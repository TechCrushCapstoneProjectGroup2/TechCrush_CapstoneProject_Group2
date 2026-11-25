# Sourced by ledgerpoint.sh

download_blob() {
    local blob_name="$1"
    local destination

    validate_blob_name "$blob_name" || return 1

    destination="downloads/$blob_name"

    mkdir -p downloads

    if [[ -e "$destination" || -L "$destination" ]]; then
        echo "ERROR: Destination already exists: $destination" >&2
        return 1
    fi

    echo "Downloading document from LedgerPoint..." >&2

    az storage blob download \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name originals \
        --name "$blob_name" \
        --file "$destination" \
        --auth-mode login \
        --overwrite false \
        --output none

    echo "SUCCESS: Document downloaded."
    echo "Saved to: $destination"
}
