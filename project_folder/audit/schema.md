# Audit record schema

The CLI writes **one tab-separated (TSV) record per line** to `~/.ledgerpoint/audit.log`
(or `LEDGERPOINT_LOG_FILE`). Azure data-plane events are written separately by the
storage service to the Log Analytics workspace configured in `deploy/`.

## Local CLI record

| Field | Example | Notes |
| --- | --- | --- |
| `timestamp` | `2026-11-23T10:31:00Z` | UTC, ISO 8601 |
| `actor` | `office.manager@ledgerpoint.example` | Signed-in Entra UPN, fallback object ID, then `unknown-user` |
| `action` | `UPLOAD`, `DOWNLOAD`, `LIST`, `DELETE`, `SHARE`, `REVOKE_SHARE` | Fixed vocabulary; `FAILURE` is a status, not an action |
| `target` | `financial-statements/clientA/statement.pdf` | Container/blob or storage account |
| `status` | `SUCCESS` / `FAILURE` | Outcome of the operation |
| `details` | `expiry=2026-11-24T10:31:00Z;permissions=r;type=user-delegation-sas` | Context such as source, destination, expiry, permissions |

Example record (tabs shown as `→`):

```text
2026-11-23T10:31:00Z→office.manager@ledgerpoint.example→SHARE→financial-statements/clientA/statement.pdf→SUCCESS→expiry=2026-11-24T10:31:00Z;permissions=r;type=user-delegation-sas
```

A real file uses literal tab characters, so it can be parsed with
`awk -F '\t'` or viewed with `bash scripts/ledgerpoint-cli.sh audit-log`.

## Azure platform record

Diagnostic settings forward the storage categories `StorageRead`, `StorageWrite` and
`StorageDelete` to Log Analytics. These records contain the Azure caller identity and
UTC time of the platform operation. They complement, but do not replace, the local
actor field.

## Forbidden fields

Never write a SAS token, signature, `sig=` parameter, full signed URL, account key,
real client name/email or IP address into either log. Run any captured output through
`tests/evidence-scripts/redact.sh` before placing it in `evidence/` or `audit/samples/`.
