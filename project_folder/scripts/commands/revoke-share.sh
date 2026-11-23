#!/usr/bin/env bash

# Revoke all user delegation keys (invalidates every user delegation SAS).

cmd_revoke_share() {
    log "Revoking all user delegation keys for storage account '$STORAGE_ACCOUNT'..."
    log "WARNING: This invalidates ALL active user delegation SAS tokens for this storage account."

    if az storage account revoke-delegation-keys \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --only-show-errors \
        --output none; then
        audit_event "REVOKE_SHARE" "$STORAGE_ACCOUNT" "SUCCESS" "revoked all user delegation keys"
        log "User delegation keys revoked. Previously issued user delegation SAS links are now invalid."
    else
        audit_event "REVOKE_SHARE" "$STORAGE_ACCOUNT" "FAILURE" "failed to revoke user delegation keys"
        fail "Failed to revoke user delegation keys."
    fi
}
