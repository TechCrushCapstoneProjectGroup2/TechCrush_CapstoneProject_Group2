
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
    Default duration: 15 minutes.
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

LEDGERPOINT_MODULE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/modules" || exit 1

source "$LEDGERPOINT_MODULE_ROOT/list/list.sh" || exit 1


# ==========================================
# 5. UPLOAD DOCUMENT
# ==========================================

source "$LEDGERPOINT_MODULE_ROOT/upload/upload.sh" || exit 1


# ==========================================
# 6. DOWNLOAD DOCUMENT
# ==========================================

source "$LEDGERPOINT_MODULE_ROOT/download/download.sh" || exit 1


# ==========================================
# 7. DELETE ORIGINAL DOCUMENT
# ==========================================

source "$LEDGERPOINT_MODULE_ROOT/delete/delete.sh" || exit 1


# ==========================================
# 8. CREATE SECURE AUDITOR SHARE
# ==========================================

source "$LEDGERPOINT_MODULE_ROOT/share/share.sh" || exit 1


# ==========================================
# 9. REVOKE AUDITOR ACCESS
# ==========================================

source "$LEDGERPOINT_MODULE_ROOT/revoke/revoke.sh" || exit 1


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
            share_blob "$2" "${3:-15}"
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
