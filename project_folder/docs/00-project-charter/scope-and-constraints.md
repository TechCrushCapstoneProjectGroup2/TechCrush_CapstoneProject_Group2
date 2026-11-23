# Scope and constraints

## Hard constraints (from the brief)

- Storage resource is **private by default**. No public container, no public-read ACL, no anonymous listing.
- Share links use a **time-limited mechanism**, not a public toggle.
- Links must be unguessable and must expire; expired links must fail with observable evidence.
- Every upload / download / list / delete / share / revoke action produces an audit record with actor + timestamp.
- No real secret, SAS token, presigned URL, or customer data in the repository or evidence.
- All scripts and configs must work from a clean clone.
- No compute, port 80 listener or public IP is deployed. This is a storage-only project; external access is through HTTPS blob endpoints only, so the generic port-80/public-IP submission rule does not apply here.

## Cost and operability constraints

- Prefer managed storage with no always-on compute. No VM to babysit.
- Keep the number of resources small; teardown must remove everything billable.
- Provide a plain-English operator guide (`docs/03-runbooks/operations.md`) for the office manager.

## Out of scope unless the team agrees otherwise

- Building a web UI.
- User accounts for auditors.
- Permanent/lifetime links.
- Indexing or search over file contents.
