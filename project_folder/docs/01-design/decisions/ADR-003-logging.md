# ADR-003: Audit logging

Status: ACCEPTED | Date: 2026-11-23 | Decision owners: LedgerPoint project team

## Context

The brief requires every upload, download and share action to be logged with who did
it and when. The log must not be writable by auditors and must not contain SAS tokens.

## Decision

- Log destination: local TSV file at `~/.ledgerpoint/audit.log` (override with `LEDGERPOINT_LOG_FILE`) **plus** Azure Blob diagnostic settings to Log Analytics.
- Format: tab-separated local records with `timestamp`, `actor`, `action`, `target`, `status`, `details`. Azure platform records follow the Log Analytics schema.
- Retention: 30 days in Log Analytics; local log kept for the project duration, with redacted samples copied into `audit/samples/`.
- Readers: firm staff and reviewers; Log Analytics access follows Azure RBAC.
- Writers: CLI operator identity only; auditors have no write access and no access to the log.
- Redaction: tokens and full signed URLs are never written to the local audit log; evidence passes through `tests/evidence-scripts/redact.sh` before entering the repo.

## Alternatives rejected

| Alternative | Why rejected |
| --- | --- |
| Log to stdout only | Not durable or reviewable |
| Log into the same public container | Auditors could read/modify the trail |
| Separate private storage table | Extra cost/complexity for a small capstone; Log Analytics already provides queryable platform events |

## Consequences

- Positive: simple for the operator, durable enough for review, and platform events are queryable in Azure.
- Negative / risks: local log lives on the operator machine and must be collected explicitly; platform logs do not contain the CLI actor field.
- Mitigations: document log collection in the runbooks; copy redacted samples to `audit/samples/` and `evidence/logs/audit-trail/`.

## Build divergence notes

The local audit log is TSV rather than JSON lines because that is what the CLI writes;
`audit/schema.md` documents the actual fields.
