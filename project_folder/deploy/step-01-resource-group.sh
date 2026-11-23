#!/usr/bin/env bash

# Step 1/8: create or verify the resource group.

step_resource_group() {
    log "[1/8] Creating or verifying Resource Group..."

    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --tags project=LedgerPoint environment=capstone \
        --output none

    RESOURCE_GROUP_ID=$(az group show \
        --name "$RESOURCE_GROUP" \
        --query id \
        --output tsv)

    log "Resource Group ready: $RESOURCE_GROUP"
}
