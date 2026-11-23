#!/usr/bin/env bash

# Step 2/8: create or verify the secure StorageV2 account.
# Sets STORAGE_ID for the RBAC and diagnostics steps.

step_storage_account() {
    log "[2/8] Creating or verifying secure Storage Account..."

    az storage account create \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --allow-shared-key-access false \
        --tags project=LedgerPoint environment=capstone \
        --output none

    STORAGE_ID=$(az storage account show \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --query id \
        --output tsv)

    log "Storage Account ready: $STORAGE_ACCOUNT"
}
