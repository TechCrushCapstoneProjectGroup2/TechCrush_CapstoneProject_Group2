# Sourced by ledgerpoint.sh

list_blobs() {
    local container="$1"

    case "$container" in
        originals|temporary-shares)
            ;;
        *)
            echo "ERROR: Invalid container: $container" >&2
            return 1
            ;;
    esac

    az storage blob list \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$container" \
        --auth-mode login \
        --query "[].{Name:name,Size:properties.contentLength}" \
        --output json
}
