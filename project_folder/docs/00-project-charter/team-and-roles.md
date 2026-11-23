# Team and roles

Ownership is assigned by **role** so the project still makes sense before individual
names are added. Replace a role label with a name and GitHub handle if your tutor asks
for named owners.

| Area | Owner (role) | Reviewer (role) | Notes |
| --- | --- | --- | --- |
| Phase 0 design + ADRs | Project lead | Security & audit engineer | Must be finished before build work starts; see `../01-design/phase0-worksheet.md` |
| Cloud provisioning (`deploy/`) | Cloud/devops engineer | Project lead | Private-by-default, diagnostics and teardown included |
| CLI tool (`scripts/`) | CLI engineer | Cloud/devops engineer | upload/download/list/delete/share/revoke-share/audit-log |
| Audit logging (`audit/`) | Security & audit engineer | Project lead | Schema, retention, redaction, log samples |
| Tests + evidence | Test engineer | Security & audit engineer | Three required screenshots + audit sample |
| Incident report + demo | Project lead | Test engineer | 5-section report, live walkthrough |

## Decision rule

Design disagreements are resolved in an ADR, not in a Slack thread. The ADR records the
decision, the rejected alternatives, and who agreed. See
`../01-design/decisions/README.md`.

## Handover note

The office manager role (the tool's end user) is not a repo owner. Their operating
instructions live in `../03-runbooks/operations.md` and must stay jargon-free.
