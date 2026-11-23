#!/usr/bin/env bash

# Download a blob to a local path.

cmd_download() {
    local blob_name="${1:-}"
    local local_path="${2:-}"

    [[ -n "$blob_name" && -n "$local_path" ]] || fail "Usage: download <blob-name> <local-path>"
    validate_blob_name "$blob_name"

    local local_dir
    local_dir="$(dirname "$local_path")"
    mkdir -p "$local_dir"

    log "Downloading '$CONTAINER_NAME/$blob_name' to '$local_path'..."
    if az storage blob download \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER_NAME" \
        --name "$blob_name" \
        --file "$local_path" \
        --auth-mode login \
        --only-show-errors \
        --output none; then
        audit_event "DOWNLOAD" "$CONTAINER_NAME/$blob_name" "SUCCESS" "destination=$local_path"
        log "Download complete."
    else
        audit_event "DOWNLOAD" "$CONTAINER_NAME/$blob_name" "FAILURE" "destination=$local_path"
        fail "Download failed for '$blob_name'."
    fi
}
