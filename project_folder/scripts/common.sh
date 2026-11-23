#!/usr/bin/env bash

# Shared configuration, validation, logging and audit helpers for the CLI.
# Sourced by dispatcher.sh - not meant to be run directly.

COMMON_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$COMMON_DIR/.." && pwd)"

# shellcheck source=../config.sh
source "$ROOT_DIR/config.sh"

LOG_DIR="$LEDGERPOINT_LOG_DIR"
LOG_FILE="$LEDGERPOINT_LOG_FILE"

usage() {
    cat <<'USAGE'
LedgerPoint CLI - Secure Cloud File Storage

Usage:
  scripts/ledgerpoint-cli.sh upload <local-file> [blob-name]
  scripts/ledgerpoint-cli.sh download <blob-name> <local-path>
  scripts/ledgerpoint-cli.sh list
  scripts/ledgerpoint-cli.sh delete <blob-name>
  scripts/ledgerpoint-cli.sh share <blob-name> [hours]
  scripts/ledgerpoint-cli.sh revoke-share
  scripts/ledgerpoint-cli.sh audit-log [lines]

Configuration:
  Set values in .env at the repository root, or export them before running.
  STORAGE_ACCOUNT is required and must be globally unique.

Environment variables:
  RESOURCE_GROUP         Azure resource group
  STORAGE_ACCOUNT        Azure storage account name (required)
  CONTAINER_NAME         Blob container name
  DEFAULT_SHARE_HOURS    Default SAS lifetime in hours (default: 24)
  MAX_SHARE_HOURS        Maximum allowed SAS lifetime (default: 72)
  LEDGERPOINT_LOG_DIR    Audit log directory (default: ~/.ledgerpoint)
  LEDGERPOINT_LOG_FILE   Audit log file path

Examples:
  scripts/ledgerpoint-cli.sh upload ./statement.pdf clientA/statement.pdf
  scripts/ledgerpoint-cli.sh share clientA/statement.pdf 2
  scripts/ledgerpoint-cli.sh revoke-share
USAGE
}

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*" >&2
}

fail() {
    log "ERROR: $*"
    exit 1
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' is not installed."
}

validate_common_config() {
    [[ -n "$STORAGE_ACCOUNT" ]] ||
        fail "STORAGE_ACCOUNT is required. Set it in .env or export it before running."

    [[ "$STORAGE_ACCOUNT" =~ ^[a-z0-9]{3,24}$ ]] ||
        fail "STORAGE_ACCOUNT must contain 3-24 lowercase letters/numbers."

    [[ "$RESOURCE_GROUP" =~ ^[a-zA-Z0-9._()-]+$ ]] ||
        fail "RESOURCE_GROUP has an invalid name."

    [[ "$CONTAINER_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] ||
        fail "CONTAINER_NAME is invalid."
}

init_audit_log() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    chmod 700 "$LOG_DIR"
    chmod 600 "$LOG_FILE"
}

current_user() {
    local upn=""
    local oid=""
    upn=$(az ad signed-in-user show --query userPrincipalName -o tsv 2>/dev/null || true)
    if [[ -n "$upn" && "$upn" != "null" ]]; then
        echo "$upn"
        return
    fi
    oid=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)
    if [[ -n "$oid" && "$oid" != "null" ]]; then
        echo "$oid"
        return
    fi
    echo "unknown-user"
}

audit_event() {
    local action="$1"
    local target="$2"
    local status="$3"
    local details="${4:-}"
    local actor
    local timestamp

    actor="$(current_user)"
    timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

    # Tab-separated: timestamp, actor, action, target, status, details.
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$timestamp" "$actor" "$action" "$target" "$status" "$details" >> "$LOG_FILE"
}

require_login() {
    az account show --output none 2>/dev/null ||
        fail "Not authenticated. Run 'az login' first."
}

require_storage_exists() {
    az storage account show \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --output none 2>/dev/null ||
        fail "Storage account '$STORAGE_ACCOUNT' not found in '$RESOURCE_GROUP'. Run deploy/deploy.sh first."
}

validate_blob_name() {
    local blob_name="$1"
    [[ -n "$blob_name" ]] || fail "Blob name cannot be empty."
    [[ "$blob_name" != /* ]] || fail "Blob name must not start with '/'."
    [[ "$blob_name" != *..* ]] || fail "Blob name must not contain '..'."
    [[ ${#blob_name} -le 1024 ]] || fail "Blob name is too long."
}

require_environment() {
    check_command az
    check_command date
    validate_common_config
    init_audit_log
    require_login
    require_storage_exists
}
