# System overview (as built)

## Components

| Component | Responsibility | Implementation |
| --- | --- | --- |
| Office manager / staff | Upload and share files | `scripts/ledgerpoint-cli.sh` |
| CLI tool | upload, download, list, delete, share, revoke | `scripts/commands/` + `scripts/` |
| Cloud storage | Private blob holding financial statements | `deploy/` |
| Share capability | Time-limited unguessable link | user delegation SAS (ADR-001) |
| Audit trail | Append-only record of actions | `audit/` + Log Analytics |
| Automation | Provision/verify/tear down | `deploy/`, `.github/workflows/` |

## Trust boundary

Storage is private. The only thing that crosses to the outside is a **single,
time-limited capability URL** for a specific object. No account, no listing, no
container-level access.

## Diagram

The source for this diagram is `../01-design/diagrams/architecture.md`.

```mermaid
flowchart LR
    subgraph Private["Private (LedgerPoint / Azure)"]
        Staff["Office manager<br/>bash scripts/ledgerpoint-cli.sh"]
        CLI["CLI + commands/<br/>Entra auth (--auth-mode login)"]
        Storage[("Azure Blob Storage<br/>private container<br/>public access OFF<br/>shared key OFF")]
        Audit[("Audit log<br/>local TSV + Log Analytics")]
        Deploy["deploy/<br/>provision + verify + teardown"]
    end

    subgraph Outside["Outside (no Azure account)"]
        Auditor["Auditor browser"]
    end

    Staff --> CLI
    CLI -->|upload / download / list / delete| Storage
    CLI -->|generate SAS / revoke keys| Storage
    CLI -->|timestamp, actor, action, target, status| Audit
    Deploy -->|creates and verifies| Storage
    Storage -->|"one-time read-only SAS URL<br/>HTTPS only, expires"| Auditor
    Auditor -.->|"GET single blob (no login)"| Storage

    classDef private fill:#e8f4ff,stroke:#0366d6;
    classDef outside fill:#fff4e5,stroke:#d97706;
    class Staff,CLI,Storage,Audit,Deploy private;
    class Auditor outside;
```

What the diagram proves:

- the auditor never receives an account, a listing or container access;
- the SAS URL is the only object crossing the trust boundary, and it is temporary;
- every operator action is written to the audit trail before the tool exits.
