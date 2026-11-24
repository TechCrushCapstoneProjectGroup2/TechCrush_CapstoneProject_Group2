# LedgerPoint — Secure Cloud File Storage System

**TECHCRUSH Group 2 | DevOps & Cloud Engineering Capstone**

## 1. Project Overview

LedgerPoint is a fictional accounting firm that manages confidential client financial documents.

This project implements a secure cloud-based storage and external auditor-sharing solution using Microsoft Azure and Bash automation.

Authorized staff can upload, list, download, and delete documents. They can also create temporary, read-only sharing links for external auditors without requiring those auditors to have Azure accounts.

The project includes access revocation, automated expired-share cleanup, audit logging, deployment automation, and security tests.

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
| Azure CLI | Azure operations |
| Bash / Git Bash | Automation and command-line interface |
| Git and GitHub | Version control and team collaboration |
| Visual Studio Code | Development environment |
| cURL | HTTP security verification |

## 4. System Architecture

```text
Authorized LedgerPoint Staff
             |
             v
     Git Bash / Azure CLI
             |
             v
      ledgerpoint.sh
             |
             v
    Microsoft Entra ID
       + Azure RBAC
             |
             v
     Azure Blob Storage
             |
       +-----+------+
       |            |
       v            v
   originals   temporary-shares
       |            |
       |            v
       |      Read-only HTTPS
       |      User Delegation SAS
       |            |
       |            v
       |      External Auditor
       |
       v
  Protected master files

Application Audit Log
          +
Azure Blob Diagnostics
          |
          v
 Log Analytics Workspace
```

The `originals` container stores the master documents.

The `temporary-shares` container stores individually created copies for auditors. Revoking an auditor's access deletes the relevant temporary copy without deleting the original.

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
- Individual temporary copies for auditor sharing.
- Explicit confirmation before destructive CLI operations.
- Expiration metadata on newly created auditor copies.
- Separate local and Azure-side audit logging.
- Git exclusions for local logs and confidential documents.

**Important:** The storage account's public network endpoint is enabled, but anonymous Blob access is disabled. This does not constitute private-endpoint network isolation.

## 7. Project Structure

```text
ledgerpoint-group2-capstone/
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
│   └── cleanup.sh
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

The current deployment script creates or reuses the resource group and storage account, verifies storage security settings, and ensures the two private containers exist.

**Current limitation:** RBAC role assignment, resource-provider registration, and Log Analytics diagnostic configuration are not yet fully automated by `deploy.sh`. These must be prepared separately in a fresh environment.

## 10. Application Commands

Display help:

```bash
./scripts/ledgerpoint.sh help
```

List original documents:

```bash
./scripts/ledgerpoint.sh list originals
```

Upload a document:

```bash
./scripts/ledgerpoint.sh upload samples/example.txt
```

Download a document:

```bash
./scripts/ledgerpoint.sh download example.txt
```

Delete a document:

```bash
./scripts/ledgerpoint.sh delete example.txt --confirm
```

Create a 30-minute temporary auditor link:

```bash
SAS_URL="$(./scripts/ledgerpoint.sh share example.txt 30)"
```

The SAS URL is captured in a shell variable rather than printed.

Identify the temporary auditor copy:

```bash
SHARE_BLOB="${SAS_URL%%\?*}"
SHARE_BLOB="${SHARE_BLOB##*/}"
```

Revoke that share:

```bash
./scripts/ledgerpoint.sh revoke "$SHARE_BLOB" --confirm
```

Clear the temporary credential:

```bash
unset SAS_URL
```

The default SAS duration is 30 minutes, with a maximum of 60 minutes.

SAS expiry prevents new authorized requests after expiry, but does not delete the temporary Blob or recall files previously downloaded by the recipient.

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

Cleanup currently requires a manual invocation. Production scheduling and additional safeguards remain future improvements.

## 12. Audit Logging

### Application Logging

Local application events are recorded in:

```text
logs/ledgerpoint-audit.tsv
```

Records include time, operator, operation, target, result, and details.

Raw audit logs must be protected and sanitized before sharing.

### Azure Diagnostic Logging

Blob diagnostic categories enabled:

- `StorageRead`
- `StorageWrite`
- `StorageDelete`

The records were successfully queried from the Log Analytics `StorageBlobLogs` table.

A verified sample query is:

```kusto
StorageBlobLogs
| where TimeGenerated > ago(24h)
| summarize Events=count() by Category
| order by Category asc
```

During testing, the workspace returned five events across the three categories.

Log Analytics ingestion may incur Azure charges.

## 13. Automated Testing

Run the storage tests:

```bash
./tests/test-storage.sh
```

Run the sharing and revocation tests:

```bash
./tests/test-sharing.sh
```

Run the security regression tests:

```bash
./tests/test-security.sh
```

### Verified Results — November 23, 2026

| Test Suite | Result |
|---|---|
| Storage automation | 8/8 passed |
| Secure sharing and revocation | 12/12 passed |
| Security regression | 12/12 passed |
| **Total** | **32/32 passed** |

Additional manual tests verified that revoking one auditor's share did not affect another independent auditor's share.

Expired-share cleanup also reported the successful removal of an expired temporary copy.

These tests validate the implemented scenarios, not every possible production security condition.

## 14. Incident Report

The incident report is available at:

```text
docs/incident-report.md
```

It documents a cloud monitoring configuration failure caused by an unregistered `Microsoft.Insights` resource provider.

The provider was registered, diagnostic settings were enabled, and Azure Blob activity logs were successfully retrieved.

## 15. Known Limitations and Future Improvements

Before production deployment, the following should be addressed:

- Separate staff identities and role-based permission testing.
- Reduction of broad administrative privileges.
- Automatic provisioning of RBAC and monitoring dependencies.
- Scheduled expired-share cleanup.
- Review of legacy temporary blobs without expiry metadata.
- Stronger protection and retention of application audit logs.
- Formal approval and secure delivery of auditor sharing links.
- Tracking the intended auditor for each share.
- Improved failure recovery and concurrency controls.
- Private network connectivity where required.
- Additional integration and security tests.

The current implementation is an educational capstone prototype, not a production-certified financial document platform.

## 16. Demonstration Workflow

The final group demonstration should show:

1. Azure storage security configuration.
2. Successful infrastructure deployment verification.
3. Upload and download of a fictional document.
4. Generation of a temporary auditor link.
5. Successful read access without an Azure login.
6. Rejection of an unauthorized DELETE operation.
7. Early revocation of one auditor share.
8. Preservation of the original document.
9. Automated test results.
10. Application and Azure audit evidence.
11. Expired-share cleanup behavior.
12. Incident report and lessons learned.

Never display complete SAS URLs or confidential document contents during the demonstration.

## 17. Project Status

Core CLI functionality, Azure storage configuration, diagnostic logging, and the three automated test suites have been verified.

Final documentation, sanitized submission evidence, GitHub publication, and group demonstration preparation are in progress.

---

**TECHCRUSH Group 2 — LedgerPoint Secure Cloud File Storage System**
