# End-to-end verification

`run.sh` runs the real scenario against Azure and writes **redacted** evidence to
`evidence/logs/tests/`.

What it verifies:

1. Storage is private (public blob access, shared keys and container access are off).
2. Anonymous container listing is denied (HTTP 403).
3. Upload succeeds and writes an `UPLOAD` audit record.
4. `list` succeeds.
5. `share` returns a read-only SAS link that opens anonymously (HTTP 200).
6. `download` returns the same content through the CLI.
7. `revoke-share` invalidates the link (HTTP 403 afterwards).
8. Audit trail is captured and redacted.

Run:

```bash
bash tests/integration/run.sh
```

Useful overrides:

```bash
SHARE_HOURS=1 VERIFY_ANONYMOUS=true CLEANUP_BLOB=true \
  TEST_SOURCE_FILE=./sample.pdf \
  EVIDENCE_DIR=evidence/logs/tests bash tests/integration/run.sh
```

For the separate expired-link proof, run:

```bash
bash tests/evidence-scripts/capture-expired-link.sh
```

Never commit an unredacted SAS URL. All output passed through `redact.sh` before
being written to `evidence/`.
