# Revoke a share link early

Use when a document was sent to the wrong auditor or a link is suspected leaked.

1. Note the share event in the audit record (do **not** paste the full URL into chat).
2. Run `bash scripts/ledgerpoint-cli.sh revoke-share`. This revokes the storage account's user delegation keys, so **all** active share links become invalid and must be reissued to legitimate recipients.
3. Verify denial: open the link in a private browser window and confirm access is refused. Save the output.
4. Capture the **successful revoke** screenshot into `evidence/screenshots/02-successful-revoke/`.
5. Confirm a `revoke` record was written to the audit trail with actor and UTC timestamp.
6. If the link still works, treat as an incident: use the Security issue template and `incident-response.md`.

Record the before/after evidence in the incident report if this was part of the failure injection.
