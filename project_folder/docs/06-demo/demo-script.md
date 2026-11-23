# Demo script (run order)

1. **Problem (30s)**: read the contradiction from `docs/00-project-charter/brief-summary.md`.
2. **Design (60s)**: show Phase 0 worksheet and ADR-001; point at the rejected public-container option.
3. **Deploy (60s)**: `bash deploy/deploy.sh` (or show recorded output if time is short).
4. **Private by default (30s)**: show anonymous request denied -> `evidence/logs/deploy/`.
5. **Upload + share (90s)**: `bash scripts/ledgerpoint-cli.sh upload`, then `share`; open link; show it works.
6. **Audit (45s)**: show the upload-to-share audit cycle from `audit/samples/`.
7. **Revoke (45s)**: `bash scripts/ledgerpoint-cli.sh revoke-share`; open link again; show denial.
8. **Expiry (45s)**: show pre-captured expired-link denial screenshot from `evidence/screenshots/03-expired-link-denied/`.
9. **Incident (60s)**: walk through the 5 sections of the incident report.
10. **Cost/ops (30s)**: point at `operations.md` and teardown.

Fallback if the network fails: use saved outputs in `evidence/logs/` and screenshots; never paste a live unredacted signed URL.
