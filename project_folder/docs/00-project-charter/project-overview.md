# Project overview - LedgerPoint

## What this project delivers

This project implements **Project 2: Secure Cloud File Storage System** for
LedgerPoint, an accounting firm that needs to store sensitive financial statements
and share them with external auditors using time-limited links.

Implemented controls:

- Private Azure Blob Storage: public blob access disabled, container private,
  shared key access disabled.
- Secure transport: HTTPS-only, minimum TLS 1.2.
- Least privilege: Azure RBAC with `Storage Blob Data Contributor` and
  `Storage Blob Delegator` scoped to the storage account.
- Bash CLI: upload, download, list, delete, share, revoke-share and audit-log.
- Time-limited sharing: read-only, HTTPS-only user delegation SAS links.
- Audit logging: Azure diagnostics to Log Analytics plus a local CLI audit log.
- Automation: deployment, verification and teardown scripts.

## Repository structure

```text
.
├── config.sh                 # Loads .env / .env.local
├── deploy/
│   ├── deploy.sh              # Entry point
│   ├── orchestrator.sh        # Runs the step functions in order
│   ├── common.sh              # Shared helpers
│   ├── step-*.sh              # One file per deployment step
│   ├── teardown.sh            # Deletes the resource group
│   └── README.md
├── scripts/
│   ├── ledgerpoint-cli.sh     # Entry point
│   ├── dispatcher.sh          # Routes commands
│   ├── common.sh              # Shared CLI helpers
│   ├── commands/              # One file per CLI command
│   └── README.md
└── tests/
    ├── integration/run.sh     # Real Azure end-to-end test
    └── evidence-scripts/      # Redaction and expiry evidence helpers
```

## Prerequisites

- Bash
- Azure CLI (`az`)
- Access to an Azure subscription where you can create resource groups, storage
  accounts, roles, Log Analytics workspaces and diagnostic settings
- `az login` completed

## Configuration

Copy `.env.example` to `.env` and set at least:

```bash
STORAGE_ACCOUNT="stledgerpointg2<your-unique-suffix>"
```

Common optional values:

```bash
RESOURCE_GROUP="rg-ledgerpoint-capstone"
LOCATION="uksouth"
CONTAINER_NAME="financial-statements"
WORKSPACE_NAME="lawledgerpointcapstone"
DEFAULT_SHARE_HOURS="24"
MAX_SHARE_HOURS="72"
```

You can also export these variables directly instead of using `.env`.

## Deploy

```bash
bash deploy/deploy.sh
```

The deployment validates configuration, creates the secure storage account and
private container, assigns RBAC, enables diagnostics and verifies all security
settings. If container creation fails due to RBAC propagation, wait a minute and
re-run; the script is safe to re-run.

## CLI usage

```bash
bash scripts/ledgerpoint-cli.sh upload ./statement.pdf clientA/statement.pdf
bash scripts/ledgerpoint-cli.sh list
bash scripts/ledgerpoint-cli.sh download clientA/statement.pdf ./downloads/statement.pdf
bash scripts/ledgerpoint-cli.sh share clientA/statement.pdf 24
bash scripts/ledgerpoint-cli.sh audit-log 20
bash scripts/ledgerpoint-cli.sh revoke-share
bash scripts/ledgerpoint-cli.sh delete clientA/statement.pdf
```

## Security notes

- The `share` command creates a user delegation SAS: read-only, HTTPS-only and
  time-limited. Auditors do not need an Azure account.
- Sharing never makes the container public.
- `revoke-share` revokes all user delegation keys, invalidating every active SAS
  link for the storage account.
- The maximum share lifetime is enforced by `MAX_SHARE_HOURS`.
- Never commit a SAS URL, an account key or a customer file.

## Teardown

```bash
bash deploy/teardown.sh
```

This deletes the resource group and everything in it. It is safe to run twice.
