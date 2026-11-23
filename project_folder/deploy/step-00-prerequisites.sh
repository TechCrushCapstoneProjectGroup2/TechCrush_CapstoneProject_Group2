#!/usr/bin/env bash

# Pre-deployment checks and local audit log setup.
# Sets SUBSCRIPTION_ID and DEPLOYER_ID for later steps.

step_prerequisites() {
    log "Starting LedgerPoint deployment..."

    check_command az
    check_command date
    check_command mkdir
    check_command sleep

    validate_configuration

    az account show --output none ||
        fail "Not authenticated. Run 'az login' first."

    SUBSCRIPTION_ID=$(az account show --query id --output tsv)
    DEPLOYER_ID=$(az ad signed-in-user show --query id --output tsv)

    [[ -n "$SUBSCRIPTION_ID" ]] ||
        fail "Could not identify Azure subscription."

    [[ -n "$DEPLOYER_ID" ]] ||
        fail "Could not identify the signed-in Entra user."

    log "Azure authentication verified."
    log "Subscription: $SUBSCRIPTION_ID"
    log "Region: $LOCATION"

    init_audit_log
    log "Local audit log initialized: $LOG_FILE"
}
