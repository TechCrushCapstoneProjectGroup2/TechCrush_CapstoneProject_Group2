# Data flow

Each flow shows the exact command, the cloud operation and the audit record written.

## 1. Upload

`bash scripts/ledgerpoint-cli.sh upload <local-file> [blob-name]` -> validate input ->
check Azure login -> `az storage blob upload --auth-mode login` -> `UPLOAD` audit
record with actor, UTC time, target and status.

## 2. Share

`bash scripts/ledgerpoint-cli.sh share <blob-name> [hours]` -> validate TTL against
`MAX_SHARE_HOURS` -> `az storage blob generate-sas --as-user --permissions r
--https-only` -> print the URL once -> `SHARE` audit record with expiry and status.
**The URL is never logged.**

## 3. Auditor download

Auditor opens the SAS URL -> Azure validates the user delegation key and expiry ->
file is downloaded without an Azure account. This happens outside the CLI, so no
local audit record is written for the auditor action.

## 4. Staff download

`bash scripts/ledgerpoint-cli.sh download <blob-name> <local-path>` -> `az storage
blob download --auth-mode login` -> `DOWNLOAD` audit record.

## 5. Revoke / expiry

`bash scripts/ledgerpoint-cli.sh revoke-share` -> `az storage account
revoke-delegation-keys` -> all active user delegation SAS links become invalid ->
`REVOKE_SHARE` audit record. Expired links fail naturally at the cloud layer;
capture the denial screenshot with `tests/evidence-scripts/capture-expired-link.sh`.
