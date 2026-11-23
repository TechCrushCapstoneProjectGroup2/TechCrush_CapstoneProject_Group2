# Team sync - 2026-11-23

Attendees: project lead, cloud/devops engineer, CLI engineer, security/audit engineer, test engineer

## Agenda

1. Confirm the client contradiction and hard constraints from the brief
2. Accept the three Phase 0 decisions
3. Agree the implementation layout and the verification approach

## Decisions made

| Decision | ADR / doc link | Agreed by |
| --- | --- | --- |
| Private container + read-only, HTTPS-only user delegation SAS | `../01-design/decisions/ADR-001-access-mechanism.md` | All roles |
| Default TTL 24 h, max 72 h, revoke all user delegation keys | `../01-design/decisions/ADR-002-expiry-and-revocation.md` | All roles |
| Local TSV audit log plus Log Analytics diagnostics | `../01-design/decisions/ADR-003-logging.md` | All roles |
| Use `deploy/` for provisioning and `scripts/` for the CLI | `../00-project-charter/project-overview.md` | Project lead, cloud/devops, CLI |
| Fill the docs before pushing; no secrets or live tokens in the repo | `../../CONTRIBUTING.md` | All roles |

## Action items

| Action | Owner (role) | Due | Status |
| --- | --- | --- | --- |
| Complete Phase 0 worksheet and accept ADRs | Project lead | 2026-11-23 | Done |
| Provision and verify private storage via `deploy/deploy.sh` | Cloud/devops engineer | Before demo | Pending live Azure run |
| Implement and verify CLI commands | CLI engineer | 2026-11-23 | Done (mocked verification) |
| Define audit schema, retention and redaction | Security/audit engineer | 2026-11-23 | Done |
| Run end-to-end test and capture three screenshots | Test engineer | Before demo | Pending live Azure run |
| Write the incident reflection and demo script | Project lead | Before demo | Draft complete |

## Blockers / risks

- No live Azure run has happened yet, so deployment, integration and screenshot
  evidence are still outstanding. The code has been verified against a mocked
  `az`/`curl` environment only.
- `STORAGE_ACCOUNT` must be set to a globally unique name before deployment.
- `revoke-share` needs the ARM revoke-delegation-key permission, which the deploying
  identity may not have by default.

## Next sync

Immediately after the live deployment: review the private-by-default output, confirm
the three screenshots exist in `evidence/screenshots/`, and sign off the incident
report before submission.
