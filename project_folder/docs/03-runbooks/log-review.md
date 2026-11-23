# Reviewing the audit trail

1. Locate the destination defined in ADR-003: `LEDGERPOINT_LOG_FILE` (default
   `~/.ledgerpoint/audit.log`, set in `.env`). Azure platform records are in the Log
   Analytics workspace created by `deploy/`.
2. Read the most recent local records with
   `bash scripts/ledgerpoint-cli.sh audit-log 50`; sort by UTC timestamp.
3. Required fields per record are defined in `audit/schema.md`.
4. Confirm a full cycle exists: `UPLOAD` -> `SHARE` -> `DOWNLOAD` -> `REVOKE_SHARE`.
5. Confirm there are **no** tokens, `sig=` parameters or full signed URLs in the
   records.
6. Copy a redacted sample to `audit/samples/` using
   `bash tests/evidence-scripts/redact.sh`, then reference it in the deliverables.

Only the roles listed in ADR-003 may read the trail. Auditors have no access at all and
must not be able to write to it.
