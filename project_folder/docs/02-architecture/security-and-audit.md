# Security and Audit - LedgerPoint (Project 2)

## Role: Security and Audit Engineer

Responsible for ensuring the LedgerPoint storage system meets the Capstone capstone security requirements: private storage, least-privilege access, secure temporary external sharing, audit logging, and verifiable security controls.

## Security objectives (from brief)

- Auditors (external, no company account) can open a shared file via link.
- Files are sensitive financial statements: never discoverable by search engines/guessable URL, and not accessible indefinitely.
- Every upload, download, and share action must be logged with who did it and when.
- System must be cheap to run and easy for a non-technical office manager to operate.

## Control implementation

| Control | Implementation | Evidence |
|---|---|---|
| Private storage by default | `deploy.sh` sets `--allow-blob-public-access false`; container created with `--public-access off` | `deploy.sh`, `az storage account show`, `az storage container show` |
| No shared key auth | `--allow-shared-key-access false`; CLI uses `--auth-mode login` | `deploy.sh`, `ledgerpoint-cli.sh` |
| Encryption in transit | `--https-only true`, `--min-tls-version TLS1_2`; SAS generated with `--https-only` | `deploy.sh`, `ledgerpoint-cli.sh` |
| Least privilege RBAC | `Storage Blob Data Contributor` for data ops; `Storage Blob Delegator` for SAS issuance; scoped to storage account | `deploy.sh`, `az role assignment list` |
| Time-limited external sharing | User delegation SAS with `--permissions r --expiry <UTC> --as-user --auth-mode login --full-uri` | `ledgerpoint-cli.sh`, share command output |
| No public container toggle | Share command does not alter container access; deploy verifies container public access is null/private | `ledgerpoint-cli.sh`, `deploy.sh` verification step |
| Audit logging | Azure diagnostic settings send `StorageRead/Write/Delete` to Log Analytics; CLI writes local audit log with timestamp, actor, action, target, status, details | `deploy.sh`, `ledgerpoint-cli.sh`, `~/.ledgerpoint/audit.log` |
| Revocation | `revoke-share` revokes user delegation keys for storage account, invalidating active user delegation SAS | `ledgerpoint-cli.sh`, `az storage account revoke-delegation-keys` |
| Security verification | `deploy.sh` verifies public access, shared key, HTTPS-only, TLS 1.2, and container privacy after deployment | `deploy.sh` deployment summary |

## Audit trail requirements

Every CLI action logs:

- **When**: UTC ISO 8601 timestamp
- **Who**: signed-in Entra user UPN (fallback object ID)
- **What**: `UPLOAD`, `DOWNLOAD`, `LIST`, `DELETE`, `SHARE`, `REVOKE_SHARE`
- **Target**: container/blob or storage account
- **Status**: `SUCCESS` / `FAILURE`
- **Details**: source/destination, expiry, permissions, SAS type, etc.

Azure platform logs (Log Analytics) capture storage data-plane operations through diagnostic categories `StorageRead`, `StorageWrite`, `StorageDelete`.

## Evidence checklist

- [ ] `deploy.sh` execution output / deployment summary
- [ ] `az storage account show` proving private/secure settings
- [ ] `az storage container show` proving private container
- [ ] `az role assignment list` showing RBAC assignments
- [ ] CLI audit log sample covering upload -> share -> download/delete cycle
- [ ] Screenshot: successful share link generation
- [ ] Screenshot: expired SAS link denied (403)
- [ ] Screenshot: revoked SAS link denied after `revoke-share` (403)
- [ ] Log Analytics query/screenshot for StorageRead/Write/Delete

## Current status (this workspace)

- **Code/artifacts prepared**: Yes - `deploy.sh`, `ledgerpoint-cli.sh`, and security/SAS policy docs.
- **Live Azure execution**: Not executed in this session because Azure CLI is not logged in (`az account show` returned "Please run 'az login'").
- **Required to complete live evidence**: Run `az login`, set a globally unique `STORAGE_ACCOUNT`, run `bash deploy/deploy.sh`, then use `bash scripts/ledgerpoint-cli.sh` to perform upload/share/download/revoke tests and capture screenshots/logs.
