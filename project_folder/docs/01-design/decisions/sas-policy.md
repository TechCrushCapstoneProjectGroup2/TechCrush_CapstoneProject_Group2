# SAS Policy - LedgerPoint (Project 2)

## Purpose

Define how LedgerPoint issues, uses, expires, and revokes external file-sharing links for sensitive financial statements.

## Decision

**Selected mechanism: User Delegation SAS (Azure Blob Service SAS, Entra ID-backed).**

| Option | Pros | Cons | Decision |
|---|---|---|---|
| Public container/blob | Simple | Discoverable/public, no expiry control, violates brief | **Rejected** |
| Account SAS / Service SAS with shared key | Time-limited possible | Requires shared key; weaker audit identity; conflicts with `allowSharedKeyAccess=false` | **Rejected** |
| User delegation SAS | Time-limited, HTTPS-only, read-only, Entra-authenticated issuance, works with shared key disabled | Cannot individually revoke a single SAS before expiry; revocation requires revoking user delegation keys | **Selected** |

This directly satisfies: "Auditors can open shared file from link, no login required" while keeping storage private and links time-limited.

## Policy rules

1. **Storage remains private**. Never set container/public blob access to public.
2. **HTTPS only**. All SAS links include `--https-only`.
3. **Least privilege**. Default share permission is read-only (`r`). No write/delete/list permissions in auditor links.
4. **Time-limited**. Every share link must have an explicit expiry (`--expiry`). Default: 24 hours (`DEFAULT_SHARE_HOURS=24`), configurable per share.
5. **No indefinite access**. Do not issue links without expiry. Avoid excessively long expiries; use shortest practical window.
6. **Entra ID issuance**. Links are generated with `--as-user --auth-mode login`; issuer must have `Storage Blob Delegator` and appropriate blob data permissions.
7. **Audit every share**. CLI logs share creation with actor, timestamp, blob target, expiry, permissions, and SAS type.
8. **Revocation/escalation**. If a link is sent to the wrong auditor or must be invalidated before expiry, run `bash scripts/ledgerpoint-cli.sh revoke-share`.

## Revocation procedure

User delegation SAS tokens cannot be individually revoked before expiry. Early revocation procedure:

1. Confirm incident (wrong recipient, leaked link, etc.) and record in incident/audit notes.
2. Run:
   ```bash
   STORAGE_ACCOUNT=<account> RESOURCE_GROUP=<rg> bash scripts/ledgerpoint-cli.sh revoke-share
   ```
   This executes `az storage account revoke-delegation-keys`.
3. Verify old SAS returns `403` (Signature did not match / authentication failed).
4. Re-issue new SAS links only for legitimate recipients with fresh expiry.
5. Record action in audit log (`REVOKE_SHARE` event).

**Impact**: revoking delegation keys invalidates **all** active user delegation SAS tokens for that storage account. Plan accordingly during incident response.

## Operational guidance for office manager

- Upload file: `bash scripts/ledgerpoint-cli.sh upload <file> [blob-name]`
- Share file for 2 hours: `bash scripts/ledgerpoint-cli.sh share <blob-name> 2`
- If wrong recipient: `bash scripts/ledgerpoint-cli.sh revoke-share` immediately, then re-share correct link.
- Never make container public in Azure Portal/CLI.

## Compliance notes

- SAS URLs are bearer tokens; treat as sensitive. Share via secure channel.
- Do not commit SAS URLs to git, tickets, or public docs.
- Prefer short expiries (1-24h) for auditor access.
- Log Analytics and local audit logs provide evidence for audit trail.