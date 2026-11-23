#!/usr/bin/env bash

# End-to-end verification against real Azure resources.
# Produces redacted evidence in evidence/logs/tests/.

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$ROOT_DIR/config.sh"
CLI="$ROOT_DIR/scripts/ledgerpoint-cli.sh"
REDACT="$ROOT_DIR/tests/evidence-scripts/redact.sh"

# shellcheck source=../../config.sh
source "$CONFIG"

EVIDENCE_DIR="${EVIDENCE_DIR:-$ROOT_DIR/evidence/logs/tests}"
SHARE_HOURS="${SHARE_HOURS:-1}"
VERIFY_ANONYMOUS="${VERIFY_ANONYMOUS:-true}"
CLEANUP_BLOB="${CLEANUP_BLOB:-true}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"
}

fail() {
    log "ERROR: $*"
    exit 1
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' is not installed."
}

sanitize() {
    local src="$1"
    local dst="$2"
    mkdir -p "$EVIDENCE_DIR"
    bash "$REDACT" "$src" > "$dst"
}

expect_status() {
    local actual="$1"
    local expected="$2"
    local label="$3"
    if [[ "$actual" != "$expected" ]]; then
        fail "$label: expected HTTP $expected, got ${actual:-<none>}"
    fi
    log "$label: HTTP $actual OK"
}

main() {
    check_command az
    check_command curl
    check_command cmp

    [[ -n "$STORAGE_ACCOUNT" ]] ||
        fail "STORAGE_ACCOUNT is required. Set it in .env before running."

    az account show --output none || fail "Run 'az login' first."

    mkdir -p "$EVIDENCE_DIR"

    log "Checking private storage settings..."
    local public_access shared_key https_only tls container_access
    public_access=$(az storage account show --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" --query allowBlobPublicAccess -o tsv)
    shared_key=$(az storage account show --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" --query allowSharedKeyAccess -o tsv)
    https_only=$(az storage account show --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" --query supportsHttpsTrafficOnly -o tsv)
    tls=$(az storage account show --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" --query minimumTlsVersion -o tsv)
    container_access=$(az storage container show --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT" --auth-mode login \
        --query properties.publicAccess -o tsv)

    [[ "$public_access" == "false" ]] || fail "Public blob access is enabled."
    [[ "$shared_key" == "false" ]] || fail "Shared key access is enabled."
    [[ "$https_only" == "true" ]] || fail "HTTPS-only is not enforced."
    [[ "$tls" == "TLS1_2" ]] || fail "Minimum TLS is not 1.2."
    [[ -z "$container_access" || "$container_access" == "null" ]] ||
        fail "Container public access is enabled."

    if [[ "$VERIFY_ANONYMOUS" == "true" ]]; then
        log "Verifying anonymous listing is denied..."
        local anon_status
        anon_status=$(curl -sS -o "$TMP_DIR/anonymous.out" -w "%{http_code}" \
            "https://${STORAGE_ACCOUNT}.blob.core.windows.net/${CONTAINER_NAME}?restype=container&comp=list" || true)
        expect_status "$anon_status" "403" "anonymous list"
        sanitize "$TMP_DIR/anonymous.out" "$EVIDENCE_DIR/anonymous-list-denied.txt"
    fi

    local blob_name="test/statement-$(date -u +%s)-$$.txt"
    if [[ -n "${TEST_SOURCE_FILE:-}" && -f "$TEST_SOURCE_FILE" ]]; then
        cp "$TEST_SOURCE_FILE" "$TMP_DIR/statement.txt"
    else
        printf 'LedgerPoint integration test\n' > "$TMP_DIR/statement.txt"
    fi

    log "Uploading test blob '$blob_name'..."
    bash "$CLI" upload "$TMP_DIR/statement.txt" "$blob_name" > "$TMP_DIR/upload.out" 2>&1
    cat "$TMP_DIR/upload.out"
    sanitize "$TMP_DIR/upload.out" "$EVIDENCE_DIR/upload.txt"

    log "Listing blobs..."
    bash "$CLI" list > "$TMP_DIR/list.out" 2>&1
    cat "$TMP_DIR/list.out"
    sanitize "$TMP_DIR/list.out" "$EVIDENCE_DIR/list.txt"

    log "Generating share link..."
    bash "$CLI" share "$blob_name" "$SHARE_HOURS" > "$TMP_DIR/share.out" 2>&1
    local sas_url
    sas_url="$(grep -E '^https://' "$TMP_DIR/share.out" | head -n1 || true)"
    [[ -n "$sas_url" ]] || fail "CLI did not return a SAS URL."
    sanitize "$TMP_DIR/share.out" "$EVIDENCE_DIR/share-success.txt"

    log "Opening link anonymously..."
    local link_status
    link_status=$(curl -sS -o "$TMP_DIR/via-link.bin" -w "%{http_code}" "$sas_url" || true)
    expect_status "$link_status" "200" "anonymous link open"
    cmp -s "$TMP_DIR/statement.txt" "$TMP_DIR/via-link.bin" ||
        fail "Content downloaded through link does not match uploaded file."

    log "Downloading through the CLI..."
    bash "$CLI" download "$blob_name" "$TMP_DIR/downloaded.txt" > "$TMP_DIR/download.out" 2>&1
    cmp -s "$TMP_DIR/statement.txt" "$TMP_DIR/downloaded.txt" ||
        fail "CLI download content does not match uploaded file."
    sanitize "$TMP_DIR/download.out" "$EVIDENCE_DIR/download.txt"

    log "Revoking all user delegation keys..."
    bash "$CLI" revoke-share > "$TMP_DIR/revoke.out" 2>&1
    cat "$TMP_DIR/revoke.out"
    sanitize "$TMP_DIR/revoke.out" "$EVIDENCE_DIR/revoke-success.txt"

    log "Verifying revoked link is denied..."
    local revoked_status
    revoked_status=$(curl -sS -o "$TMP_DIR/revoked.out" -w "%{http_code}" "$sas_url" || true)
    expect_status "$revoked_status" "403" "revoked link"
    sanitize "$TMP_DIR/revoked.out" "$EVIDENCE_DIR/revoked-link-denied.txt"

    if [[ "$CLEANUP_BLOB" == "true" ]]; then
        log "Deleting test blob..."
        bash "$CLI" delete "$blob_name" > "$TMP_DIR/delete.out" 2>&1
        sanitize "$TMP_DIR/delete.out" "$EVIDENCE_DIR/delete.txt"
    fi

    log "Copying redacted audit trail..."
    bash "$CLI" audit-log 50 > "$TMP_DIR/audit.out" 2>&1
    sanitize "$TMP_DIR/audit.out" "$EVIDENCE_DIR/audit-trail.txt"

    log "Integration test passed. Evidence: $EVIDENCE_DIR"
}

main "$@"
