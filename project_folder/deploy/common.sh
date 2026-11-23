#!/usr/bin/env bash

# Shared configuration and helpers for deployment steps.
# Sourced by orchestrator.sh and teardown.sh - not meant to be run directly.

COMMON_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$COMMON_DIR/.." && pwd)"

# shellcheck source=../config.sh
source "$ROOT_DIR/config.sh"

DIAGNOSTIC_SETTING="ledgerpoint-blob-diagnostics"

LOG_DIR="$LEDGERPOINT_LOG_DIR"
LOG_FILE="$LEDGERPOINT_LOG_FILE"

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"
}

fail() {
    log "ERROR: $*"
    exit 1
}

handle_error() {
    local exit_code=$?
    log "Deployment failed near line ${BASH_LINENO[0]} (exit code ${exit_code})."
    exit "$exit_code"
}

check_command() {
    command -v "$1" >/dev/null 2>&1 ||
        fail "Required command '$1' is not installed."
}

validate_configuration() {
    [[ -n "$STORAGE_ACCOUNT" ]] ||
        fail "STORAGE_ACCOUNT is required. Set it in .env or export it before running."

    [[ "$STORAGE_ACCOUNT" =~ ^[a-z0-9]{3,24}$ ]] ||
        fail "STORAGE_ACCOUNT must contain 3-24 lowercase letters/numbers."

    [[ "$RESOURCE_GROUP" =~ ^[a-zA-Z0-9._()-]+$ ]] ||
        fail "RESOURCE_GROUP has an invalid name."

    [[ "$CONTAINER_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] ||
        fail "CONTAINER_NAME is invalid."

    [[ "$WORKSPACE_NAME" =~ ^[a-zA-Z0-9-]{4,63}$ ]] ||
        fail "WORKSPACE_NAME is invalid."
}

init_audit_log() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    chmod 700 "$LOG_DIR"
    chmod 600 "$LOG_FILE"
}
