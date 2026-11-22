#!/bin/bash
# @Author: Your name
# @Date:   2026-11-22 22:10:16
# @Last Modified by:   Your name
# @Last Modified time: 2026-11-22 22:34:53
#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

check_azure_login
check_storage

if [[ $# -ne 1 ]]; then

    echo "Usage: ./scripts/delete.sh <blob-name>"

    exit 1

fi

BLOB_NAME="$1"

echo "WARNING: You are about to delete:"
echo "$BLOB_NAME"

read -r -p "Are you sure? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then

    audit_log "DELETE" "$BLOB_NAME" "CANCELLED"

    echo "Deletion cancelled."

    exit 0

fi

if az storage blob delete \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$FILE_CONTAINER" \
    --name "$BLOB_NAME" \
    --auth-mode login \
    --only-show-errors
then

    audit_log "DELETE" "$BLOB_NAME" "SUCCESS"

    success_message "Document deleted."

else

    audit_log "DELETE" "$BLOB_NAME" "FAILED"

    error_message "Deletion failed."

    exit 1

fi