
#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

# ==========================================
# LEDGERPOINT AUTOMATED SHARING TEST
# TECHCRUSH GROUP 2 CAPSTONE
# ==========================================

# Work from the project root.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# ==========================================
# 1. CHECK REQUIREMENTS
# ==========================================

if [[ -z "${STORAGE_ACCOUNT:-}" ]]; then
    echo "FAIL: STORAGE_ACCOUNT is not configured."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "FAIL: curl is required."
    exit 1
fi

mkdir -p logs

# Unique disposable test document.
BLOB_NAME="sharing-test-$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}.txt"

SOURCE_FILE="$(mktemp logs/.sharing-test.XXXXXXXX)"

ORIGINAL_PRESENT=false
AUDITOR_PRESENT=false

SHARE_BLOB=""
SAS_URL=""

# ==========================================
# 2. AUTOMATIC CLEANUP
# ==========================================

cleanup() {
    local status="$?"

    trap - EXIT

    # Remove the auditor copy if a test failed
    # before revocation was completed.
    if [[ "$AUDITOR_PRESENT" == true &&
          -n "$SHARE_BLOB" ]]; then

        echo "Cleanup: Removing temporary auditor copy..."

        ./scripts/ledgerpoint.sh revoke \
            "$SHARE_BLOB" --confirm >/dev/null 2>&1 ||
            echo "WARNING: Check the temporary auditor copy in Azure."
    fi

    # Remove the disposable original if it
    # was not already deleted.
    if [[ "$ORIGINAL_PRESENT" == true ]]; then

        echo "Cleanup: Removing disposable original..."

        ./scripts/ledgerpoint.sh delete \
            "$BLOB_NAME" --confirm >/dev/null 2>&1 ||
            echo "WARNING: Check the test original in Azure."
    fi

    rm -f -- "$SOURCE_FILE"

    # Discard the confidential SAS URL variable.
    unset SAS_URL

    exit "$status"
}

trap cleanup EXIT

# ==========================================
# TEST 1: CREATE FICTIONAL DOCUMENT
# ==========================================

echo "TEST 1: Create fictional test document"

printf 'LedgerPoint sharing automation test\n' \
    > "$SOURCE_FILE"

echo "PASS: Test document created."


# ==========================================
# TEST 2: UPLOAD ORIGINAL
# ==========================================

echo "TEST 2: Upload original document"

./scripts/ledgerpoint.sh upload \
    "$SOURCE_FILE" "$BLOB_NAME"

ORIGINAL_PRESENT=true

echo "PASS: Original uploaded."


# ==========================================
# TEST 3: CREATE SECURE SHARING LINK
# ==========================================

echo "TEST 3: Generate temporary auditor link"

# Keep the SAS URL in a shell variable.
# Never display it in the terminal.
SAS_URL="$(./scripts/ledgerpoint.sh share "$BLOB_NAME" 30)"

if [[ "$SAS_URL" != https://*\?* ]]; then
    echo "FAIL: Valid HTTPS sharing URL not generated."
    exit 1
fi

# Extract the temporary blob name, not its token.
SHARE_BLOB="${SAS_URL%%\?*}"
SHARE_BLOB="${SHARE_BLOB##*/}"

if [[ "$SHARE_BLOB" != auditor-* ]]; then
    echo "FAIL: Invalid temporary auditor blob name."
    exit 1
fi

AUDITOR_PRESENT=true

echo "PASS: Temporary sharing link generated."


# ==========================================
# TEST 4: VERIFY AUDITOR COPY EXISTS
# ==========================================

echo "TEST 4: Verify temporary auditor copy exists"

EXISTS="$(az storage blob exists \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name temporary-shares \
    --name "$SHARE_BLOB" \
    --auth-mode login \
    --query exists \
    --output tsv)"

if [[ "$EXISTS" != "true" ]]; then
    echo "FAIL: Temporary auditor copy not found."
    exit 1
fi

echo "PASS: Auditor copy exists."


# ==========================================
# TEST 5: VERIFY AUDITOR CAN READ
# ==========================================

echo "TEST 5: Verify auditor access"

HTTP_BEFORE="$(curl \
    --silent --show-error \
    --output /dev/null \
    --write-out '%{http_code}' \
    "$SAS_URL")"

if [[ "$HTTP_BEFORE" != "200" ]]; then
    echo "FAIL: Expected HTTP 200; received $HTTP_BEFORE."
    exit 1
fi

echo "PASS: Auditor access returned HTTP 200."


# ==========================================
# TEST 6: REQUIRE REVOCATION CONFIRMATION
# ==========================================

echo "TEST 6: Reject revocation without confirmation"

if ./scripts/ledgerpoint.sh revoke \
    "$SHARE_BLOB" >/dev/null 2>&1; then

    echo "FAIL: Revocation succeeded without --confirm."
    exit 1
fi

echo "PASS: Missing confirmation was rejected."


# ==========================================
# TEST 7: REVOKE TEMPORARY ACCESS
# ==========================================

echo "TEST 7: Revoke auditor access"

./scripts/ledgerpoint.sh revoke \
    "$SHARE_BLOB" --confirm

echo "PASS: Revocation command succeeded."


# ==========================================
# TEST 8: VERIFY TEMPORARY COPY DELETED
# ==========================================

echo "TEST 8: Verify auditor copy is deleted"

EXISTS="$(az storage blob exists \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name temporary-shares \
    --name "$SHARE_BLOB" \
    --auth-mode login \
    --query exists \
    --output tsv)"

if [[ "$EXISTS" != "false" ]]; then
    echo "FAIL: Auditor copy still exists."
    exit 1
fi

AUDITOR_PRESENT=false

echo "PASS: Auditor copy deleted."


# ==========================================
# TEST 9: VERIFY OLD LINK NO LONGER WORKS
# ==========================================

echo "TEST 9: Verify revoked link cannot download"

HTTP_AFTER="$(curl \
    --silent --show-error \
    --output /dev/null \
    --write-out '%{http_code}' \
    "$SAS_URL")"

if [[ "$HTTP_AFTER" != "404" ]]; then
    echo "FAIL: Expected HTTP 404; received $HTTP_AFTER."
    exit 1
fi

echo "PASS: Revoked link returned HTTP 404."


# ==========================================
# TEST 10: VERIFY ORIGINAL IS PRESERVED
# ==========================================

echo "TEST 10: Verify original remains available"

EXISTS="$(az storage blob exists \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name originals \
    --name "$BLOB_NAME" \
    --auth-mode login \
    --query exists \
    --output tsv)"

if [[ "$EXISTS" != "true" ]]; then
    echo "FAIL: Original was unexpectedly removed."
    exit 1
fi

echo "PASS: Original was preserved."


# ==========================================
# TEST 11: CLEAN UP DISPOSABLE ORIGINAL
# ==========================================

echo "TEST 11: Remove disposable original"

./scripts/ledgerpoint.sh delete \
    "$BLOB_NAME" --confirm

echo "PASS: Disposable original deleted."


# ==========================================
# TEST 12: VERIFY CLEANUP
# ==========================================

echo "TEST 12: Verify test original no longer exists"

EXISTS="$(az storage blob exists \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name originals \
    --name "$BLOB_NAME" \
    --auth-mode login \
    --query exists \
    --output tsv)"

if [[ "$EXISTS" != "false" ]]; then
    echo "FAIL: Test original still exists."
    exit 1
fi

ORIGINAL_PRESENT=false

echo "PASS: Test cleanup verified."


# ==========================================
# FINAL RESULT
# ==========================================

echo "========================================"
echo "PASS: ALL 12 SHARING TESTS COMPLETED"
echo "========================================"
