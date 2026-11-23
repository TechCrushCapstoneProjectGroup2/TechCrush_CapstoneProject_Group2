#!/usr/bin/env bash

# Step 7/8: verify the storage security settings.
# Sets the *_ACCESS/TLS values used by the summary step.

step_verify() {
    log "[7/8] Verifying storage security settings..."

    PUBLIC_ACCESS=$(az storage account show \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --query allowBlobPublicAccess \
        --output tsv)

    SHARED_KEY_ACCESS=$(az storage account show \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --query allowSharedKeyAccess \
        --output tsv)

    HTTPS_ONLY=$(az storage account show \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --query supportsHttpsTrafficOnly \
        --output tsv)

    TLS_VERSION=$(az storage account show \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --query minimumTlsVersion \
        --output tsv)

    CONTAINER_ACCESS=$(az storage container show \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --query properties.publicAccess \
        --output tsv)

    [[ "$PUBLIC_ACCESS" == "false" ]] ||
        fail "Public Blob access is not disabled."

    [[ "$SHARED_KEY_ACCESS" == "false" ]] ||
        fail "Shared Key authorization is still enabled."

    [[ "$HTTPS_ONLY" == "true" ]] ||
        fail "HTTPS-only enforcement is not enabled."

    [[ "$TLS_VERSION" == "TLS1_2" ]] ||
        fail "Minimum TLS version is not TLS 1.2."

    [[ -z "$CONTAINER_ACCESS" || "$CONTAINER_ACCESS" == "null" ]] ||
        fail "Container public access is enabled."

    log "All storage security checks passed."
}
