# ADR-001: External access mechanism

Status: ACCEPTED | Date: 2026-11-23 | Decision owners: LedgerPoint project team

## Context

Auditors have no company account but must open a specific file from a link. Files are
sensitive financial statements that must not be searchable, guessable, or permanently
available.

## Decision

Use a **private Azure Blob Storage container** with a **read-only, HTTPS-only,
time-limited user delegation SAS** for exactly one blob. The storage account has
public blob access disabled, shared key access disabled, HTTPS-only enabled and
TLS 1.2 minimum. All operator actions use Entra authentication (`--auth-mode login`).

## Alternatives rejected

| Alternative | Why rejected |
| --- | --- |
| Public container / public-read bucket | Violates the private-by-default and non-discoverable requirements |
| Anonymous link with no expiry | Violates "not indefinite" |
| Creating auditor accounts | Brief explicitly requires no login |
| Service SAS with account key | Requires shared keys, which are disabled by design |

## Consequences

- Positive: auditors need no account; the container cannot be listed; links are unguessable, expire automatically and grant read access to one object only.
- Negative / risks: a SAS URL in browser history, chat or email is a bearer credential until it expires; revocation affects all active links.
- Mitigations: short default TTL (24 h), maximum TTL (72 h), HTTPS-only, redaction script, no URL in audit logs, `revoke-share` operator command.

## Build divergence notes

none
