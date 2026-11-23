# Teardown

Remove everything billable after testing and before final submission (keep code, docs and evidence).

1. Run `bash deploy/teardown.sh`.
2. Confirm the resource group / bucket and audit destination no longer exist.
3. Confirm no share links remain valid from a previous test run.
4. Save the teardown output to `evidence/logs/deploy/teardown.txt`.
5. Update `docs/04-incident-reports/` and the demo notes if teardown revealed a leftover resource.

Teardown must be repeatable and safe to run twice.
