# Sourced by ledgerpoint.sh

upload_blob() {
    local file_path="$1"
    local blob_name="${2:-$(basename -- "$1")}"

    if [[ ! -f "$file_path" ]]; then
        echo "ERROR: File does not exist: $file_path" >&2
        return 1
    fi

    if [[ ! -r "$file_path" ]]; then
        echo "ERROR: File is not readable: $file_path" >&2
        return 1
    fi

    validate_blob_name "$blob_name" || return 1

    echo "Uploading document to LedgerPoint..." >&2

    az storage blob upload \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name originals \
        --name "$blob_name" \
        --file "$file_path" \
        --auth-mode login \
        --overwrite false \
        --output none

    echo "SUCCESS: Document uploaded."
    echo "Container: originals"
    echo "Blob name: $blob_name"
}
