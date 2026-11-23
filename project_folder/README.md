# Secure Cloud File Storage System

Capstone project for **Project 2: Secure Cloud File Storage System**.

LedgerPoint staff upload sensitive financial statements to private Azure Blob Storage
and generate short-lived, read-only links for external auditors. The files are never
public and the links expire automatically.

## Repository map

| Path | Purpose |
| --- | --- |
| `config.sh` | Loads `.env` / `.env.local` and normalizes configuration names. |
| `deploy/` | Deployment, verification and teardown scripts. |
| `scripts/` | LedgerPoint CLI and per-command implementations. |
| `tests/` | End-to-end verification and evidence helpers. |
| `docs/` | Charter, design decisions, architecture, runbooks and demo material. |
| `audit/` | Audit schema, retention rules and redacted samples. |
| `evidence/` | Screenshots and logs required for submission. |
| `.github/` | Issue/PR templates and CI documentation. |
| `HOW-IT-WORKS.md` | **Start here** - plain-English explanation of the code and how the files connect. |
| `USAGE-AND-AUDIT.md` | Review notes and detailed usage guide. |

## Quick start

1. Copy the example config and fill it in locally:

   ```bash
   cp .env.example .env
   ```

   Set `STORAGE_ACCOUNT` to a globally unique Azure storage account name.

2. Authenticate:

   ```bash
   az login
   ```

3. Deploy:

   ```bash
   bash deploy/deploy.sh
   ```

4. Check the CLI:

   ```bash
   bash scripts/ledgerpoint-cli.sh help
   ```

5. Run the end-to-end verification:

   ```bash
   bash tests/integration/run.sh
   ```

6. Tear down when finished:

   ```bash
   bash deploy/teardown.sh
   ```

Configuration can also be exported directly instead of using `.env`:

```bash
export STORAGE_ACCOUNT="stledgerpointg2<your-unique-suffix>"
export RESOURCE_GROUP="rg-ledgerpoint-capstone"
export LOCATION="uksouth"
```

## Common CLI commands

```bash
bash scripts/ledgerpoint-cli.sh upload ./statement.pdf clientA/statement.pdf
bash scripts/ledgerpoint-cli.sh list
bash scripts/ledgerpoint-cli.sh share clientA/statement.pdf 24
bash scripts/ledgerpoint-cli.sh download clientA/statement.pdf ./statement.pdf
bash scripts/ledgerpoint-cli.sh revoke-share
bash scripts/ledgerpoint-cli.sh audit-log 20
```

`revoke-share` invalidates **all** active user delegation SAS links for the storage
account. Reissue legitimate links afterwards.

## Design rules

- Storage is private by default: no public container, no shared key access.
- Links are time-limited, HTTPS-only, read-only user delegation SAS URLs.
- Every Azure action writes an audit record with actor, timestamp and status.
- Audit records and evidence never contain SAS tokens or full signed URLs.
- The deployment and CLI are intended to be simple enough for a non-technical operator.

See `docs/03-runbooks/operations.md` for the plain-English operator guide.

## Deliverables

| Deliverable | Location |
| --- | --- |
| Phase 0 worksheet | `docs/01-design/phase0-worksheet.md` |
| ADRs | `docs/01-design/decisions/` |
| Architecture and threat model | `docs/02-architecture/` |
| Deployment scripts | `deploy/` |
| CLI scripts | `scripts/` |
| End-to-end test | `tests/integration/run.sh` |
| Screenshots | `evidence/screenshots/` |
| Redacted logs | `evidence/logs/`, `audit/samples/` |
| Incident report template | `docs/04-incident-reports/_TEMPLATE.md` |

Secrets, real SAS URLs and customer data are never committed.
