# Sourced by ledgerpoint.sh

revoke_blob() {
    local share_name="$1"
    local confirmation="$2"
    local exists

    validate_blob_name "$share_name" || return 1

    if [[ "$share_name" != auditor-* ]]; then
        echo "ERROR: Only auditor temporary copies may be revoked." >&2
        return 1
    fi

    if [[ "$confirmation" != "--confirm" ]]; then
        echo "ERROR: Revocation requires --confirm." >&2
        return 1
    fi

    exists=$(az storage blob exists \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name temporary-shares \
        --name "$share_name" \
        --auth-mode login \
        --query exists \
        --output tsv)

    if [[ "$exists" != "true" ]]; then
        echo "ERROR: Auditor copy not found: $share_name" >&2
        return 1
    fi

    echo "Revoking auditor access..." >&2

    az storage blob delete \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name temporary-shares \
        --name "$share_name" \
        --auth-mode login \
        --output none

    if [[ -f logs/current-share-blob.txt ]] &&
       [[ "$(cat logs/current-share-blob.txt)" == "$share_name" ]]; then

        rm -f -- logs/current-share-blob.txt
    fi

    echo "SUCCESS: Temporary auditor copy deleted."
    echo "Original document was not deleted."
}
