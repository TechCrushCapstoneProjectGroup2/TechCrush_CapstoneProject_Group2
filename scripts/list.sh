#!/bin/bash
# @Author: Your name
# @Date:   2026-11-22 22:10:16
# @Last Modified by:   Your name
# @Last Modified time: 2026-11-22 22:34:11
#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

check_azure_login
check_storage

echo "=========================================="
echo " LEDGERPOINT STORED DOCUMENTS"
echo "=========================================="

if az storage blob list \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$FILE_CONTAINER" \
    --auth-mode login \
    --query "[].{File:name,Size:properties.contentLength,Modified:properties.lastModified}" \
    --output table
then

    audit_log "LIST" "ALL_FILES" "SUCCESS"

else

    audit_log "LIST" "ALL_FILES" "FAILED"

    error_message "Could not retrieve documents."

    exit 1

fi
