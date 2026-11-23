#!/usr/bin/env bash

# Remove the resource group created by deploy.sh.
# Safe to run twice: a missing resource group is not an error.

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

main() {
    check_command az
    [[ -n "$RESOURCE_GROUP" ]] ||
        fail "RESOURCE_GROUP is required."

    az account show --output none ||
        fail "Not authenticated. Run 'az login' first."

    if az group show --name "$RESOURCE_GROUP" --output none 2>/dev/null; then
        log "Deleting resource group '$RESOURCE_GROUP'..."
        az group delete \
            --name "$RESOURCE_GROUP" \
            --yes \
            --no-wait \
            --output none
        log "Deletion started. Verify with: az group show --name '$RESOURCE_GROUP'"
    else
        log "Resource group '$RESOURCE_GROUP' does not exist. Nothing to do."
    fi
}

main "$@"
