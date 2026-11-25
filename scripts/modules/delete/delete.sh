# Sourced by ledgerpoint.sh

delete_blob() {
    local blob_name="$1"
    local confirmation="$2"
    local exists

    validate_blob_name "$blob_name" || return 1

    if [[ "$confirmation" != "--confirm" ]]; then
        echo "ERROR: Deletion requires --confirm." >&2
        return 1
    fi

    exists=$(az storage blob exists \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name originals \
        --name "$blob_name" \
        --auth-mode login \
        --query exists \
        --output tsv)

    if [[ "$exists" != "true" ]]; then
        echo "ERROR: Document not found: $blob_name" >&2
        return 1
    fi

    echo "Deleting document from LedgerPoint..." >&2

    az storage blob delete \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name originals \
        --name "$blob_name" \
        --auth-mode login \
        --output none

    echo "SUCCESS: Document deleted."
    echo "Container: originals"
    echo "Blob name: $blob_name"
}
