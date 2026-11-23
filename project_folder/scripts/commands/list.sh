#!/usr/bin/env bash

# List blobs in the private container.

cmd_list() {
    log "Listing blobs in '$CONTAINER_NAME'..."
    if az storage blob list \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER_NAME" \
        --auth-mode login \
        --query "[].{name:name, size:properties.contentLength, lastModified:properties.lastModified}" \
        --output table; then
        audit_event "LIST" "$CONTAINER_NAME" "SUCCESS" "listed blobs"
    else
        audit_event "LIST" "$CONTAINER_NAME" "FAILURE" "list failed"
        fail "List failed for container '$CONTAINER_NAME'."
    fi
}
