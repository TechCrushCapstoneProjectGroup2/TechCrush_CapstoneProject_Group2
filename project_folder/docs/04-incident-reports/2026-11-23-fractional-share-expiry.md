# Incident report: Fractional share lifetime rejected before expiry calculation

Date: 2026-11-23 | Author: Test engineer | Project: Secure Cloud File Storage System (Capstone) | Severity: Major

## 1. Symptom

While verifying the CLI with a mocked Azure CLI, a valid fractional share lifetime was
rejected:

```text
$ bash scripts/ledgerpoint-cli.sh share clientA/statement.pdf 0.5
ERROR: Could not calculate SAS expiry time.
```

The command exited non-zero and no SAS URL was produced. Whole-hour values (for
example `2`) worked. The before/after verification summary is recorded in
`../../USAGE-AND-AUDIT.md` sections 1.1 and 3.

## 2. Investigation trail

| # | What was checked | Command / method | Result | Ruled in / out |
| --- | --- | --- | --- | --- |
| 1 | Azure authentication and blob existence | mocked `az account show`, `az storage blob show` | Both succeeded | Ruled out auth and missing blob |
| 2 | Input validation regex in `scripts/commands/share.sh` | read source | `^[0-9]+([.][0-9]+)?$` already accepted `0.5` | Ruled out validation |
| 3 | Expiry date calculation | ran `date -u -d "+0.5 hours"` and `date -u -v+0.5H` on GNU date | both forms failed on a fractional argument | Ruled **in**: platform-specific `date` parsing |
| 4 | Whole-hour control test | `share clientA/statement.pdf 2` | produced a link with a valid expiry | Confirmed the bug was fractional-only |

## 3. Root cause

The expiry calculation passed the fractional value directly to system `date` as
`+0.5 hours` (GNU) or `-v+0.5M` (BSD/macOS). GNU `date` requires whole units, so it
returned an error and the script reported "Could not calculate SAS expiry time" even
though the input was valid.

## 4. Fix

`scripts/commands/share.sh` now converts hours to **whole minutes** with `awk`
(`hours * 60`, rounded up) and passes an integer minute count to `date`. It also
enforces `MAX_SHARE_HOURS` (default 72) before calculating the expiry.

- Before: `ERROR: Could not calculate SAS expiry time.` for `share <blob> 0.5`
- After: link generated with `expires` 30 minutes in the future for `share <blob> 0.5`;
  values above `MAX_SHARE_HOURS` are rejected with a clear message.

Verification is reproducible with the mocked CLI described in
`../../USAGE-AND-AUDIT.md` section 3. For live proof, capture the before/after output
into `evidence/logs/tests/` and redact it with
`bash tests/evidence-scripts/redact.sh`.

## 5. Design reflection

ADR-002 correctly required an explicit expiry and a maximum TTL, but it described the
policy in **hours** without specifying how fractional values are converted into a
platform-neutral timestamp. The design therefore made this failure more likely: the
policy allowed a value that the implementation's date tool could not express. It was
easy to catch because the integration path prints the expiry and the CLI fails loudly,
but only whole-hour values were exercised during design review. I would update ADR-002
to state that lifetimes are rounded up to whole minutes and that both GNU and BSD
`date` forms must be verified in `tests/integration/run.sh`. The ADR has been updated
with a build-divergence note.
