# Phase 0 design (completed before build)

> The brief warns that a weak design loses marks even if the build works. This phase
> is signed off in `phase0-worksheet.md` and in the three accepted ADRs below.

1. **Access mechanism** - compare at least two options and justify the choice against
   "never discoverable, not indefinite" (ADR-001).
2. **Expiry and revocation** - default lifetime and the exact early-revoke procedure
   (ADR-002).
3. **Logging plan** - what is logged, where it is stored, who can read it (ADR-003).
4. Diagrams live in `diagrams/architecture.md` and are embedded in
   `../02-architecture/system-overview.md`.

## Files

| File | Status |
| --- | --- |
| `phase0-worksheet.md` | Accepted 2026-11-23 |
| `decisions/ADR-001-access-mechanism.md` | Accepted 2026-11-23 |
| `decisions/ADR-002-expiry-and-revocation.md` | Accepted 2026-11-23, with build-divergence note |
| `decisions/ADR-003-logging.md` | Accepted 2026-11-23, with build-divergence note |
| `decisions/sas-policy.md` | Operator policy derived from ADR-001/002 |
| `decisions/_ADR-TEMPLATE.md` | Blank template for new decisions |
| `diagrams/architecture.md` | Mermaid sources |

If the build later diverges from the design, add a one-line note in the relevant ADR
explaining why. Silence is not acceptable.
