#!/bin/bash
# @Author: Your name
# @Date:   2026-11-22 22:10:16
# @Last Modified by:   Your name
# @Last Modified time: 2026-11-22 22:43:55

#!/bin/bash

set -euo pipefail

# ==========================================
# LEDGERPOINT SECURE FILE SHARING
# AZURE USER DELEGATION SAS
# ==========================================

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

check_azure_login
check_storage

# Validate arguments
if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: ./scripts/share.sh <blob-name> [expiry-minutes]"
    exit 1
fi

BLOB_NAME="$1"
EXPIRY_MINUTES="${2:-$DEFAULT_SAS_EXPIRY_MINUTES}"

# Validate expiry
if ! [[ "$EXPIRY_MINUTES" =~ ^[0-9]+$ ]]; then
    error_message "Expiry must be a number."
    exit 1
fi

if (( EXPIRY_MINUTES < 1 || EXPIRY_MINUTES > MAX_SAS_EXPIRY_MINUTES )); then
    error_message "Expiry must be between 1 and $MAX_SAS_EXPIRY_MINUTES minutes."
    exit 1
fi

echo "=========================================="
echo " LEDGERPOINT SECURE FILE SHARING"
echo "=========================================="

echo "File: $BLOB_NAME"
echo "Expiry: $EXPIRY_MINUTES minutes"

# Verify that the blob exists
if ! az storage blob exists \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$FILE_CONTAINER" \
    --name "$BLOB_NAME" \
    --auth-mode login \
    --query exists \
    --output tsv | grep -qx true; then

    audit_log "SHARE" "$BLOB_NAME" "FAILED_NOT_FOUND"
    error_message "The requested document does not exist."
    exit 1
fi

# Generate UTC timestamps
START_TIME=$(date -u -d "5 minutes ago" '+%Y-%m-%dT%H:%MZ')
EXPIRY_TIME=$(date -u -d "+${EXPIRY_MINUTES} minutes" '+%Y-%m-%dT%H:%MZ')

echo "Generating User Delegation SAS..."

# Generate read-only SAS URL
if SAS_URL=$(az storage blob generate-sas \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$FILE_CONTAINER" \
    --name "$BLOB_NAME" \
    --permissions r \
    --start "$START_TIME" \
    --expiry "$EXPIRY_TIME" \
    --auth-mode login \
    --as-user \
    --https-only \
    --full-uri \
    --output tsv 2>/dev/null); then

    if [[ -z "$SAS_URL" || "$SAS_URL" != https://* ]]; then
        audit_log "SHARE" "$BLOB_NAME" "FAILED_INVALID_URL"
        error_message "Azure did not return a valid HTTPS URL."
        exit 1
    fi

    audit_log "SHARE" "$BLOB_NAME" "SUCCESS_EXPIRY_${EXPIRY_MINUTES}_MIN"

    echo ""
    echo "=========================================="
    echo " SECURE SHARE LINK GENERATED"
    echo "=========================================="

    echo ""
    echo "Document: $BLOB_NAME"
    echo "Expires: $EXPIRY_TIME UTC"
    echo "Permission: READ ONLY"
    echo "Protocol: HTTPS"
    echo ""
    echo "AUDITOR LINK:"
    echo ""
    printf '%s\n' "$SAS_URL"
    echo ""
    echo "=========================================="
    echo "IMPORTANT:"
    echo "Treat this URL like a password."
    echo "Do not publish or commit it."
    echo "=========================================="

else

    audit_log "SHARE" "$BLOB_NAME" "FAILED_SAS_GENERATION"
    error_message "Could not generate the sharing link."
    exit 1

fi
