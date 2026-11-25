# LEDGERPOINT — INCIDENT REPORT

**Incident ID:** LP-IR-001
**Project:** LedgerPoint Secure Cloud File Storage System
**Team:** TECHCRUSH Group 2
**Incident date:** November 23, 2026
**Status:** Resolved
**Incident type:** Cloud monitoring configuration failure
**Environment:** Azure capstone test environment

## 1. Executive Summary

During the implementation of LedgerPoint's secure cloud file storage system, the team encountered a failure while enabling Azure Blob Storage diagnostic logging.

Azure rejected the diagnostic-setting creation request because the subscription had not registered the `Microsoft.Insights` resource provider.

This prevented the team from completing the planned Azure-side audit logging configuration until the issue was resolved.

The team registered the required provider, verified its status, enabled the diagnostic categories, and successfully retrieved Azure Blob activity records through Log Analytics.

There was no observed compromise of confidential financial statements during this incident. Testing used fictional documents.

## 2. Incident Description

LedgerPoint requires audit records for operations involving confidential client financial documents.

The monitoring implementation uses Azure Monitor diagnostic settings and a Log Analytics workspace to record Blob Storage read, write, and delete operations.

During setup, the following error was returned:

`Please register the subscription with Microsoft.Insights.`

Although the Azure error was labeled `InvalidAuthenticationToken`, its accompanying message identified the missing resource-provider registration.

The team therefore investigated the subscription registration state.

## 3. Impact Assessment

**Affected component:** Azure Blob Storage diagnostic logging.

**Operational impact:** The planned diagnostic setting could not initially be created, delaying Azure-side audit visibility.

**Security impact:** An audit-configuration gap existed during setup. Without independent cloud logs, investigating unauthorized document access would have been more difficult.

**Data confidentiality impact:** No unauthorized disclosure was established by this incident.

**Data integrity impact:** No document alteration or loss was established.

**Business impact:** Delayed completion and validation of the monitoring component in the capstone environment.

## 4. Investigation and Timeline

The following sequence was reconstructed from the team's terminal results:

1. The team attempted to enable `StorageRead`, `StorageWrite`, and `StorageDelete` diagnostic categories.
2. An unsupported Azure CLI argument was identified and removed.
3. A subsequent diagnostic-setting creation attempt failed with a message requiring `Microsoft.Insights` registration.
4. The team inspected the provider's registration status.
5. The status initially showed `Registering` and later changed to `Registered`.
6. The team verified that the Blob service supported all three diagnostic categories.
7. The diagnostic setting `ledgerpoint-blob-audit` was successfully created.
8. The configuration was verified as enabled and connected to the Log Analytics workspace.
9. Fresh upload, list, download, and delete operations were performed using fictional data.
10. Log Analytics queries were tested. Results were found in the `StorageBlobLogs` table.

Exact timestamps for every investigation step were not captured in this report.

## 5. Root Cause Analysis

**Primary root cause:** The Azure subscription had not completed registration of the `Microsoft.Insights` resource provider.

Azure diagnostic settings depend on this resource provider. Until the registration requirement was satisfied, the diagnostic-setting creation request could not succeed.

**Contributing issues:**

- The initial command contained an argument unsupported by the locally installed Azure CLI command.
- Initial queries targeted `AzureDiagnostics`, while the ingested Blob activity records were found in `StorageBlobLogs`.

These issues increased troubleshooting time but did not change the primary registration-related root cause.

## 6. Remediation Actions

The team completed the following actions:

- Registered the `Microsoft.Insights` resource provider.
- Verified that the registration state was `Registered`.
- Confirmed support for the required Blob diagnostic categories.
- Successfully created the Azure diagnostic setting.
- Verified that all three categories were enabled.
- Connected the diagnostic setting to the Log Analytics workspace.
- Performed fresh storage operations.
- Queried the `StorageBlobLogs` table to verify audit ingestion.

## 7. Resolution Verification

The following results were retrieved from Log Analytics:

| Diagnostic category | Events observed |
|---|---:|
| StorageRead | 3 |
| StorageWrite | 1 |
| StorageDelete | 1 |
| **Total** | **5** |

These records demonstrated that read, write, and delete activity had been ingested into Azure's independent logging system.

The team's application audit log also recorded the successful upload, listing, download, and deletion of a fictional test document.

**Resolution outcome:** The Azure diagnostic logging configuration was successfully enabled and its ingestion verified.

## 8. Preventive Recommendations

To reduce the risk of recurrence, the team recommends:

1. Add required Azure resource-provider checks to the deployment preflight process.
2. Validate Azure CLI command compatibility before deployment.
3. Automate diagnostic-setting configuration and verification.
4. Include Log Analytics ingestion checks in the deployment acceptance tests.
5. Document the actual log table used by the environment.
6. Maintain local application audit logs alongside independent Azure-side logs.
7. Restrict access to audit evidence and exclude SAS tokens, credentials, and confidential document contents.

## 9. Lessons Learned

Cloud infrastructure deployment requires more than creating storage accounts and containers.

Monitoring dependencies, provider registration, CLI compatibility, data ingestion, and evidence verification are also part of a reliable DevOps implementation.

The team also learned that a successful configuration command is not sufficient evidence of working monitoring. Actual audit records must be retrieved and inspected.

## 10. Supporting Evidence

- Terminal output confirming the provider registration error.
- Terminal output showing `Microsoft.Insights` as `Registered`.
- Diagnostic-setting verification showing three enabled categories.
- Log Analytics query returning five categorized Blob activity events.
- Local application audit records for the storage-operation test.
- Automated storage, sharing, and security test results.

Evidence shared externally must be sanitized to remove account identifiers, credentials, SAS query strings, and other sensitive information.

## 11. Conclusion

The diagnostic logging configuration failure was investigated and resolved.

LedgerPoint subsequently demonstrated the ability to collect independent Azure Blob Storage activity records and maintain local application audit events.

This incident highlights the importance of validating cloud monitoring as part of secure infrastructure deployment.

**Final status: Resolved.**