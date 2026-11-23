#!/usr/bin/env bash

# Creates a short-lived SAS link, waits for expiry and captures the denied request.
# Save redacted proof to evidence/screenshots/03-expired-link-denied/.

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI="$ROOT_DIR/scripts/ledgerpoint-cli.sh"
REDACT="$ROOT_DIR/tests/evidence-scripts/redact.sh"

# shellcheck source=../../config.sh
source "$ROOT_DIR/config.sh"

BLOB_NAME="${1:-test/expiry-proof.txt}"
SHARE_HOURS="${SHARE_HOURS:-0.01}"
WAIT_SECONDS="${WAIT_SECONDS:-75}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$ROOT_DIR/evidence/screenshots/03-expired-link-denied}"

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

main() {
    check_command curl
    check_command sleep
    check_command grep

    [[ -n "$STORAGE_ACCOUNT" ]] ||
        fail "STORAGE_ACCOUNT is required. Set it in .env before running."

    mkdir -p "$EVIDENCE_DIR"

    printf 'Expiry proof\n' > "$TMP_DIR/expiry-proof.txt"

    log "Uploading '$BLOB_NAME'..."
    bash "$CLI" upload "$TMP_DIR/expiry-proof.txt" "$BLOB_NAME" > "$TMP_DIR/upload.out" 2>&1

    log "Generating short-lived link (${SHARE_HOURS} hours)..."
    bash "$CLI" share "$BLOB_NAME" "$SHARE_HOURS" > "$TMP_DIR/share.out" 2>&1

    local sas_url
    sas_url="$(grep -E '^https://' "$TMP_DIR/share.out" | head -n1 || true)"
    [[ -n "$sas_url" ]] || fail "CLI did not return a SAS URL."

    bash "$REDACT" "$TMP_DIR/share.out" > "$EVIDENCE_DIR/share-link-redacted.txt"

    log "Waiting ${WAIT_SECONDS}s for expiry..."
    sleep "$WAIT_SECONDS"

    local status
    status=$(curl -sS -o "$TMP_DIR/denied.out" -w "%{http_code}" "$sas_url" || true)
    if [[ "$status" != "403" ]]; then
        fail "Expected HTTP 403 after expiry, got ${status:-<none>}. Increase WAIT_SECONDS."
    fi

    bash "$REDACT" "$TMP_DIR/denied.out" > "$EVIDENCE_DIR/expired-link-denied.txt"

    log "Expired-link proof saved to $EVIDENCE_DIR"
}

main "$@"
