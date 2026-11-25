
#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

# ==========================================
# LEDGERPOINT EXPIRED-SHARE CLEANUP
# TECHCRUSH GROUP 2 CAPSTONE
# ==========================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Dry-run by default: no deletion.
MODE="${1:---dry-run}"

if [[ -z "${STORAGE_ACCOUNT:-}" ]]; then
    echo "ERROR: STORAGE_ACCOUNT is missing." >&2
    exit 1
fi

case "$MODE" in
    --dry-run)
        if (( $# > 1 )); then
            echo "Usage: cleanup.sh [--dry-run]" >&2
            exit 1
        fi
        ;;
    --apply)
        if [[ "${2:-}" != "--confirm" || $# -ne 2 ]]; then
            echo "ERROR: Use --apply --confirm to delete expired copies." >&2
            exit 1
        fi
        ;;
    *)
        echo "Usage: cleanup.sh [--dry-run | --apply --confirm]" >&2
        exit 1
        ;;
esac

echo "LedgerPoint expired-share cleanup"
echo "Mode: $MODE"
echo "Container: temporary-shares"

# List temporary blobs and their metadata.
# Keep only the fields required for cleanup.
if ! ROWS="$(az storage blob list \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name temporary-shares \
    --auth-mode login \
    --prefix auditor- \
    --include m \
    --query "[].[name,metadata.ledgerpointmanaged,metadata.ledgerpointexpiry]" \
    --output tsv)"; then

    echo "ERROR: Unable to list temporary shares." >&2
    exit 1
fi

if [[ -z "$ROWS" ]]; then
    echo "No auditor copies found."
    exit 0
fi

NOW="$(date -u +%s)"

EXPIRED=0
REMOVED=0
SKIPPED=0

while IFS=$'\t' read -r BLOB MANAGED EXPIRY
do
    [[ -n "$BLOB" ]] || continue

    # Protect files outside our expected naming scheme.
    if [[ ! "$BLOB" =~ ^auditor-[A-Za-z0-9._-]+$ ]]; then
        echo "SKIP: Unexpected blob name."
        (( SKIPPED += 1 ))
        continue
    fi

    # Never delete a blob unless LedgerPoint explicitly
    # marked it as managed and recorded its expiry.
    if [[ "$MANAGED" != "true" || -z "$EXPIRY" ]]; then
        echo "SKIP: Missing LedgerPoint cleanup metadata: $BLOB"
        (( SKIPPED += 1 ))
        continue
    fi

    if ! EXPIRY_SECONDS="$(date -u -d "$EXPIRY" +%s 2>/dev/null)"; then
        echo "SKIP: Invalid expiry metadata: $BLOB"
        (( SKIPPED += 1 ))
        continue
    fi

    if (( NOW < EXPIRY_SECONDS )); then
        echo "KEEP: Active share: $BLOB"
        (( SKIPPED += 1 ))
        continue
    fi

    (( EXPIRED += 1 ))

    if [[ "$MODE" == "--dry-run" ]]; then
        echo "WOULD DELETE: $BLOB"
        continue
    fi

    # Recheck metadata immediately before deletion.
    CURRENT_MANAGED="$(az storage blob show \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name temporary-shares \
        --name "$BLOB" \
        --auth-mode login \
        --query metadata.ledgerpointmanaged \
        --output tsv)"

    CURRENT_EXPIRY="$(az storage blob show \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name temporary-shares \
        --name "$BLOB" \
        --auth-mode login \
        --query metadata.ledgerpointexpiry \
        --output tsv)"

    if [[ "$CURRENT_MANAGED" != "true" ||
          "$CURRENT_EXPIRY" != "$EXPIRY" ]]; then
        echo "SKIP: Metadata changed: $BLOB"
        (( SKIPPED += 1 ))
        continue
    fi

    echo "DELETE: Expired temporary copy: $BLOB"

    az storage blob delete \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name temporary-shares \
        --name "$BLOB" \
        --auth-mode login \
        --output none

    # Remove the latest-share pointer if applicable.
    if [[ -f logs/current-share-blob.txt ]] &&
       [[ "$(cat logs/current-share-blob.txt)" == "$BLOB" ]]; then
        rm -f -- logs/current-share-blob.txt
    fi

    (( REMOVED += 1 ))

    # Add a record to our application audit file.
    ACTOR="$(az account show --query user.name -o tsv)"

    printf '%s\t%s\tcleanup\t%s\tSUCCESS\texpired-share-removed\n' \
        "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        "$ACTOR" \
        "$BLOB" >> logs/ledgerpoint-audit.tsv

done <<< "$ROWS"

echo "========================================"
echo "Expired candidates: $EXPIRED"
echo "Removed: $REMOVED"
echo "Skipped or active: $SKIPPED"
echo "Cleanup completed."
echo "========================================"
