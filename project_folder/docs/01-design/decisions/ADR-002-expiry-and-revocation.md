# ADR-002: Link expiry and revocation

Status: ACCEPTED | Date: 2026-11-23 | Decision owners: LedgerPoint project team

## Context

A link sent to an auditor must stop working on its own, and the firm must be able to
cut access early if a document is sent to the wrong person.

## Decision

- Default TTL: **24 hours** - enough time for a normal audit review without leaving a long-lived credential.
- Maximum TTL: **72 hours** - enforced by `MAX_SHARE_HOURS`; longer requests are rejected.
- Early revocation method: revoke all **user delegation keys** for the storage account. Azure user delegation SAS links cannot be individually revoked, so all active links are invalidated at once.
- Operator command: `bash scripts/ledgerpoint-cli.sh revoke-share`
- Verification: reopen a previously issued link and expect **HTTP 403**. Automated check: `bash tests/integration/run.sh`.

## Alternatives rejected

| Alternative | Why rejected |
| --- | --- |
| No expiry | Violates the brief |
| Manual portal-only revocation | Not scriptable/repeatable; office manager cannot reproduce it |
| Per-link revocation | Not supported for user delegation SAS in Azure |
| Rotating account keys | Shared key access is disabled; would not affect user delegation SAS |

## Consequences

- Positive: links expire automatically; one simple command cuts all access; verification is scriptable.
- Negative / risks: revoking keys invalidates legitimate links too, so they must be reissued; the operator needs broader ARM permission for the revoke action.
- Mitigations: document the blast radius in the operator runbook; save a redacted before/after proof; reissue links after revocation.

## Build divergence notes

User delegation SAS links cannot be revoked individually, so "revoke" means revoking
all user delegation keys for the storage account. See `sas-policy.md` for operator steps.
