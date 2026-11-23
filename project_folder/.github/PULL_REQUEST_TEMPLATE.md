## What changed

Summarise the change in one or two sentences. Name the files or folders affected, for
example: "Added `MAX_SHARE_HOURS` enforcement in `scripts/commands/share.sh` and
documented it in `.env.example`."

## Why (design link)

- Phase 0 section / ADR: link the relevant `docs/01-design/decisions/ADR-*.md` or
  `docs/01-design/phase0-worksheet.md` section.
- Divergence from design (if any, one line): write "none" if the build matches the
  design. If it differs, add a line to that ADR as well.

## Verification

- [ ] `bash -n` passes on every changed `.sh` file
- [ ] `shellcheck` clean on changed scripts
- [ ] CLI commands affected by this change were exercised
- [ ] Integration scenario pass (private check -> upload -> share -> download -> revoke -> denied)
- [ ] No secrets/tokens/real customer data in diff or screenshots
- [ ] Evidence committed under `evidence/` (link below)
- [ ] Teardown verified after test run with `bash deploy/teardown.sh`

## Evidence

Link the redacted screenshots/logs in `evidence/` here, for example:

- `evidence/logs/tests/share-success.txt`
- `evidence/screenshots/02-successful-revoke/`

If the change is docs-only, write "docs-only, no runtime evidence required".

## Rollback if this PR is wrong

Name the tag/commit to return to. For a config- or docs-only change, write
"config-only, revert commit" or "docs-only, revert commit".

> Never paste a live SAS URL, `sig=` value or account key into a PR description.
