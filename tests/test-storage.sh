
#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

# ==========================================
# LEDGERPOINT AUTOMATED STORAGE TEST
# TECHCRUSH GROUP 2 CAPSTONE
# ==========================================

# Move to the project root.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Verify configuration.
if [[ -z "${STORAGE_ACCOUNT:-}" ]]; then
    echo "FAIL: STORAGE_ACCOUNT is not configured."
    exit 1
fi

# Create a unique test document name.
BLOB_NAME="storage-test-$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}.txt"

mkdir -p logs downloads

SOURCE_FILE="$(mktemp logs/.storage-test.XXXXXXXX)"
DOWNLOADED_FILE="downloads/$BLOB_NAME"

UPLOADED=false

# ==========================================
# CLEANUP
# ==========================================

cleanup() {
    rm -f -- "$SOURCE_FILE" "$DOWNLOADED_FILE"

    # If the test fails after uploading,
    # try to remove only its own test document.
    if [[ "$UPLOADED" == true ]]; then
        echo "Cleanup: removing temporary Azure test document..."

        ./scripts/ledgerpoint.sh delete \
            "$BLOB_NAME" --confirm >/dev/null || \
            echo "WARNING: Check whether the test document remains in Azure."
    fi
}

trap cleanup EXIT


# ==========================================
# TEST 1: CREATE LOCAL TEST DOCUMENT
# ==========================================

printf 'LedgerPoint automated storage test\n' > "$SOURCE_FILE"

echo "TEST 1: Create test document"
echo "PASS: Test document created."


# ==========================================
# TEST 2: UPLOAD
# ==========================================

echo "TEST 2: Upload document"

./scripts/ledgerpoint.sh upload \
    "$SOURCE_FILE" \
    "$BLOB_NAME"

UPLOADED=true

echo "PASS: Upload succeeded."


# ==========================================
# TEST 3: VERIFY AZURE BLOB EXISTS
# ==========================================

echo "TEST 3: Verify blob exists"

EXISTS=$(az storage blob exists \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name originals \
    --name "$BLOB_NAME" \
    --auth-mode login \
    --query exists \
    --output tsv)

if [[ "$EXISTS" != "true" ]]; then
    echo "FAIL: Uploaded blob not found."
    exit 1
fi

echo "PASS: Blob exists in Azure."


# ==========================================
# TEST 4: LIST
# ==========================================

echo "TEST 4: Verify document appears in listing"

BLOB_LIST="$(./scripts/ledgerpoint.sh list originals)"

if ! grep -Fq "\"$BLOB_NAME\"" <<< "$BLOB_LIST"; then
    echo "FAIL: Blob missing from listing."
    exit 1
fi

echo "PASS: Blob appears in listing."


# ==========================================
# TEST 5: DOWNLOAD
# ==========================================

echo "TEST 5: Download document"

./scripts/ledgerpoint.sh download "$BLOB_NAME"

if [[ ! -f "$DOWNLOADED_FILE" ]]; then
    echo "FAIL: Downloaded document not found."
    exit 1
fi

echo "PASS: Download succeeded."


# ==========================================
# TEST 6: VERIFY CONTENT INTEGRITY
# ==========================================

echo "TEST 6: Compare document contents"

if ! cmp -s "$SOURCE_FILE" "$DOWNLOADED_FILE"; then
    echo "FAIL: File contents do not match."
    exit 1
fi

echo "PASS: Downloaded content matches original."


# ==========================================
# TEST 7: DELETE TEST DOCUMENT
# ==========================================

echo "TEST 7: Delete disposable document"

./scripts/ledgerpoint.sh delete "$BLOB_NAME" --confirm

echo "PASS: Delete command succeeded."


# ==========================================
# TEST 8: VERIFY DELETION
# ==========================================

echo "TEST 8: Verify blob no longer exists"

EXISTS=$(az storage blob exists \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name originals \
    --name "$BLOB_NAME" \
    --auth-mode login \
    --query exists \
    --output tsv)

if [[ "$EXISTS" != "false" ]]; then
    echo "FAIL: Test blob still exists in Azure."
    exit 1
fi

UPLOADED=false

echo "PASS: Blob successfully deleted."


# ==========================================
# FINAL RESULT
# ==========================================

echo "========================================"
echo "PASS: ALL 8 STORAGE TESTS COMPLETED"
echo "========================================"
