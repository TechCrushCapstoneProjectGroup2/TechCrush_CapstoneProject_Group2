# LedgerPoint — Secure Cloud File Storage System

**TECHCRUSH Group 2 | DevOps & Cloud Engineering Capstone**

## 1. Project Overview

LedgerPoint is a fictional accounting firm that manages confidential client financial documents.

This project implements a secure cloud-based storage and external auditor-sharing solution using Microsoft Azure and modular Bash automation.

Authorized staff can upload, list, download, and delete documents. They can also create temporary, read-only sharing links for external auditors without requiring those auditors to have Azure accounts.

The project includes access revocation, expired-share cleanup automation, audit logging, infrastructure deployment automation, and security tests.

The application separates its six major operational functions into dedicated modules while maintaining a unified command-line interface. This architecture promotes maintainability, separation of concerns, and effective team collaboration.

**All project test documents contain fictional data.**

## 2. Project Objectives

- Protect financial documents against anonymous access.
- Authenticate staff through Microsoft Entra ID.
- Manage Blob operations using Azure RBAC.
- Generate time-limited, read-only auditor links.
- Allow individual auditor shares to be revoked.
- Preserve original documents during share revocation.
- Record application and Azure-side storage activity.
- Automate infrastructure verification and functional testing.
- Implement a modular application architecture.
- Improve code maintainability and team collaboration.
- Preserve document integrity during upload and download operations.

## 3. Technology Stack

| Technology | Purpose |
|---|---|
| Microsoft Azure | Cloud platform |
| Azure Blob Storage | Confidential document storage |
| Microsoft Entra ID | Staff authentication |
| Azure RBAC | Staff authorization |
| User Delegation SAS | Temporary external access |
| Azure Monitor | Cloud diagnostic logging |
| Log Analytics | Audit investigation |
| KQL | Querying and analysing Azure diagnostic logs |
| Azure CLI | Azure operations |
| Bash / Git Bash | Modular automation and command-line interface |
| Git and GitHub | Version control and team collaboration |
| Visual Studio Code | Development environment |
| cURL | HTTP security verification |
| SHA-256 | Document integrity verification |

## 4. System Architecture

LedgerPoint implements a modular, cloud-integrated Bash CLI architecture.

The main application, `scripts/ledgerpoint.sh`, acts as a unified command dispatcher that loads six dedicated operational modules using Bash sourcing.

Shared configuration, validation, and application audit functions remain within the main application.

Infrastructure deployment and expired-share cleanup are managed through separate supporting automation scripts.

### 4.1 Architecture Diagram

```text
                 Authorized LedgerPoint Staff
                              |
                              v
                           Git Bash
                              |
                              v
                       ledgerpoint.sh
                     Command Dispatcher
                              |
          +-------------------+-------------------+
          |                                       |
          v                                       v
   Operational Modules                     Shared Functions
   -------------------                     ----------------
   Upload                                  Configuration
   Download                                Validation
   List                                    Audit Logging
   Delete                                         |
   Share                                          v
   Revoke                              Application Audit Log
          |
          v
      Azure CLI
          |
          v
   Microsoft Entra ID
      + Azure RBAC
          |
          v
   Azure Blob Storage -------> Azure Blob Diagnostics
          |                              |
    +-----+------+                       v
    |            |              Log Analytics Workspace
    v            v
 originals   temporary-shares
    |            ^
    |            |
    v      Read-only HTTPS
 Protected User Delegation SAS
 Master          |
 Files           |
                 |
          External Auditor
```

The `originals` container stores the master financial documents.

The `temporary-shares` container stores individually created copies for external auditors.

Revoking an auditor's access deletes the relevant temporary copy without deleting the original document or affecting other independent auditor shares.

External auditors connect directly to Azure Blob Storage through a secure SAS URL without requiring an Azure account or access to the internal CLI.

### 4.2 Modular Application Design

The application is divided into six operational modules.

| Module | Script | Responsibility |
|---|---|---|
| Upload | `scripts/modules/upload/upload.sh` | Upload documents to the originals container |
| Download | `scripts/modules/download/download.sh` | Download authorized original documents |
| List | `scripts/modules/list/list.sh` | List documents in supported containers |
| Delete | `scripts/modules/delete/delete.sh` | Delete original documents with explicit confirmation |
| Share | `scripts/modules/share/share.sh` | Create temporary auditor copies and secure SAS links |
| Revoke | `scripts/modules/revoke/revoke.sh` | Revoke individual auditor access |

### 4.3 Supporting Application Components

| Component | Responsibility |
|---|---|
| `scripts/ledgerpoint.sh` | Main command dispatcher, validation, configuration, and audit logging |
| `scripts/deploy.sh` | Azure infrastructure deployment and security configuration |
| `scripts/cleanup.sh` | Identification and removal of expired temporary shares |
| `config/config.example.env` | Example environment configuration |
| `tests/test-storage.sh` | Storage functionality regression tests |
| `tests/test-sharing.sh` | Sharing and revocation regression tests |
| `tests/test-security.sh` | Security regression tests |

### 4.4 Architectural Benefits

The modular architecture provides:

- Separation of concerns.
- Clearly defined operational responsibilities.
- Improved code readability and maintainability.
- Easier troubleshooting and debugging.
- Easier collaboration between group members.
- Reduced likelihood of Git merge conflicts.
- Simplified development and testing of individual modules.
- Preservation of existing application commands.
- Preservation of shared configuration and security controls.
- A foundation for future architectural expansion.

LedgerPoint is a modular application with a unified CLI core supported by Azure-managed cloud services.

The operational modules are separated at the source-code level but are loaded into the same Bash application process. They are not independently deployed microservices.

## 5. Azure Environment

| Resource | Name |
|---|---|
| Resource Group | `rg-ledgerpoint-capstone` |
| Storage Account | `lpg21795439984` |
| Azure Region | `eastus` |
| Original Container | `originals` |
| Auditor Container | `temporary-shares` |
| Log Analytics Workspace | `law-ledgerpoint-capstone` |
| Diagnostic Setting | `ledgerpoint-blob-audit` |

These names describe the tested capstone environment. Another deployment must use its own valid configuration.

## 6. Security Controls

The implementation uses:

- Disabled anonymous Blob access.
- Disabled Shared Key authentication.
- HTTPS-only storage access.
- Minimum TLS 1.2.
- Microsoft Entra authentication for staff operations.
- Azure RBAC for Blob data access.
- Read-only, HTTPS-only User Delegation SAS links.
- Blob-level SAS authorization.
- Default SAS validity of 15 minutes.
- Minimum SAS validity of 1 minute.
- Maximum SAS validity of 60 minutes.
- Explicit UTC SAS start and expiration times.
- Azure Storage SAS expiration policy configured to Block.
- Individual temporary copies for auditor sharing.
- Targeted early revocation of individual auditor shares.
- Explicit confirmation before destructive CLI operations.
- Expiration metadata on newly created auditor copies.
- Separate local and Azure-side audit logging.
- Git exclusions for local logs and confidential documents.

### 6.1 SAS Expiration Policy

The application enforces the following sharing policy:

| Setting | Value |
|---|---|
| Default duration | 15 minutes |
| Minimum duration | 1 minute |
| Maximum duration | 60 minutes |
| SAS type | User Delegation SAS |
| Permission | Read-only |
| Protocol | HTTPS-only |
| Resource scope | Individual Blob |
| Azure expiration policy action | Block |
| Azure maximum validity interval | 0.01:00:00 |

The Azure expiration policy prevents requests using SAS tokens that violate the configured maximum validity interval.

The CLI also rejects sharing durations outside the permitted range.

### 6.2 Revocation Policy

Each auditor share uses an individually created temporary document copy.

When access is revoked:

1. The application validates the temporary Blob name.
2. Explicit confirmation is required.
3. The relevant temporary auditor copy is deleted.
4. Subsequent retrieval requests using the revoked URL fail.
5. The original financial document remains intact.
6. Other independent auditor shares remain unaffected.

SAS expiration and revocation prevent subsequent retrieval of the shared document but cannot recall copies previously saved by recipients.

**Important:** The storage account's public network endpoint is enabled, but anonymous Blob access is disabled. This does not constitute private-endpoint network isolation.

## 7. Project Structure

```text
ledgerpoint-secure-storage/
├── .gitignore
├── .gitattributes
├── README.md
├── config/
│   └── config.example.env
├── docs/
│   ├── architecture.md
│   ├── phase-0-design.md
│   ├── incident-report.md
│   └── security-test-results.md
├── scripts/
│   ├── deploy.sh
│   ├── ledgerpoint.sh
│   ├── cleanup.sh
│   └── modules/
│       ├── upload/
│       │   └── upload.sh
│       ├── download/
│       │   └── download.sh
│       ├── list/
│       │   └── list.sh
│       ├── delete/
│       │   └── delete.sh
│       ├── share/
│       │   └── share.sh
│       └── revoke/
│           └── revoke.sh
├── tests/
│   ├── test-storage.sh
│   ├── test-sharing.sh
│   └── test-security.sh
├── evidence/
│   ├── screenshots/
│   └── sanitized-logs/
├── logs/
├── samples/
└── downloads/
```

The `modules/` directory contains the application's six operational components.

The main `ledgerpoint.sh` script loads these modules and provides a consistent command-line interface.

Local logs, temporary downloads, and test documents must not be committed when they contain confidential information.

## 8. Prerequisites

The system requires:

- Bash or Git Bash
- Azure CLI
- An Azure subscription
- Appropriate Azure management and Blob data permissions
- An authenticated Azure CLI session
- cURL
- Git

Sign in to Azure:

```bash
az login

az account show --output table
```

Set the project's configuration:

```bash
export RESOURCE_GROUP="rg-ledgerpoint-capstone"
export STORAGE_ACCOUNT="lpg21795439984"
```

## 9. Infrastructure Deployment

Validate the deployment script:

```bash
bash -n scripts/deploy.sh
```

Run:

```bash
./scripts/deploy.sh
```

The current deployment script:

- Creates or reuses the resource group.
- Creates or reuses the storage account.
- Verifies storage security settings.
- Disables anonymous Blob access.
- Disables Shared Key authentication.
- Configures HTTPS enforcement and minimum TLS requirements.
- Configures the one-hour SAS expiration Block policy.
- Ensures the two private containers exist.
- Verifies the configured security controls.

**Current limitation:** RBAC role assignment, resource-provider registration, and Log Analytics diagnostic configuration are not yet fully automated by `deploy.sh`. These must be prepared separately in a fresh environment.

## 10. Application Commands

All application commands should be executed from the project directory.

The modular application retains the original command-line interface. Users do not need to execute individual module files directly.

### 10.1 Display Help

```bash
./scripts/ledgerpoint.sh help
```

### 10.2 List Original Documents

```bash
./scripts/ledgerpoint.sh list originals
```

### 10.3 List Temporary Auditor Copies

```bash
./scripts/ledgerpoint.sh list temporary-shares
```

### 10.4 Upload a Document

```bash
./scripts/ledgerpoint.sh upload samples/example.txt
```

### 10.5 Download a Document

```bash
./scripts/ledgerpoint.sh download example.txt
```

### 10.6 Delete a Document

```bash
./scripts/ledgerpoint.sh delete example.txt --confirm
```

### 10.7 Create a Temporary Auditor Link

Create a temporary auditor link using the default 15-minute duration:

```bash
SAS_URL="$(./scripts/ledgerpoint.sh share example.txt)"
```

Alternatively, create a link with a specified duration:

```bash
SAS_URL="$(./scripts/ledgerpoint.sh share example.txt 30)"
```

Use one command for each intended share.

The SAS URL is captured in a shell variable rather than printed.

The default SAS duration is 15 minutes, with a maximum of 60 minutes.

### 10.8 Identify the Temporary Auditor Copy

```bash
SHARE_BLOB="${SAS_URL%%\?*}"
SHARE_BLOB="${SHARE_BLOB##*/}"
```

### 10.9 Verify Auditor Access

```bash
curl -sS -o /dev/null \
    -w 'HTTP status: %{http_code}\n' \
    "$SAS_URL"
```

Expected result for an active, valid link:

```text
HTTP status: 200
```

### 10.10 Revoke Auditor Access

```bash
./scripts/ledgerpoint.sh revoke "$SHARE_BLOB" --confirm
```

Verify that the revoked link no longer works:

```bash
curl -sS -o /dev/null \
    -w 'HTTP status: %{http_code}\n' \
    "$SAS_URL"
```

The tested revocation mechanism returned HTTP 404 after the temporary Blob was deleted.

### 10.11 Clear Temporary Credentials

```bash
unset SAS_URL
unset SHARE_BLOB
```

SAS expiry prevents new authorized requests after expiration but does not delete the temporary Blob or recall files previously downloaded by the recipient.

A read-only SAS permits retrieval of document contents and does not independently enforce download prevention.

## 11. Expired-Share Cleanup

Preview cleanup candidates without deleting anything:

```bash
./scripts/cleanup.sh
```

Apply cleanup with confirmation:

```bash
./scripts/cleanup.sh --apply --confirm
```

The cleanup script only considers `auditor-` objects in `temporary-shares` with LedgerPoint management and expiry metadata.

Older temporary copies created before metadata was implemented require separate, authorized review.

Cleanup currently requires manual invocation. Production scheduling and additional safeguards remain future improvements.

## 12. Audit Logging

LedgerPoint uses two complementary logging mechanisms:

- Application-level audit logging.
- Azure-side Blob Storage diagnostic logging.

### 12.1 Application Logging

Local application events are recorded in:

```text
logs/ledgerpoint-audit.tsv
```

Records include:

- Timestamp.
- Operator.
- Operation.
- Target document.
- Operation result.
- Additional event details.

Shared audit functions are maintained within the main application and are available to the operational modules.

Raw audit logs must be protected and sanitized before sharing.

Complete SAS URLs must never be recorded in application audit logs.

### 12.2 Azure Diagnostic Logging

Blob diagnostic categories enabled:

- `StorageRead`
- `StorageWrite`
- `StorageDelete`

Azure Blob diagnostic logs provide evidence of requests made directly to Azure Storage, including external auditor requests that bypass the internal Bash application.

The records were successfully queried from the Log Analytics `StorageBlobLogs` table.

A verified sample query is:

```kusto
StorageBlobLogs
| where TimeGenerated > ago(24h)
| summarize Events=count() by Category
| order by Category asc
```

During earlier testing, the workspace returned five events across the three categories.

### 12.3 Audit and Identity Limitations

User Delegation SAS links are bearer credentials.

Although Azure can record SAS-authorized requests, timestamps, request outcomes, and available requester information, possession of a SAS link does not conclusively establish the identity of the individual using it.

Successful Blob retrieval requests may represent browser viewing, downloading, or partial-content retrieval.

They must not automatically be interpreted as completed downloads saved to a recipient's device.

Log Analytics ingestion may incur Azure charges.

## 13. Automated Testing

LedgerPoint includes three automated regression test suites.

### 13.1 Storage Functionality Tests

```bash
bash tests/test-storage.sh
```

The storage suite verifies:

1. Local test document creation.
2. Document upload.
3. Azure Blob existence.
4. Document listing.
5. Document download.
6. Document content integrity.
7. Document deletion.
8. Successful deletion verification.

### 13.2 Sharing and Revocation Tests

```bash
bash tests/test-sharing.sh
```

The sharing suite verifies:

1. Fictional test document creation.
2. Original document upload.
3. Secure sharing link generation.
4. Temporary auditor copy existence.
5. Authorized auditor retrieval.
6. Rejection of revocation without confirmation.
7. Successful access revocation.
8. Temporary auditor copy deletion.
9. Denial of the revoked link.
10. Original document preservation.
11. Disposable original deletion.
12. Test cleanup verification.

### 13.3 Security Regression Tests

```bash
bash tests/test-security.sh
```

The security suite verifies:

1. Azure Storage security settings.
2. Disposable security document upload.
3. Anonymous access denial.
4. Rejection of deletion without confirmation.
5. Original document protection.
6. Secure HTTPS auditor link generation.
7. Authorized read-only auditor access.
8. Unauthorized auditor deletion denial.
9. Temporary copy preservation after denied deletion.
10. Early access revocation.
11. Revoked-link denial and original preservation.
12. Disposable document cleanup.

### 13.4 Verified Results — November 23, 2026

| Test Suite | Result |
|---|---|
| Storage automation | 8/8 passed |
| Secure sharing and revocation | 12/12 passed |
| Security regression | 12/12 passed |
| **Total** | **32/32 passed** |

### 13.5 Post-Modularisation Results — November 25, 2026

Following the separation of the six operational functions into dedicated modules, all existing automated regression suites were executed again.

| Test Suite | Before Modularisation | After Modularisation |
|---|---|---|
| Storage functionality | 8/8 passed | 8/8 passed |
| Sharing and revocation | 12/12 passed | 12/12 passed |
| Security regression | 12/12 passed | 12/12 passed |
| **Total** | **32/32 passed** | **32/32 passed** |

**Post-modularisation automated regression pass rate: 100%.**

### 13.6 Individual Module Validation

| Module | Live Functionality Test |
|---|---|
| Upload module | Passed |
| Download module | Passed |
| List module | Passed |
| Delete module | Passed |
| Share module | Passed |
| Revoke module | Passed |

All six operational modules passed live Azure functionality testing.

### 13.7 Additional Security Verification

| Security Check | Verified Result |
|---|---|
| Anonymous Blob access | Disabled |
| Shared Key authentication | Disabled |
| HTTPS enforcement | Enabled |
| Minimum TLS | TLS 1.2 |
| Default SAS duration | 15 minutes |
| Maximum SAS duration | 60 minutes |
| Azure SAS expiration policy | Block |
| Valid auditor retrieval | HTTP 200 |
| Anonymous document access | HTTP 409 |
| Unauthorized auditor deletion | HTTP 403 |
| Revoked auditor link | HTTP 404 |
| Original document preservation | Passed |
| Document integrity | Passed |
| Disposable test document cleanup | Passed |

Additional manual tests verified that revoking one auditor's share did not affect another independent auditor's share.

The application also successfully rejected a requested sharing duration of 61 minutes.

### 13.8 Document Integrity Verification

SHA-256 hashing was used to verify that uploaded and downloaded documents contained identical data.

The original and downloaded test documents returned matching SHA-256 hashes.

The storage regression suite also successfully verified document integrity using `cmp`.

This confirms that the tested upload and download operations preserved document contents.

### 13.9 Expired-Share Cleanup Verification

Earlier expired-share cleanup testing reported the successful removal of an expired temporary copy.

These tests validate the implemented scenarios and demonstrate that modularisation preserved the tested application functionality and security controls.

The automated regression results do not constitute verification of every possible production security condition or every capstone acceptance criterion.

## 14. Incident Report

The incident report is available at:

```text
docs/incident-report.md
```

It documents a cloud monitoring configuration failure caused by an unregistered `Microsoft.Insights` resource provider.

The provider was registered, diagnostic settings were enabled, and Azure Blob activity logs were successfully retrieved.

The incident demonstrates the importance of:

- Resource-provider registration.
- Infrastructure dependency verification.
- Cloud diagnostic monitoring.
- Systematic troubleshooting.
- Root cause analysis.
- Documenting corrective actions.
- Verifying successful incident resolution.

## 15. Known Limitations and Future Improvements

Before production deployment, the following should be addressed:

- Separate staff identities and role-based permission testing.
- Reduction of broad administrative privileges.
- Automatic provisioning of RBAC and monitoring dependencies.
- Scheduled expired-share cleanup.
- Review of legacy temporary Blobs without expiry metadata.
- Stronger protection and retention of application audit logs.
- Formal approval and secure delivery of auditor sharing links.
- Tracking the intended auditor for each share.
- Improved failure recovery and concurrency controls.
- Private network connectivity where required.
- Additional integration and security tests.
- Dedicated natural SAS expiration testing and acceptance evidence.
- Improved browser-based document viewing for supported file formats.
- Investigation and aggregation of external auditor retrieval logs.
- Improved correlation between application audit events and Azure diagnostic records.
- Potential separation of shared configuration, validation, and audit functions into common utility modules.

The current implementation is an educational capstone prototype, not a production-certified financial document platform.

## 16. Demonstration Workflow

The final group demonstration should show:

1. Azure Storage security configuration.
2. Successful infrastructure deployment verification.
3. Modular application architecture and project structure.
4. Responsibilities of the six operational modules.
5. Upload and download of a fictional document.
6. Verification of document integrity.
7. Generation of a temporary auditor link.
8. Successful read access without an Azure login.
9. Default and maximum SAS duration controls.
10. Rejection of an unauthorized DELETE operation.
11. Early revocation of one auditor share.
12. Denial of subsequent access through the revoked link.
13. Preservation of the original document.
14. Natural expiration of an auditor sharing link.
15. Automated regression test results.
16. Application and Azure audit evidence.
17. Expired-share cleanup behavior.
18. Incident report and lessons learned.

Never display complete SAS URLs or confidential document contents during the demonstration.

## 17. Project Status

### Completed and Verified

- Core CLI functionality.
- Azure Storage configuration.
- Private Blob containers.
- Microsoft Entra authentication integration.
- Azure RBAC integration.
- Secure temporary auditor sharing.
- Individual share revocation.
- SAS default and maximum duration controls.
- Azure SAS expiration Block policy.
- Application audit logging.
- Azure diagnostic logging.
- Log Analytics query execution.
- Modular application architecture.
- Separation of six operational functions.
- Bash syntax validation.
- Live functionality testing of all six modules.
- SHA-256 document integrity verification.
- Automated storage regression testing.
- Automated sharing regression testing.
- Automated security regression testing.

### Current Regression Testing Status

| Category | Result |
|---|---|
| Operational modules | 6/6 passed |
| Automated storage tests | 8/8 passed |
| Automated sharing tests | 12/12 passed |
| Automated security tests | 12/12 passed |
| **Total automated regression tests** | **32/32 passed** |
| **Automated regression pass rate** | **100%** |

### Remaining Activities

- Final architecture documentation.
- Publication of the modular application to the designated group GitHub branch.
- Detailed auditor retrieval log investigation.
- Browser-based document viewing improvements.
- Natural SAS expiration acceptance evidence.
- Completion of remaining role-based permission tests.
- Final sanitized submission evidence.
- Group integration and demonstration preparation.

The modular application has successfully passed all existing automated regression tests as of November 25, 2026.

The project remains under development until all outstanding capstone acceptance requirements and deliverables have been completed and verified.

---

**TECHCRUSH Group 2 — LedgerPoint Secure Cloud File Storage System**