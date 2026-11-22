#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

check_azure_login
check_storage

if [[ $# -ne 1 ]]; then

    echo "Usage: ./scripts/upload.sh <file-path>"

    exit 1

fi

FILE_PATH="$1"

if [[ ! -f "$FILE_PATH" ]]; then

    error_message "File does not exist."

    audit_log "UPLOAD" "$FILE_PATH" "FAILED"

    exit 1

fi

FILE_NAME=$(basename "$FILE_PATH")

echo "Uploading: $FILE_NAME"

if az storage blob upload \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$FILE_CONTAINER" \
    --name "$FILE_NAME" \
    --file "$FILE_PATH" \
    --auth-mode login \
    --overwrite false \
    --only-show-errors
then

    audit_log "UPLOAD" "$FILE_NAME" "SUCCESS"

    success_message "File uploaded successfully."

else

    audit_log "UPLOAD" "$FILE_NAME" "FAILED"

    error_message "Upload failed."

    exit 1

fi
