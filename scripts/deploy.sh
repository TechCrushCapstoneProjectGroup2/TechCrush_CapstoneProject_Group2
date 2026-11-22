#!/bin/bash

set -euo pipefail

# ==========================================
# LEDGERPOINT SECURE STORAGE
# AUTOMATED AZURE DEPLOYMENT
# ==========================================

PROJECT_NAME="ledgerpoint-secure-storage"

RESOURCE_GROUP="rg-ledgerpoint-storage"

LOCATION="eastus"

FILE_CONTAINER="ledgerpoint-files"

AUDIT_CONTAINER="ledgerpoint-audit"

CONFIG_FILE="config/config.env"

echo "=========================================="
echo " LEDGERPOINT AZURE DEPLOYMENT"
echo "=========================================="

# 1. Check Azure CLI

if ! command -v az >/dev/null 2>&1; then
    echo "ERROR: Azure CLI is not installed."
    exit 1
fi

echo "[OK] Azure CLI detected."

# 2. Check authentication

if ! az account show >/dev/null 2>&1; then
    echo "Please sign in to Azure."

    az login
fi

echo "[OK] Azure authentication verified."

# 3. Get signed-in user

USER_ID=$(az ad signed-in-user show \
    --query id \
    --output tsv)

if [[ -z "$USER_ID" ]]; then
    echo "ERROR: Could not identify signed-in user."
    exit 1
fi

# 4. Generate unique storage account name

RANDOM_SUFFIX=$(date +%s | tail -c 7)

STORAGE_ACCOUNT="lpsecure${RANDOM_SUFFIX}"

echo "Storage Account: $STORAGE_ACCOUNT"

# 5. Create resource group

echo "[1/7] Creating Resource Group..."

az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output table

# 6. Create private storage account

echo "[2/7] Creating Azure Storage Account..."

az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --output table

# 7. Enforce private access

echo "[3/7] Enforcing Storage Security..."

az storage account update \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --allow-blob-public-access false \
    --https-only true \
    --min-tls-version TLS1_2 \
    --output table

# 8. Create private file container

echo "[4/7] Creating File Container..."

az storage container create \
    --name "$FILE_CONTAINER" \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login \
    --public-access off \
    --output table

# 9. Create private audit container

echo "[5/7] Creating Audit Container..."

az storage container create \
    --name "$AUDIT_CONTAINER" \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login \
    --public-access off \
    --output table

# 10. Assign storage permissions

echo "[6/7] Assigning Azure RBAC Roles..."

STORAGE_ID=$(az storage account show \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --query id \
    --output tsv)

az role assignment create \
    --assignee "$USER_ID" \
    --role "Storage Blob Data Contributor" \
    --scope "$STORAGE_ID" \
    --output none

az role assignment create \
    --assignee "$USER_ID" \
    --role "Storage Blob Delegator" \
    --scope "$STORAGE_ID" \
    --output none

# 11. Save configuration

echo "[7/7] Saving Configuration..."

cat > "$CONFIG_FILE" <<EOF
PROJECT_NAME="$PROJECT_NAME"
RESOURCE_GROUP="$RESOURCE_GROUP"
LOCATION="$LOCATION"
STORAGE_ACCOUNT="$STORAGE_ACCOUNT"
FILE_CONTAINER="$FILE_CONTAINER"
AUDIT_CONTAINER="$AUDIT_CONTAINER"
DEFAULT_SAS_EXPIRY_MINUTES=15
MAX_SAS_EXPIRY_MINUTES=60
LOG_FILE="logs/audit.log"
EOF

echo ""
echo "=========================================="
echo " DEPLOYMENT COMPLETED"
echo "=========================================="

echo "Resource Group: $RESOURCE_GROUP"

echo "Storage Account: $STORAGE_ACCOUNT"

echo "File Container: $FILE_CONTAINER"

echo "Audit Container: $AUDIT_CONTAINER"

echo ""
echo "Public Blob Access: DISABLED"

echo "HTTPS Only: ENABLED"

echo "=========================================="
