# Contributing to the Capstone repo

## Branching and PR flow

1. Create a branch from `main`: `feat/cli-share`, `fix/expiry-check`, `docs/phase0`, `test/e2e-scenario`.
2. Keep one concern per PR. Small PRs get reviewed properly.
3. Fill in the PR template. Link the design decision and the evidence you produced.
4. Request review from the owner listed in `.github/CODEOWNERS`. At least one approval before merge.
5. Do not commit directly to `main`.

## Before you open a PR

- [ ] `shellcheck` passes on every changed `.sh` file.
- [ ] No secret, token, SAS URL, account key, or real customer filename appears in the diff.
- [ ] Docs updated if behaviour changed; design divergence noted in the relevant ADR.
- [ ] Evidence added/updated in `evidence/` using the naming convention.
- [ ] Verification run (`bash tests/integration/run.sh`) and redacted output saved to `evidence/logs/tests/`.
- [ ] Teardown still works (`deploy/teardown.sh`) so we never leave billable resources behind.

## Secrets policy

- Real values live in local `.env`, cloud secret storage, or GitHub Actions secrets - never in tracked files.
- `.env.example` contains **names only**, never values.
- If a secret is accidentally committed: rotate it immediately, then tell the team in `#incidents` and record it in `docs/04-incident-reports/`.

## Evidence policy

- Screenshots must show the command/output *and* enough context to prove what happened.
- Redact tokens, URLs with signatures, account names, and personal data before committing.
- Pretend nothing happened unless there is a file in `evidence/` proving it.
