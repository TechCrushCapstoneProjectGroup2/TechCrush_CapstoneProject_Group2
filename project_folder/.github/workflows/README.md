# CI/CD documentation

GitHub Actions reads workflow files from this directory. Planned workflows:

| Planned file | Responsibility |
| --- | --- |
| `ci.yml` | On PR/push: `shellcheck` all `.sh`, validate templates, fail on accidental secret patterns. |
| `verify-deploy.yml` | On demand: run `deploy/deploy.sh` in an isolated resource group, run `tests/integration/run.sh`, collect redacted evidence, always run `deploy/teardown.sh`. |

## Repository secrets (never printed)

- `AZURE_CREDENTIALS`

## Repository variables (non-sensitive)

- `AZURE_RESOURCE_GROUP`, `AZURE_LOCATION`, `AZURE_STORAGE_ACCOUNT`, `AZURE_STORAGE_CONTAINER`
- `DEFAULT_LINK_TTL_HOURS`, `MAX_LINK_TTL_HOURS`

These map to the canonical names through `config.sh`.

## Pipeline rules

- Use GitHub environments with required reviewers for anything touching a shared cloud account.
- Never echo a generated SAS URL into CI logs.
- Upload only redacted logs as artifacts; run `tests/evidence-scripts/redact.sh` first.
- The deployment must stay private by default; a pipeline that flips public access is a failing pipeline.
