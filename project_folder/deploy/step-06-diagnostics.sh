#!/usr/bin/env bash

# Step 6/8: send Blob storage logs and metrics to Log Analytics.

step_diagnostics() {
    log "[6/8] Enabling Blob Storage diagnostic logging..."

    BLOB_SERVICE_ID="${STORAGE_ID}/blobServices/default"

    az monitor diagnostic-settings create \
        --name "$DIAGNOSTIC_SETTING" \
        --resource "$BLOB_SERVICE_ID" \
        --workspace "$WORKSPACE_ID" \
        --logs '[
            {"category":"StorageRead","enabled":true},
            {"category":"StorageWrite","enabled":true},
            {"category":"StorageDelete","enabled":true}
        ]' \
        --metrics '[
            {"category":"Transaction","enabled":true}
        ]' \
        --output none

    log "Storage diagnostic settings configured."
}
