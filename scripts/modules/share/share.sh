# Sourced by ledgerpoint.sh

share_blob() {
    local original="$1"
    local minutes="${2:-15}"
    local exists start_epoch start expiry share_name
    local tmpdir tmpfile sas_url
    local content_type content_disposition
    validate_blob_name "$original" || return 1
# Determine the preferred document presentation.
    case "${original,,}" in
        *.pdf)
            content_type="application/pdf"
            content_disposition="inline"
            ;;
        *.txt)
            content_type="text/plain"
            content_disposition="inline"
            ;;
        *)
            content_type="application/octet-stream"
            content_disposition="attachment"
            ;;
    esac

    if [[ ! "$minutes" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Duration must be a whole number." >&2
        return 1
    fi

    minutes=$((10#$minutes))

    if (( minutes < 1 || minutes > 60 )); then
        echo "ERROR: Duration must be 1-60 minutes." >&2
        return 1
    fi

    exists=$(az storage blob exists \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name originals \
        --name "$original" \
        --auth-mode login \
        --query exists \
        --output tsv)

    if [[ "$exists" != "true" ]]; then
        echo "ERROR: Original document not found." >&2
        return 1
    fi

# Unique auditor-specific copy.
    share_name="auditor-$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}-${original}"



    mkdir -p logs

    tmpdir=$(mktemp -d logs/.share-work.XXXXXXXX)
    tmpfile="$tmpdir/document"

    echo "Creating temporary auditor copy..." >&2

# Retrieve the original document.
    if ! az storage blob download \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name originals \
        --name "$original" \
        --file "$tmpfile" \
        --auth-mode login \
        --overwrite false \
        --output none; then

        rm -f -- "$tmpfile"
        rmdir -- "$tmpdir"
        echo "ERROR: Original download failed." >&2
        return 1
    fi

# Calculate the SAS validity interval in UTC.
    start_epoch=$(date -u +%s)

    start=$(date -u -d "@$start_epoch" \
        '+%Y-%m-%dT%H:%M:%SZ')

    expiry=$(date -u -d \
        "@$((start_epoch + minutes * 60))" \
        '+%Y-%m-%dT%H:%M:%SZ')

 # Create the temporary sharing copy.
    if ! az storage blob upload \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name temporary-shares \
        --name "$share_name" \
        --file "$tmpfile" \
        --content-type "$content_type" \
        --content-disposition "$content_disposition" \
        --content-cache-control "private, no-store" \
        --metadata \
            "ledgerpointmanaged=true" \
            "ledgerpointexpiry=$expiry" \
        --auth-mode login \
        --overwrite false \
        --output none; then

        rm -f -- "$tmpfile"
        rmdir -- "$tmpdir"
        echo "ERROR: Auditor copy upload failed." >&2
        return 1
    fi

# Remove the local temporary document after successful upload.
    rm -f -- "$tmpfile"
    rmdir -- "$tmpdir"

# Generate user delegation SAS.
    if ! sas_url=$(az storage blob generate-sas \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name temporary-shares \
        --name "$share_name" \
        --permissions r \
        --start "$start" \
        --expiry "$expiry" \
        --https-only \
        --auth-mode login \
        --as-user \
        --full-uri \
        --output tsv); then

        echo "ERROR: SAS generation failed." >&2

        az storage blob delete \
            --account-name "$STORAGE_ACCOUNT" \
            --container-name temporary-shares \
            --name "$share_name" \
            --auth-mode login \
            --output none || true

        return 1
    fi

    if [[ "$sas_url" != https://* ]]; then
        echo "ERROR: Invalid SAS URL returned." >&2
        return 1
    fi

# Save identifier, never the SAS token.
    printf '%s\n' "$share_name" > logs/current-share-blob.txt

# Audit the temporary sharing resource.
    audit_event SUCCESS "share-copy" "$share_name" "expiry=$expiry"

    echo "SUCCESS: Auditor link created." >&2
    echo "Expires: $expiry" >&2

# Secret URL goes to stdout for safe variable capture.
    printf '%s\n' "$sas_url"
}
