# Evidence helpers

| Script | Purpose |
| --- | --- |
| `redact.sh` | Strip SAS tokens, signed URLs, emails, object IDs and account names from logs. Reads stdin or files; `-o` writes to a file. |
| `capture-expired-link.sh` | Upload a test blob, create a short-lived SAS link, wait for expiry and capture the denied HTTP response. |

Examples:

```bash
cat raw.log | bash tests/evidence-scripts/redact.sh
bash tests/evidence-scripts/redact.sh -o evidence/logs/tests/clean.txt raw.log
bash tests/evidence-scripts/capture-expired-link.sh
```

`capture-expired-link.sh` writes redacted proof to:

```text
evidence/screenshots/03-expired-link-denied/
```

Tune the wait with `WAIT_SECONDS` if you change `SHARE_HOURS`.

Never commit an unredacted token, even in a test fixture.
