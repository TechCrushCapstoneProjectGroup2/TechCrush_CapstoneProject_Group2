# Retention, access, and integrity

| Property | Decision |
| --- | --- |
| Destination | Local TSV at `~/.ledgerpoint/audit.log` (override: `LEDGERPOINT_LOG_FILE`) plus Azure diagnostic settings to the Log Analytics workspace in `deploy/` |
| Retention | 30 days in Log Analytics; local log kept for the project duration; redacted samples copied into `audit/samples/` and `evidence/logs/audit-trail/` |
| Readers | Firm staff and reviewers; Log Analytics access follows Azure RBAC (see ADR-003) |
| Writers | CLI operator identity only; auditors have no read or write access to the log |
| Tamper resistance | Append-only local file with `0600` permissions in a `0700` directory; Azure platform logs are written by the storage service, not by the CLI |
| Redaction | `tests/evidence-scripts/redact.sh` before any log enters the repo; SAS URLs are never written to the audit log |

## Review procedure

1. Run `bash scripts/ledgerpoint-cli.sh audit-log 50` to inspect recent local records.
2. Confirm the cycle exists: `UPLOAD` -> `SHARE` -> `DOWNLOAD`/`DELETE` -> `REVOKE_SHARE`.
3. Confirm there is no token, `sig=` parameter or full signed URL in any record.
4. Copy a redacted sample to `audit/samples/` using the `YYYY-MM-DD_upload-to-share_redacted.log` naming convention.
5. Review access quarterly (or before the compliance audit) and record the check in `../docs/05-meetings/`.
