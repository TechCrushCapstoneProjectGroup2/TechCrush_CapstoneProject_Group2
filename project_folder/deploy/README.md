# Deployment scripts

This folder provisions and removes the Azure resources used by the CLI.

## Files

| File | Purpose |
| --- | --- |
| `deploy.sh` | Entry point. Run this from the repository root. |
| `orchestrator.sh` | Sources the helpers and all step files, then runs the steps. |
| `common.sh` | Configuration aliases, logging, validation, audit-log setup. |
| `step-00-prerequisites.sh` … `step-08-summary.sh` | One function per deployment step. |
| `teardown.sh` | Deletes the resource group. Safe to run twice. |
| `access-policy.md` | Who can access files and the audit log. |
| `README.md` | This file. |

All scripts are sourced into one Bash process, so later steps can use variables set
by earlier steps (for example `STORAGE_ID`).

## Configuration

Configuration is loaded from the repository `config.sh`, which reads `.env` and
`.env.local` if present. See `.env.example` at the repository root.

Required:

```bash
export STORAGE_ACCOUNT="stledgerpointg2<your-unique-suffix>"
```

Common optional values:

```bash
export RESOURCE_GROUP="rg-ledgerpoint-capstone"
export LOCATION="uksouth"
export CONTAINER_NAME="financial-statements"
export WORKSPACE_NAME="lawledgerpointcapstone"
export TEAM_BLOB_CONTRIBUTOR_IDS="<object-id-1>,<object-id-2>"
export SAS_ISSUER_PRINCIPAL_IDS="<object-id-1>,<object-id-2>"
```

## Run

```bash
az login
bash deploy/deploy.sh
```

If step 4 fails with `403`, wait 1–2 minutes and re-run. The script retries
container creation while Azure RBAC propagates.

Audit log: `~/.ledgerpoint/audit.log` by default (override with
`LEDGERPOINT_LOG_FILE`).

## Teardown

```bash
bash deploy/teardown.sh
```

This deletes the whole resource group, including the storage account, workspace and
diagnostic settings. It is idempotent.

## Adding a step

1. Add `deploy/step-0N-name.sh` defining `step_name()`.
2. Add the file to the list in `orchestrator.sh`.
3. Add `step_name` to `main()` in the same order.
