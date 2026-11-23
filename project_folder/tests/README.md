# Tests and verification

| Path | Purpose |
| --- | --- |
| `integration/run.sh` | Real Azure end-to-end scenario: private check -> upload -> share -> download -> revoke -> denied. |
| `evidence-scripts/redact.sh` | Removes SAS tokens, signed URLs, emails, IDs and account names from logs. |
| `evidence-scripts/capture-expired-link.sh` | Produces the expired-link denial evidence. |

Run the full scenario with:

```bash
bash tests/integration/run.sh
```

Redacted output is written to `evidence/logs/tests/`. Screenshots belong under
`evidence/screenshots/`.

Do not commit raw logs containing signed URLs or customer data.
