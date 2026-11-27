#!/usr/bin/env bash
# Run from this contribution's root in Git Bash. No SAS URLs or tokens are uploaded.
set -euo pipefail
export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'
RG=${RESOURCE_GROUP:-rg-ledgerpoint-capstone}
WS=${LOG_ANALYTICS_WORKSPACE:-law-ledgerpoint-capstone}
RULE=ledgerpoint-lifecycle-dcr
TABLE=LedgerPointShareAudit_CL
STREAM=Custom-LedgerPointShareAudit
API=2024-03-11
TMP=$(mktemp -d .audit-monitor.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
[[ -f scripts/ledgerpoint.sh && -f queries/storage-audit.kql ]] || { echo 'Run from the LedgerPoint contribution root.' >&2; exit 1; }
workspace_id() { az monitor log-analytics workspace show -g "$RG" -n "$WS" --query id -o tsv | tr -d '\r'; }
rule_id() { printf '%s/providers/Microsoft.Insights/dataCollectionRules/%s' "${1%/providers/*}" "$RULE"; }
setup() {
  local ws location dcr oid
  ws=$(workspace_id)
  location=$(az monitor log-analytics workspace show -g "$RG" -n "$WS" --query location -o tsv | tr -d '\r')
  dcr=$(rule_id "$ws")
  python - "$TMP" "$ws" "$location" <<'PY'
import json,sys,pathlib
p=pathlib.Path(sys.argv[1]); ws,loc=sys.argv[2:]
cols=[{'name':n,'type':'datetime'} for n in ('TimeGenerated','EventTime')]+[{'name':n,'type':'string'} for n in ['EventId','Actor','Operation','Target','Result']]+[{'name':'Expiry','type':'datetime'}]
(p/'table.json').write_text(json.dumps({'properties':{'schema':{'name':'LedgerPointShareAudit_CL','columns':cols}}}))
(p/'dcr.json').write_text(json.dumps({'location':loc,'kind':'Direct','properties':{'streamDeclarations':{'Custom-LedgerPointShareAudit':{'columns':cols}},'destinations':{'logAnalytics':[{'workspaceResourceId':ws,'name':'workspace'}]},'dataFlows':[{'streams':['Custom-LedgerPointShareAudit'],'destinations':['workspace'],'transformKql':'source','outputStream':'Custom-LedgerPointShareAudit_CL'}]}}))
PY
  az rest --method put --url "https://management.azure.com${ws}/tables/${TABLE}?api-version=2022-10-01" --body "@$TMP/table.json" -o none
  # The table can take a moment to become usable by the DCR.
  for i in {1..12}; do
    state=$(az rest --method get --url "https://management.azure.com${ws}/tables/${TABLE}?api-version=2022-10-01" --query properties.provisioningState -o tsv | tr -d '\r')
    [[ "$state" == Succeeded ]] && break
    sleep 5
  done
  [[ "$state" == Succeeded ]] || { echo "Table state: $state; rerun setup later." >&2; return 1; }
  az rest --method put --url "https://management.azure.com${dcr}?api-version=${API}" --body "@$TMP/dcr.json" -o none
  oid=$(az ad signed-in-user show --query id -o tsv | tr -d '\r')
  [[ -n "$oid" ]] || return 1
  if [[ $(az role assignment list --assignee "$oid" --scope "$dcr" --query "[?roleDefinitionName=='Monitoring Metrics Publisher'] | length(@)" -o tsv | tr -d '\r') == 0 ]]; then
    az role assignment create --assignee-object-id "$oid" --assignee-principal-type User --role 'Monitoring Metrics Publisher' --scope "$dcr" -o none
  fi
  echo 'Custom table and ingestion rule configured. RBAC propagation may take a few minutes.'
}
sync_logs() {
  local ws dcr endpoint immutable token count
  [[ -f logs/ledgerpoint-audit.tsv ]] || { echo 'No local audit log found.' >&2; return 1; }
  mkdir -p logs
  python - "$TMP" <<'PY'
import csv,datetime,hashlib,json,pathlib,re,sys
p=pathlib.Path(sys.argv[1]); state=pathlib.Path('logs/.azure-audit-sent')
sent=set(state.read_text().splitlines()) if state.exists() else set()
records=[]; ids=set()
with open('logs/ledgerpoint-audit.tsv',encoding='utf-8-sig',newline='') as f:
    for r in csv.DictReader(f,delimiter='\t'):
        if not {'timestamp_utc','actor','operation','target','result','details'} <= r.keys():
            raise SystemExit('Unexpected audit TSV header; no data sent.')
        op=(r['operation'] or '').lower(); result=(r['result'] or '').upper(); target=r['target'] or ''
        if result!='SUCCESS' or op not in ('share-copy','revoke','revoke-copy'): continue
        # Do not upload URLs, credentials or arbitrary details.
        if not target or '://' in target or '?' in target or 'sig=' in target.lower(): continue
        expiry=re.search(r'\bexpiry=(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ)',r['details'] or '')
        ts=(r['timestamp_utc'] or '').strip()
        try: dt=datetime.datetime.fromisoformat(ts.replace('Z','+00:00'))
        except ValueError: raise SystemExit('Unexpected timestamp format: inspect the local audit log.')
        if dt.tzinfo is None: dt=dt.replace(tzinfo=datetime.timezone.utc)
        rec={'EventTime':dt.astimezone(datetime.timezone.utc).isoformat(),'Actor':r['actor'] or '', 'Operation':'share-copy' if op=='share-copy' else 'revoke','Target':target,'Result':result,'Expiry':expiry.group(1) if expiry else None}
        eventid=hashlib.sha256(json.dumps(rec,sort_keys=True).encode()).hexdigest()
        if eventid in sent or eventid in ids: continue
        rec['EventId']=eventid; rec['TimeGenerated']=datetime.datetime.now(datetime.timezone.utc).isoformat(); records.append(rec); ids.add(eventid)
# Keep requests below ingestion limits, even if importing many historical rows.
for i in range(0,len(records),100):
    batch=records[i:i+100]; (p/f'batch-{i:08}.json').write_text(json.dumps(batch)); (p/f'batch-{i:08}.ids').write_text(''.join(r['EventId']+'\n' for r in batch))
(p/'count').write_text(str(len(records)))
PY
  count=$(cat "$TMP/count")
  [[ "$count" != 0 ]] || { echo 'No new successful share/revoke events to upload.'; return 0; }
  ws=$(workspace_id); dcr=$(rule_id "$ws")
  endpoint=$(az rest --method get --url "https://management.azure.com${dcr}?api-version=${API}" --query properties.endpoints.logsIngestion -o tsv | tr -d '\r')
  immutable=$(az rest --method get --url "https://management.azure.com${dcr}?api-version=${API}" --query properties.immutableId -o tsv | tr -d '\r')
  [[ "$endpoint" == https://* && -n "$immutable" ]] || { echo 'DCR ingestion endpoint not ready.' >&2; return 1; }
  token=$(az account get-access-token --resource https://monitor.azure.com/ --query accessToken -o tsv | tr -d '\r')
  for batch in "$TMP"/batch-*.json; do
    curl --fail --silent --show-error --request POST --header "Authorization: Bearer $token" --header 'Content-Type: application/json' --data-binary "@$batch" "${endpoint%/}/dataCollectionRules/$immutable/streams/$STREAM?api-version=2023-01-01" >/dev/null || { echo 'Ingestion failed. Local log is preserved; rerun sync after checking RBAC.' >&2; return 1; }
    cat "${batch%.json}.ids" >> logs/.azure-audit-sent
  done
  echo "Sent $count share/revoke audit events to Azure Monitor."
}
report() {
  # Names are fetched privately at runtime, never committed to Git.
  if ! az ad user list --query '[].{id:id,name:displayName,upn:userPrincipalName,mail:mail}' -o json > "$TMP/users.json"; then printf '[]' > "$TMP/users.json"; echo 'Directory lookup unavailable; using native identifiers.' >&2; fi
  python - "$TMP/users.json" <<'PY'
import json,sys,pathlib
users=json.load(open(sys.argv[1],encoding='utf-8-sig')); names={}; emails={}
for u in users:
    for key in (u.get('id'),u.get('upn'),u.get('mail')):
        if key:
            names[key.lower()]=u.get('name') or key
            emails[key.lower()]=u.get('mail') or u.get('upn') or ''
q=pathlib.Path('queries/storage-audit.kql').read_text()
print(q.replace('__NAMES__',json.dumps(names,ensure_ascii=True)).replace('__EMAILS__',json.dumps(emails,ensure_ascii=True)))
PY
}
case "${1:-}" in
  setup) setup ;;
  sync) sync_logs ;;
  report) report ;;
  run) shift; rc=0; bash scripts/ledgerpoint.sh "$@" || rc=$?; sync_logs || { echo 'Audit sync failed; rerun sync.' >&2; exit 1; }; exit "$rc" ;;
  *) echo 'Usage: bash scripts/audit-monitor.sh {setup|sync|report|run <ledgerpoint arguments>}' >&2; exit 2 ;;
esac
