
#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

# LedgerPoint Secure File-Sharing CLI
# TECHCRUSH Group 2 Capstone Project

AUDIT_FILE="logs/ledgerpoint-audit.tsv"


# ==========================================
# 1. HELP MENU
# ==========================================

show_help() {
    cat <<'HELP'
LedgerPoint Secure File-Sharing CLI

Usage:
    ledgerpoint.sh help
    ledgerpoint.sh list <container>
    ledgerpoint.sh upload <local-file> [blob-name]
    ledgerpoint.sh download <blob-name>
    ledgerpoint.sh delete <blob-name> --confirm
    ledgerpoint.sh share <blob-name> [minutes]
    ledgerpoint.sh revoke <temporary-blob-name> --confirm

Containers:
    originals
    temporary-shares

Sharing:
    Read-only and HTTPS-only.
    Default duration: 30 minutes.
    Maximum duration: 60 minutes.

Required environment:
    STORAGE_ACCOUNT

Application audit log:
    logs/ledgerpoint-audit.tsv

Never record SAS URLs in audit logs.
HELP
}


# ==========================================
# 2. AUDIT LOGGING
# ==========================================

audit_event() {
    local result="$1"
    local operation="$2"
    local target="$3"
    local details="${4:-}"
    local actor

    # Identify the Azure CLI user when available.
    actor=$(az account show \
        --query user.name \
        --output tsv 2>/dev/null) \
        || actor="${USER:-unknown}"

    [[ -n "$actor" ]] || actor="unknown"

    # Prevent tabs and newlines from breaking log records.
    actor="${actor//$'\t'/ }"
    actor="${actor//$'\n'/ }"

    target="${target//$'\t'/ }"
    target="${target//$'\n'/ }"

    details="${details//$'\t'/ }"
    details="${details//$'\n'/ }"

    mkdir -p logs

    # Create column headings for a new audit file.
    if [[ ! -e "$AUDIT_FILE" ]]; then
        printf 'timestamp_utc\tactor\toperation\ttarget\tresult\tdetails\n' \
            > "$AUDIT_FILE"
    fi

    # Append an audit record.
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        "$actor" \
        "$operation" \
        "$target" \
        "$result" \
        "$details" >> "$AUDIT_FILE"
}


# ==========================================
# 3. VALIDATION
# ==========================================

require_storage_account() {
    if [[ -z "${STORAGE_ACCOUNT:-}" ]]; then
        echo "ERROR: STORAGE_ACCOUNT is not configured." >&2
        return 1
    fi
}

validate_blob_name() {
    local name="$1"

    if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
        echo "ERROR: Invalid blob name." >&2
        echo "Use letters, numbers, dots, underscores or hyphens." >&2
        return 1
    fi
}


# ==========================================
# 4. LIST BLOBS
# ==========================================

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


# ==========================================
# 5. UPLOAD DOCUMENT
# ==========================================

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


# ==========================================
# 6. DOWNLOAD DOCUMENT
# ==========================================

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


# ==========================================
# 7. DELETE ORIGINAL DOCUMENT
# ==========================================

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


# ==========================================
# 8. CREATE SECURE AUDITOR SHARE
# ==========================================

share_blob() {
    local original="$1"
    local minutes="${2:-30}"
    local exists expiry share_name
    local tmpdir tmpfile sas_url

    validate_blob_name "$original" || return 1

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

   expiry=$(date -u -d "+${minutes} minutes" \
    '+%Y-%m-%dT%H:%M:%SZ')

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

    # Create the temporary sharing copy.
    if ! az storage blob upload \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name temporary-shares \
    --name "$share_name" \
    --file "$tmpfile" \
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

    rm -f -- "$tmpfile"
    rmdir -- "$tmpdir"

    # Generate user delegation SAS.
    if ! sas_url=$(az storage blob generate-sas \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name temporary-shares \
        --name "$share_name" \
        --permissions r \
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


# ==========================================
# 9. REVOKE AUDITOR ACCESS
# ==========================================

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


# ==========================================
# 10. MAIN APPLICATION
# ==========================================

main() {
    local command="${1:-help}"

    case "$command" in

        help|--help|-h)
            show_help
            ;;

        list)
            if [[ "$#" -ne 2 ]]; then
                echo "ERROR: Usage: ledgerpoint.sh list <container>" >&2
                return 1
            fi

            require_storage_account
            list_blobs "$2"
            ;;

        upload)
            if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
                echo "ERROR: Usage: ledgerpoint.sh upload <local-file> [blob-name]" >&2
                return 1
            fi

            require_storage_account
            upload_blob "$2" "${3:-}"
            ;;

        download)
            if [[ "$#" -ne 2 ]]; then
                echo "ERROR: Usage: ledgerpoint.sh download <blob-name>" >&2
                return 1
            fi

            require_storage_account
            download_blob "$2"
            ;;

        delete)
            if [[ "$#" -ne 3 ]]; then
                echo "ERROR: Usage: ledgerpoint.sh delete <blob-name> --confirm" >&2
                return 1
            fi

            require_storage_account
            delete_blob "$2" "$3"
            ;;

        share)
            if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
                echo "ERROR: Usage: ledgerpoint.sh share <blob-name> [minutes]" >&2
                return 1
            fi

            require_storage_account
            share_blob "$2" "${3:-30}"
            ;;

        revoke)
            if [[ "$#" -ne 3 ]]; then
                echo "ERROR: Usage: ledgerpoint.sh revoke <temporary-blob-name> --confirm" >&2
                return 1
            fi

            require_storage_account
            revoke_blob "$2" "$3"
            ;;

        *)
            echo "ERROR: Unknown command: $command" >&2
            show_help >&2
            return 1
            ;;
    esac
}


# ==========================================
# 11. AUTOMATIC AUDIT RECORDING
# ==========================================

EVENT_ACTION="${1:-help}"
EVENT_TARGET="${2:--}"

should_audit=true

case "$EVENT_ACTION" in
    help|--help|-h)
        should_audit=false
        ;;
esac

# Record a failed command while preserving its exit status.
log_failure() {
    local status="$1"

    trap - ERR

    if [[ "$should_audit" == true ]]; then
        audit_event FAILED \
            "$EVENT_ACTION" \
            "$EVENT_TARGET" \
            "exit=$status" || true
    fi

    exit "$status"
}

# Record the beginning of an operation.
if [[ "$should_audit" == true ]]; then
    audit_event STARTED "$EVENT_ACTION" "$EVENT_TARGET" || {
        echo "ERROR: Unable to write application audit log." >&2
        exit 1
    }
fi

# Detect failures throughout our Bash application.
trap 'log_failure "$?"' ERR

main "$@"

# Record successful completion.
if [[ "$should_audit" == true ]]; then
    audit_event SUCCESS "$EVENT_ACTION" "$EVENT_TARGET"
fi
