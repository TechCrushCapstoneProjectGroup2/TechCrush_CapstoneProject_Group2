#!/usr/bin/env bash

# Step 5/8: create or verify the Log Analytics workspace.
# Sets WORKSPACE_ID for the diagnostics step.

step_log_analytics() {
    log "[5/8] Creating or verifying Log Analytics workspace..."

    az monitor log-analytics workspace create \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name "$WORKSPACE_NAME" \
        --location "$LOCATION" \
        --retention-time 30 \
        --output none

    WORKSPACE_ID=$(az monitor log-analytics workspace show \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name "$WORKSPACE_NAME" \
        --query id \
        --output tsv)

    log "Log Analytics workspace ready."
}
