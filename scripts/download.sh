#!/bin/bash
# @Author: Your name
# @Date:   2026-11-22 22:10:16
# @Last Modified by:   Your name
# @Last Modified time: 2026-11-22 22:31:28
#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

check_azure_login
check_storage

if [[ $# -lt 1 || $# -gt 2 ]]; then

    echo "Usage: ./scripts/download.sh <blob-name> [destination]"

    exit 1

fi

BLOB_NAME="$1"

DESTINATION="${2:-downloads}"

mkdir -p "$DESTINATION"

OUTPUT_FILE="$DESTINATION/$(basename "$BLOB_NAME")"

echo "Downloading: $BLOB_NAME"

if az storage blob download \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$FILE_CONTAINER" \
    --name "$BLOB_NAME" \
    --file "$OUTPUT_FILE" \
    --auth-mode login \
    --overwrite true \
    --only-show-errors
then

    audit_log "DOWNLOAD" "$BLOB_NAME" "SUCCESS"

    success_message "File downloaded to $OUTPUT_FILE"

else

    audit_log "DOWNLOAD" "$BLOB_NAME" "FAILED"

    error_message "Download failed."

    exit 1

fi