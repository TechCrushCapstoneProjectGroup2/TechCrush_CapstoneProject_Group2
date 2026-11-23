# CLI tool

The LedgerPoint CLI stores financial statements in private Azure Blob Storage and
creates expiring, read-only links for auditors.

## Files

| File | Purpose |
| --- | --- |
| `ledgerpoint-cli.sh` | Entry point. Run this from the repository root. |
| `dispatcher.sh` | Sources the helpers and command files, then routes the command. |
| `common.sh` | Config, validation, Azure checks, audit-log helpers. |
| `commands/upload.sh` | `upload` |
| `commands/download.sh` | `download` |
| `commands/list.sh` | `list` |
| `commands/delete.sh` | `delete` |
| `commands/share.sh` | `share` (user delegation SAS) |
| `commands/revoke-share.sh` | `revoke-share` |
| `commands/audit-log.sh` | `audit-log` |
| `README.md` | This file. |

## Commands

| Command | Purpose | Audit action |
| --- | --- | --- |
| `upload <local-file> [blob-name]` | Store a statement | `UPLOAD` |
| `download <blob-name> <local-path>` | Retrieve a statement | `DOWNLOAD` |
| `list` | List files | `LIST` |
| `delete <blob-name>` | Remove a statement | `DELETE` |
| `share <blob-name> [hours]` | Create an expiring read-only link | `SHARE` |
| `revoke-share` | Revoke all active user delegation SAS links | `REVOKE_SHARE` |
| `audit-log [lines]` | Show the local audit log | — |

## Run

From the repository root:

```bash
bash scripts/ledgerpoint-cli.sh help
bash scripts/ledgerpoint-cli.sh upload ./statement.pdf clientA/statement.pdf
bash scripts/ledgerpoint-cli.sh share clientA/statement.pdf 24
```

Configuration is loaded from the repository `config.sh`, which reads `.env` and
`.env.local`. `STORAGE_ACCOUNT` is required.

## Rules

- Every Azure action writes an audit record with timestamp, actor, target and status.
- The SAS URL is printed once to the operator and is never written to the audit log.
- Links are HTTPS-only, read-only and expire automatically.
- `revoke-share` revokes **all** user delegation keys for the storage account.
- Never commit a SAS URL or an unredacted screenshot.
