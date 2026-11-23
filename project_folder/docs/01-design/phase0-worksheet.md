# Phase 0 design worksheet - Project 2

Status: ACCEPTED | Team sign-off: LedgerPoint project team | Date: 2026-11-23

## 2.1 Access mechanism decision

| Criterion | Public container / bucket | Expiring SAS / presigned URL (chosen) | Auditor accounts |
| --- | --- | --- | --- |
| Requires auditor account? | No | No | Yes |
| Discoverable by search engines? | Yes | No | No |
| Guessable by URL? | Yes - container is listable | No - signed URL is high-entropy | No |
| Can it expire? | No | Yes | N/A |
| Can access be revoked early? | Only by removing all access | Yes - revoke delegation keys for all links | Yes |
| Blast radius if link leaks? | Whole container exposed | Single object until expiry | Single account |
| Cost / ops burden | Low but unacceptable risk | Low, scriptable | High |

**Chosen mechanism:** Private Azure Blob Storage with a read-only, HTTPS-only,
time-limited **user delegation SAS** for one specific blob.

**Justification:** The container remains private, so anonymous users cannot list or
discover objects and search engines cannot index them. A signed URL is not guessable
because it includes a cryptographic signature, and it is valid only until its explicit
UTC expiry. Access is therefore not indefinite, and the firm can revoke all active
user delegation keys early if a link is sent to the wrong person. The mechanism needs
no auditor account, satisfying the brief, while keeping the blast radius to one object.

**Rejected alternatives and why:** See `decisions/ADR-001-access-mechanism.md`.

## 2.2 Expiry and revocation policy

| Item | Decision |
| --- | --- |
| Default share-link lifetime | 24 hours - long enough for an audit review, short enough to limit exposure |
| Maximum allowed lifetime | 72 hours - enforced by `MAX_SHARE_HOURS` |
| Who can create a link | Staff/office manager with Blob data access and Storage Blob Delegator |
| Who can revoke a link | Operator with permission to revoke user delegation keys |
| Exact revoke steps | 1. Run `bash scripts/ledgerpoint-cli.sh revoke-share`. 2. Confirm all active links fail. 3. Reissue legitimate links. |
| How revocation is verified | Reopen a previously issued link; expect HTTP 403. See `tests/integration/run.sh`. |
| Evidence to capture | Successful revoke output and denied-link screenshot in `evidence/screenshots/02-successful-revoke/` |

## 2.3 Logging plan

Every action writes a local TSV record with: `timestamp`, `actor`, `action`, `target`,
`status`, `details`. Azure platform logs are sent to Log Analytics.

| Action | Fields logged | Where stored | Retention | Who can read | Who can write |
| --- | --- | --- | --- | --- | --- |
| upload | timestamp, actor, target, status, source | local audit log + Log Analytics | 30 days platform / project duration local | firm staff | CLI operator |
| download | timestamp, actor, target, status, destination | local audit log + Log Analytics | 30 days platform / project duration local | firm staff | CLI operator |
| list | timestamp, actor, container, status | local audit log + Log Analytics | 30 days platform / project duration local | firm staff | CLI operator |
| delete | timestamp, actor, target, status | local audit log + Log Analytics | 30 days platform / project duration local | firm staff | CLI operator |
| share | timestamp, actor, target, status, expiry, permissions | local audit log + Log Analytics | 30 days platform / project duration local | firm staff | CLI operator |
| revoke | timestamp, actor, storage account, status | local audit log + Log Analytics | 30 days platform / project duration local | firm staff | CLI operator |

**Rule:** log the actor, UTC timestamp, action, target, outcome and expiry where
relevant. **Never log the token or full signed URL.**

## 2.4 Design sign-off

| Decision | Agreed by | Date | ADR |
| --- | --- | --- | --- |
| Access mechanism | LedgerPoint project team | 2026-11-23 | ADR-001 |
| Expiry/revocation | LedgerPoint project team | 2026-11-23 | ADR-002 |
| Logging | LedgerPoint project team | 2026-11-23 | ADR-003 |

## 2.5 Build divergence log

| Date | What we built differently | Why | ADR updated? |
| --- | --- | --- | --- |
| 2026-11-23 | `revoke-share` revokes all user delegation keys instead of a single SAS | User delegation SAS cannot be individually revoked in Azure | Yes - ADR-002 |
| 2026-11-23 | Audit log is local TSV plus Log Analytics, not a separate private storage table | Simpler for the office manager; Log Analytics covers platform events | Yes - ADR-003 |
