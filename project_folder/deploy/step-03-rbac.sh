#!/usr/bin/env bash

# Step 3/8: assign least-privilege Blob data roles at the storage account scope.

# Assign a role only if the same principal already lacks
# that role at the specified storage-account scope.
ensure_role_assignment() {
    local principal_id="$1"
    local role_name="$2"

    [[ "$principal_id" =~ ^[a-fA-F0-9-]{36}$ ]] ||
        fail "Invalid Entra object ID supplied for RBAC."

    local existing
    existing=$(az role assignment list \
        --scope "$STORAGE_ID" \
        --all \
        --query "[?principalId=='${principal_id}' && roleDefinitionName=='${role_name}' && scope=='${STORAGE_ID}'] | length(@)" \
        --output tsv)

    if [[ "$existing" == "0" ]]; then
        log "Assigning '$role_name' to principal '$principal_id'..."

        az role assignment create \
            --assignee-object-id "$principal_id" \
            --role "$role_name" \
            --scope "$STORAGE_ID" \
            --output none
    else
        log "Role '$role_name' already exists for principal '$principal_id'."
    fi
}

step_rbac() {
    log "[3/8] Configuring Azure RBAC..."

    # The deployment identity needs Blob data permissions to create
    # and manage the private container using Entra authentication.
    ensure_role_assignment \
        "$DEPLOYER_ID" \
        "Storage Blob Data Contributor"

    # Give approved team members Blob data access.
    if [[ -n "$TEAM_BLOB_CONTRIBUTOR_IDS" ]]; then
        IFS=',' read -ra TEAM_IDS <<< "$TEAM_BLOB_CONTRIBUTOR_IDS"

        for principal_id in "${TEAM_IDS[@]}"; do
            principal_id="${principal_id//[[:space:]]/}"

            [[ -z "$principal_id" ]] && continue

            ensure_role_assignment \
                "$principal_id" \
                "Storage Blob Data Contributor"
        done
    fi

    # User delegation SAS issuers need permission to obtain
    # a user delegation key.
    if [[ "$GRANT_DEPLOYER_SAS_DELEGATOR" == "true" ]]; then
        ensure_role_assignment \
            "$DEPLOYER_ID" \
            "Storage Blob Delegator"
    fi

    if [[ -n "$SAS_ISSUER_PRINCIPAL_IDS" ]]; then
        IFS=',' read -ra SAS_IDS <<< "$SAS_ISSUER_PRINCIPAL_IDS"

        for principal_id in "${SAS_IDS[@]}"; do
            principal_id="${principal_id//[[:space:]]/}"

            [[ -z "$principal_id" ]] && continue

            ensure_role_assignment \
                "$principal_id" \
                "Storage Blob Delegator"
        done
    fi

    log "RBAC assignments configured."
}
