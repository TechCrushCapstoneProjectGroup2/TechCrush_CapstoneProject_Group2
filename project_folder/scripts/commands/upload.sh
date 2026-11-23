#!/usr/bin/env bash

# Upload a local file to private Blob storage.

cmd_upload() {
    local local_file="${1:-}"
    local blob_name="${2:-}"

    [[ -n "$local_file" ]] || fail "Usage: upload <local-file> [blob-name]"
    [[ -f "$local_file" ]] || fail "Local file not found: $local_file"

    if [[ -z "$blob_name" ]]; then
        blob_name="$(basename "$local_file")"
    fi
    validate_blob_name "$blob_name"

    log "Uploading '$local_file' to '$CONTAINER_NAME/$blob_name'..."
    if az storage blob upload \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER_NAME" \
        --name "$blob_name" \
        --file "$local_file" \
        --auth-mode login \
        --overwrite true \
        --only-show-errors \
        --output none; then
        audit_event "UPLOAD" "$CONTAINER_NAME/$blob_name" "SUCCESS" "source=$local_file"
        log "Upload complete."
    else
        audit_event "UPLOAD" "$CONTAINER_NAME/$blob_name" "FAILURE" "source=$local_file"
        fail "Upload failed for '$local_file'."
    fi
}
