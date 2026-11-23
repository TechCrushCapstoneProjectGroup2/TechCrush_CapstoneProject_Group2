# Architecture diagrams (source)

Mermaid source for the diagrams referenced by the Phase 0 worksheet and
`docs/02-architecture/`.

## 1. System overview

```mermaid
flowchart LR
    Staff["Office manager"] --> CLI["LedgerPoint CLI<br/>(Bash, Entra login)"]
    CLI --> Store[("Private Azure Blob Storage<br/>container: financial-statements")]
    CLI --> Log[("Audit log<br/>local + Log Analytics")]
    Deploy["deploy/ scripts"] --> Store
    Store -->|"read-only SAS, HTTPS, expires"| Auditor["External auditor<br/>(no Azure account)"]
```

## 2. Data flow (upload and share)

```mermaid
sequenceDiagram
    actor Op as Office manager
    participant CLI as ledgerpoint-cli.sh
    participant Az as Azure Blob Storage
    participant Log as Audit log

    Op->>CLI: upload ./statement.pdf clientA/statement.pdf
    CLI->>Az: az storage blob upload --auth-mode login
    Az-->>CLI: blob stored (private container)
    CLI->>Log: UPLOAD | actor | UTC | target | SUCCESS
    CLI-->>Op: upload complete

    Op->>CLI: share clientA/statement.pdf 24
    CLI->>CLI: validate hours <= MAX_SHARE_HOURS
    CLI->>Az: generate-sas --as-user --permissions r --https-only
    Az-->>CLI: signed URL (expires at UTC timestamp)
    CLI->>Log: SHARE | actor | UTC | target | expiry | SUCCESS
    CLI-->>Op: URL printed once (never logged)
    Op->>Az: auditor opens URL -> single blob downloaded
```

## 3. Trust boundary

```mermaid
flowchart TB
    subgraph Trusted["Trusted / private"]
        A["Staff + CLI (Entra identity)"]
        B["Storage account: public access OFF<br/>shared key OFF, HTTPS only, TLS 1.2"]
        C["Audit trail: writers = CLI only"]
    end

    subgraph Temporary["Temporary capability"]
        D["User delegation SAS<br/>read-only, single blob, 24h default / 72h max"]
    end

    subgraph Untrusted["Untrusted / public internet"]
        E["Auditor browser (no login)"]
        F["Search engines / anonymous scanners"]
    end

    A --> B
    A --> C
    B --> D
    D --> E
    F -.->|"anonymous list: denied (403)"| B
    E -.->|"expired or revoked link: denied (403)"| B
```
