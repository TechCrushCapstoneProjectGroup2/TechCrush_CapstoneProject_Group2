#!/usr/bin/env bash

# Delete a blob from the private container.

cmd_delete() {
    local blob_name="${1:-}"
    [[ -n "$blob_name" ]] || fail "Usage: delete <blob-name>"
    validate_blob_name "$blob_name"

    log "Deleting '$CONTAINER_NAME/$blob_name'..."
    if az storage blob delete \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER_NAME" \
        --name "$blob_name" \
        --auth-mode login \
        --only-show-errors \
        --output none; then
        audit_event "DELETE" "$CONTAINER_NAME/$blob_name" "SUCCESS" "blob deleted"
        log "Delete complete."
    else
        audit_event "DELETE" "$CONTAINER_NAME/$blob_name" "FAILURE" "blob delete failed"
        fail "Delete failed for '$blob_name'."
    fi
}
