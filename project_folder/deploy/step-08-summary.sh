#!/usr/bin/env bash

# Step 8/8: print and append the deployment summary.

step_summary() {
    log "[8/8] Generating deployment summary..."

    {
        echo "=========================================="
        echo "LEDGERPOINT INFRASTRUCTURE DEPLOYMENT"
        echo "=========================================="
        echo "Deployment time: $(date -u)"
        echo "Subscription: $SUBSCRIPTION_ID"
        echo "Resource Group: $RESOURCE_GROUP"
        echo "Location: $LOCATION"
        echo "Storage Account: $STORAGE_ACCOUNT"
        echo "Container: $CONTAINER_NAME"
        echo "Log Analytics Workspace: $WORKSPACE_NAME"
        echo "Public Blob Access: $PUBLIC_ACCESS"
        echo "Shared Key Access: $SHARED_KEY_ACCESS"
        echo "HTTPS Only: $HTTPS_ONLY"
        echo "Minimum TLS: $TLS_VERSION"
        echo "Container Public Access: ${CONTAINER_ACCESS:-private}"
        echo "Deployment Status: SUCCESS"
        echo "=========================================="
    } | tee -a "$LOG_FILE"

    log "LEDGERPOINT INFRASTRUCTURE DEPLOYMENT COMPLETED SUCCESSFULLY."
    log "Audit log: $LOG_FILE"
}
