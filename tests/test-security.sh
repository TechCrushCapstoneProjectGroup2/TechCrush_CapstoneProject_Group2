
#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

# ==========================================
# LEDGERPOINT SECURITY REGRESSION TESTS
# TECHCRUSH GROUP 2 CAPSTONE
# ==========================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ledgerpoint-capstone}"

# ==========================================
# 1. REQUIREMENTS
# ==========================================

if [[ -z "${STORAGE_ACCOUNT:-}" ]]; then
    echo "FAIL: STORAGE_ACCOUNT is not configured." >&2
    exit 1
fi

for tool in az curl
do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "FAIL: Required tool not found: $tool" >&2
        exit 1
    fi
done

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Verify an Azure Storage account setting.
check_setting() {
    local property="$1"
    local expected="$2"
    local actual

    actual="$(az storage account show \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --query "$property" \
        --output tsv)"

    if [[ "${actual,,}" != "${expected,,}" ]]; then
        fail "$property expected $expected, received $actual"
    fi
}

# Check whether a blob exists in a container.
blob_exists() {
    local container="$1"
    local name="$2"

    az storage blob exists \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$container" \
        --name "$name" \
        --auth-mode login \
        --query exists \
        --output tsv
}

mkdir -p logs

BLOB_NAME="security-test-$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}.txt"
SOURCE_FILE="$(mktemp logs/.security-test.XXXXXXXX)"

ORIGINAL_CREATED=false
SHARE_CREATED=false

SHARE_BLOB=""
SAS_URL=""

# ==========================================
# 2. CLEANUP
# ==========================================

cleanup() {
    local status="$?"

    trap - EXIT

    if [[ "$SHARE_CREATED" == true &&
          -n "$SHARE_BLOB" ]]; then

        echo "Cleanup: Removing auditor test copy..."

        ./scripts/ledgerpoint.sh revoke \
            "$SHARE_BLOB" --confirm >/dev/null 2>&1 ||
            echo "WARNING: Check for a remaining auditor copy." >&2
    fi

    if [[ "$ORIGINAL_CREATED" == true ]]; then

        echo "Cleanup: Removing original test document..."

        ./scripts/ledgerpoint.sh delete \
            "$BLOB_NAME" --confirm >/dev/null 2>&1 ||
            echo "WARNING: Check for a remaining test original." >&2
    fi

    rm -f -- "$SOURCE_FILE"

    # Discard the secret URL from this script's shell.
    unset SAS_URL

    exit "$status"
}

trap cleanup EXIT

# ==========================================
# TEST 1: STORAGE SECURITY SETTINGS
# ==========================================

echo "TEST 1: Verify Azure Storage security settings"

check_setting allowBlobPublicAccess false
check_setting allowSharedKeyAccess false
check_setting enableHttpsTrafficOnly true
check_setting minimumTlsVersion TLS1_2

echo "PASS: Storage security settings verified."


# ==========================================
# TEST 2: CREATE AND UPLOAD TEST DOCUMENT
# ==========================================

echo "TEST 2: Upload disposable security test document"

printf 'LedgerPoint fictional security regression test\n' \
    > "$SOURCE_FILE"

./scripts/ledgerpoint.sh upload \
    "$SOURCE_FILE" "$BLOB_NAME"

# Mark for cleanup after successful upload.
ORIGINAL_CREATED=true

[[ "$(blob_exists originals "$BLOB_NAME")" == "true" ]] ||
    fail "Original test document was not found."

echo "PASS: Security test document uploaded."


# ==========================================
# TEST 3: BLOCK ANONYMOUS ACCESS
# ==========================================

echo "TEST 3: Verify anonymous access is denied"

PUBLIC_URL="https://${STORAGE_ACCOUNT}.blob.core.windows.net/originals/${BLOB_NAME}"

HTTP_PUBLIC="$(curl \
    --silent --show-error \
    --connect-timeout 10 \
    --max-time 30 \
    --output /dev/null \
    --write-out '%{http_code}' \
    "$PUBLIC_URL")"

case "$HTTP_PUBLIC" in
    401|403|409)
        echo "PASS: Anonymous access blocked (HTTP $HTTP_PUBLIC)."
        ;;
    *)
        fail "Unexpected anonymous access result: HTTP $HTTP_PUBLIC"
        ;;
esac


# ==========================================
# TEST 4: REQUIRE DELETION CONFIRMATION
# ==========================================

echo "TEST 4: Reject deletion without confirmation"

if ./scripts/ledgerpoint.sh delete \
    "$BLOB_NAME" >/dev/null 2>&1; then

    fail "Deletion succeeded without --confirm."
fi

echo "PASS: Unconfirmed deletion rejected."


# ==========================================
# TEST 5: VERIFY ORIGINAL WAS PROTECTED
# ==========================================

echo "TEST 5: Verify original survived rejected deletion"

[[ "$(blob_exists originals "$BLOB_NAME")" == "true" ]] ||
    fail "Original document was unexpectedly removed."

echo "PASS: Original still exists."


# ==========================================
# TEST 6: GENERATE READ-ONLY SAS LINK
# ==========================================

echo "TEST 6: Generate secure temporary auditor link"

SAS_URL="$(./scripts/ledgerpoint.sh share "$BLOB_NAME" 30)"

[[ "$SAS_URL" == https://*\?* ]] ||
    fail "Expected an HTTPS SAS URL."

SHARE_BLOB="${SAS_URL%%\?*}"
SHARE_BLOB="${SHARE_BLOB##*/}"

[[ "$SHARE_BLOB" == auditor-* ]] ||
    fail "Unexpected temporary sharing blob name."

SHARE_CREATED=true

echo "PASS: HTTPS auditor link generated."


# ==========================================
# TEST 7: ALLOW AUTHORIZED READING
# ==========================================

echo "TEST 7: Verify read-only link permits reading"

HTTP_READ="$(curl \
    --silent --show-error \
    --connect-timeout 10 \
    --max-time 30 \
    --output /dev/null \
    --write-out '%{http_code}' \
    "$SAS_URL")"

[[ "$HTTP_READ" == "200" ]] ||
    fail "Authorized read returned HTTP $HTTP_READ."

echo "PASS: Auditor can read (HTTP 200)."


# ==========================================
# TEST 8: REJECT UNAUTHORIZED DELETION
# ==========================================

echo "TEST 8: Verify auditor cannot delete shared blob"

# This DELETE request deliberately tests the
# temporary document, not the original.
#
# A read-only SAS must NOT authorize deletion.

HTTP_DELETE="$(curl \
    --silent --show-error \
    --connect-timeout 10 \
    --max-time 30 \
    --request DELETE \
    --header 'x-ms-version: 2021-12-02' \
    --output /dev/null \
    --write-out '%{http_code}' \
    "$SAS_URL")"

[[ "$HTTP_DELETE" == "403" ]] ||
    fail "Expected HTTP 403 for unauthorized DELETE; got $HTTP_DELETE."

echo "PASS: Auditor DELETE denied (HTTP 403)."


# ==========================================
# TEST 9: VERIFY AUDITOR COPY SURVIVED
# ==========================================

echo "TEST 9: Verify denied DELETE did not remove copy"

[[ "$(blob_exists temporary-shares "$SHARE_BLOB")" == "true" ]] ||
    fail "Temporary copy disappeared unexpectedly."

echo "PASS: Temporary copy is intact."


# ==========================================
# TEST 10: REVOKE TEMPORARY ACCESS
# ==========================================

echo "TEST 10: Revoke auditor sharing link"

./scripts/ledgerpoint.sh revoke \
    "$SHARE_BLOB" --confirm

[[ "$(blob_exists temporary-shares "$SHARE_BLOB")" == "false" ]] ||
    fail "Temporary auditor copy still exists after revocation."

SHARE_CREATED=false

echo "PASS: Auditor copy revoked and deleted."


# ==========================================
# TEST 11: VERIFY REVOCATION AND ORIGINAL
# ==========================================

echo "TEST 11: Verify revoked link fails and original survives"

HTTP_REVOKED="$(curl \
    --silent --show-error \
    --connect-timeout 10 \
    --max-time 30 \
    --output /dev/null \
    --write-out '%{http_code}' \
    "$SAS_URL")"

[[ "$HTTP_REVOKED" == "404" ]] ||
    fail "Expected HTTP 404 after revocation; got $HTTP_REVOKED."

[[ "$(blob_exists originals "$BLOB_NAME")" == "true" ]] ||
    fail "Original missing after auditor access was revoked."

echo "PASS: Revoked link blocked (HTTP 404)."
echo "PASS: Original document preserved."


# ==========================================
# TEST 12: REMOVE DISPOSABLE ORIGINAL
# ==========================================

echo "TEST 12: Clean up disposable security test document"

./scripts/ledgerpoint.sh delete \
    "$BLOB_NAME" --confirm

[[ "$(blob_exists originals "$BLOB_NAME")" == "false" ]] ||
    fail "Disposable original still exists."

ORIGINAL_CREATED=false

echo "PASS: Security test document removed."


# ==========================================
# FINAL RESULT
# ==========================================

echo "========================================"
echo "PASS: ALL 12 SECURITY TESTS COMPLETED"
echo "========================================"
