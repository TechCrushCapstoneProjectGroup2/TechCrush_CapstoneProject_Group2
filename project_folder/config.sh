#!/usr/bin/env bash

# Central configuration loader.
# Sourced by deploy/ and scripts/ entry points. Never commit real values.

CONFIG_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load local overrides if they exist.
for env_file in "$CONFIG_DIR/.env" "$CONFIG_DIR/.env.local"; do
    if [[ -f "$env_file" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
    fi
done

# Canonical names. AZURE_* aliases are supported for CI variables.
RESOURCE_GROUP="${RESOURCE_GROUP:-${AZURE_RESOURCE_GROUP:-rg-ledgerpoint-capstone}}"
LOCATION="${LOCATION:-${AZURE_LOCATION:-uksouth}}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-${AZURE_STORAGE_ACCOUNT:-}}"
CONTAINER_NAME="${CONTAINER_NAME:-${AZURE_STORAGE_CONTAINER:-financial-statements}}"
WORKSPACE_NAME="${WORKSPACE_NAME:-lawledgerpointcapstone}"
DEFAULT_SHARE_HOURS="${DEFAULT_SHARE_HOURS:-${DEFAULT_LINK_TTL_HOURS:-24}}"
MAX_SHARE_HOURS="${MAX_SHARE_HOURS:-${MAX_LINK_TTL_HOURS:-72}}"
TEAM_BLOB_CONTRIBUTOR_IDS="${TEAM_BLOB_CONTRIBUTOR_IDS:-}"
SAS_ISSUER_PRINCIPAL_IDS="${SAS_ISSUER_PRINCIPAL_IDS:-}"
GRANT_DEPLOYER_SAS_DELEGATOR="${GRANT_DEPLOYER_SAS_DELEGATOR:-true}"

# One shared audit log for deployment and CLI actions.
LEDGERPOINT_LOG_DIR="${LEDGERPOINT_LOG_DIR:-${HOME}/.ledgerpoint}"
LEDGERPOINT_LOG_FILE="${LEDGERPOINT_LOG_FILE:-${AUDIT_LOG_DESTINATION:-${LEDGERPOINT_LOG_DIR}/audit.log}}"

export RESOURCE_GROUP LOCATION STORAGE_ACCOUNT CONTAINER_NAME WORKSPACE_NAME
export DEFAULT_SHARE_HOURS MAX_SHARE_HOURS
export TEAM_BLOB_CONTRIBUTOR_IDS SAS_ISSUER_PRINCIPAL_IDS
export GRANT_DEPLOYER_SAS_DELEGATOR
export LEDGERPOINT_LOG_DIR LEDGERPOINT_LOG_FILE
