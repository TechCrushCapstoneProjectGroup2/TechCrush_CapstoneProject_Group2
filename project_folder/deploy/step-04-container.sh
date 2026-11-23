#!/usr/bin/env bash

# Create the private Blob container.
# Retries briefly because RBAC assignments from step 3 may not have propagated yet.

step_container() {
    log "[4/8] Creating private Blob container..."

    local attempt=1
    local max_attempts=10
    local created=0

    while [[ "$attempt" -le "$max_attempts" ]]; do
        if az storage container create \
            --name "$CONTAINER_NAME" \
            --account-name "$STORAGE_ACCOUNT" \
            --public-access off \
            --auth-mode login \
            --output none 2>/dev/null; then
            created=1
            break
        fi

        log "Container creation failed (attempt $attempt/$max_attempts). Waiting for RBAC propagation..."
        sleep 10
        attempt=$((attempt + 1))
    done

    [[ "$created" == "1" ]] ||
        fail "Could not create container after $max_attempts attempts. Check RBAC permissions and propagation."

    log "Private Blob container ready: $CONTAINER_NAME"
}
