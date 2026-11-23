# Threat model / failure modes

This section feeds the incident report and the demo. For each row, record how we detect it.

| Failure mode | Effect | Detection / evidence | Design control |
| --- | --- | --- | --- |
| Container/bucket made public | All files discoverable | Provisioning check + integration test asserts private access | ADR-001, `deploy/` |
| Long or no expiry | Permanent access | Test asserts TTL <= max | ADR-002 |
| Signed URL leaked in logs/screenshots | Anyone with URL can access until expiry | `redact.sh` + PR checklist + log review | ADR-003 |
| Guessable object names | Enumeration | Use random opaque ids | ADR-001 |
| Auditor can edit audit trail | No reliable evidence | IAM check: auditors have no write permission | ADR-003 |
| Expired link still works | Violates brief | `capture-expired-link.sh` + denial screenshot | ADR-002 |
| File deleted while link alive | Broken link / confusing audit | Define behaviour in ADR-002 | ADR-002 |
