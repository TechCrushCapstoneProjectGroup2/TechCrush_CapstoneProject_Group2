#!/bin/bash

# ==========================================
# LEDGERPOINT COMMON FUNCTIONS
# ==========================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CONFIG_FILE="$PROJECT_ROOT/config/config.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found."
    exit 1
fi

source "$CONFIG_FILE"

LOG_FILE="$PROJECT_ROOT/logs/audit.log"

mkdir -p "$PROJECT_ROOT/logs"

# Get authenticated Azure user

get_user() {

    az account show \
        --query user.name \
        --output tsv 2>/dev/null || echo "UNKNOWN"

}

# Record audit event

audit_log() {

    local ACTION="$1"
    local FILE="$2"
    local STATUS="$3"

    local USER
    USER=$(get_user)

    local TIMESTAMP
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "$TIMESTAMP | USER=$USER | ACTION=$ACTION | FILE=$FILE | STATUS=$STATUS" \
        >> "$LOG_FILE"

    # Synchronise audit log with private Azure container

    if [[ -n "${STORAGE_ACCOUNT:-}" ]]; then

        az storage blob upload \
            --account-name "$STORAGE_ACCOUNT" \
            --container-name "$AUDIT_CONTAINER" \
            --name "application-audit.log" \
            --file "$LOG_FILE" \
            --auth-mode login \
            --overwrite true \
            --only-show-errors \
            >/dev/null 2>&1 || {

                echo "WARNING: Audit log cloud synchronisation failed." >&2

            }

    fi

}

# Verify Azure authentication

check_azure_login() {

    if ! az account show >/dev/null 2>&1; then

        echo "ERROR: Please log in to Azure first."

        exit 1

    fi

}

# Validate required configuration

check_storage() {

    if [[ -z "${STORAGE_ACCOUNT:-}" ]]; then

        echo "ERROR: Storage account is not configured."

        exit 1

    fi

}

# Display operation result

success_message() {

    echo "[SUCCESS] $1"

}

error_message() {

    echo "[ERROR] $1" >&2

}
