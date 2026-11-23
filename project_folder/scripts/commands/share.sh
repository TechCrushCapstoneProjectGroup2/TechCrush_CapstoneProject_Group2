#!/usr/bin/env bash

# Generate a time-limited, read-only user delegation SAS link.

cmd_share() {
    local blob_name="${1:-}"
    local hours="${2:-$DEFAULT_SHARE_HOURS}"

    [[ -n "$blob_name" ]] || fail "Usage: share <blob-name> [hours]"
    validate_blob_name "$blob_name"

    check_command awk
    check_command date

    [[ "$hours" =~ ^[0-9]+([.][0-9]+)?$ ]] || fail "Hours must be a positive number."
    awk "BEGIN {exit !($hours > 0)}" || fail "Hours must be greater than 0."
    awk "BEGIN {exit !($hours <= $MAX_SHARE_HOURS)}" ||
        fail "Hours must not exceed MAX_SHARE_HOURS ($MAX_SHARE_HOURS)."

    # Round up to whole minutes. Works with GNU date and BSD/macOS date.
    local minutes
    minutes="$(awk "BEGIN {printf \"%d\", ($hours * 60) + 0.999}")"
    (( minutes >= 1 )) || fail "Share lifetime must be at least one minute."

    local expiry
    if expiry="$(date -u -d "+${minutes} minutes" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)"; then
        :
    else
        expiry="$(date -u -v+"${minutes}"M '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || true)"
    fi
    [[ -n "$expiry" ]] || fail "Could not calculate SAS expiry time."

    # Confirm blob exists before generating a link.
    az storage blob show \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER_NAME" \
        --name "$blob_name" \
        --auth-mode login \
        --only-show-errors \
        --output none 2>/dev/null ||
        fail "Blob '$blob_name' not found in container '$CONTAINER_NAME'."

    log "Generating time-limited user delegation SAS for '$blob_name' (expires: $expiry UTC)..."

    local sas_url
    if sas_url=$(az storage blob generate-sas \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER_NAME" \
        --name "$blob_name" \
        --permissions r \
        --expiry "$expiry" \
        --https-only \
        --as-user \
        --auth-mode login \
        --full-uri \
        --only-show-errors \
        --output tsv); then
        [[ -n "$sas_url" ]] || fail "Azure CLI returned an empty SAS URL."
        audit_event "SHARE" "$CONTAINER_NAME/$blob_name" "SUCCESS" \
            "expiry=$expiry;permissions=r;type=user-delegation-sas"
        echo
        echo "Share link (expires $expiry UTC):"
        echo "$sas_url"
        echo
        echo "Security note: time-limited, HTTPS-only, read-only user delegation SAS."
        echo "Do not commit this URL. Revoke early with: scripts/ledgerpoint-cli.sh revoke-share"
    else
        audit_event "SHARE" "$CONTAINER_NAME/$blob_name" "FAILURE" \
            "expiry=$expiry;type=user-delegation-sas"
        fail "Failed to generate share link. Check Blob data and Storage Blob Delegator permissions."
    fi
}
