# Evidence (part of the submission)

Store screenshots and logs here, not in random Desktop folders.

## Naming convention

`<date>_<area>_<what>_<before|after|success|denied>.<ext>`

Examples:

- `2026-11-23_ledgerpoint_share-success.png`
- `2026-11-23_ledgerpoint_revoke-after.png`
- `2026-11-23_ledgerpoint_expired-link-denied.png`

## Mandatory evidence for Project 2

1. `screenshots/01-successful-share/` - link works for an auditor without login.
2. `screenshots/02-successful-revoke/` - link denied after revoke.
3. `screenshots/03-expired-link-denied/` - expired link denied.
4. `logs/audit-trail/` - redacted full upload-to-share cycle (also mirrored in `audit/samples/`).
5. `logs/deploy/` - deploy output and private-by-default assertion.
6. `logs/tests/` - redacted output from `tests/integration/run.sh`.

## Rules

- Redact tokens, full signed URLs, account names and client data before committing.
- Use `bash tests/evidence-scripts/redact.sh` on logs before saving them here.
- Screenshots should show the command/output and enough context to prove the claim.
- Link each evidence file from the relevant doc, PR or incident report.
