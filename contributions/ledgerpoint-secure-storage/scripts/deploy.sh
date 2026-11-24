
#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# LEDGERPOINT AZURE DEPLOYMENT SCRIPT
# TECHCRUSH GROUP 2 CAPSTONE
# ==========================================

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ledgerpoint-capstone}"
LOCATION="${LOCATION:-eastus}"


# ==========================================
# 1. VALIDATE CONFIGURATION
# ==========================================

if [[ -z "${STORAGE_ACCOUNT:-}" ]]; then
    echo "ERROR: STORAGE_ACCOUNT is not configured." >&2
    exit 1
fi

if [[ ! "$STORAGE_ACCOUNT" =~ ^[a-z0-9]{3,24}$ ]]; then
    echo "ERROR: Invalid Azure storage account name." >&2
    exit 1
fi

if ! command -v az >/dev/null 2>&1; then
    echo "ERROR: Azure CLI is not installed." >&2
    exit 1
fi

if ! az account show --output none >/dev/null 2>&1; then
    echo "ERROR: Sign in using az login." >&2
    exit 1
fi

echo "Azure authentication verified."
echo "Active subscription: $(az account show --query name -o tsv)"


# ==========================================
# 2. CREATE OR REUSE RESOURCE GROUP
# ==========================================

group_exists=$(az group exists \
    --name "$RESOURCE_GROUP" \
    --output tsv)

if [[ "${group_exists,,}" == "true" ]]; then
    echo "Resource group already exists."
else
    echo "Creating resource group..."

    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output none
fi


# ==========================================
# 3. CREATE OR REUSE STORAGE ACCOUNT
# ==========================================

existing_account=$(az storage account list \
    --resource-group "$RESOURCE_GROUP" \
    --query "[?name=='${STORAGE_ACCOUNT}'].name | [0]" \
    --output tsv)

if [[ "$existing_account" == "$STORAGE_ACCOUNT" ]]; then
    echo "Storage account already exists."
else
    echo "Creating secure storage account..."

    az storage account create \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --access-tier Hot \
        --allow-blob-public-access false \
        --allow-shared-key-access false \
        --https-only true \
        --min-tls-version TLS1_2 \
        --public-network-access Enabled \
        --output none
fi


# ==========================================
# 4. VERIFY STORAGE SECURITY
# ==========================================

check_setting() {
    local field="$1"
    local expected="$2"
    local actual

    actual=$(az storage account show \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --query "$field" \
        --output tsv)

    if [[ "${actual,,}" != "${expected,,}" ]]; then
        echo "ERROR: Security check failed: $field" >&2
        echo "Expected: $expected" >&2
        echo "Actual: $actual" >&2
        return 1
    fi

    echo "PASS: $field = $expected"
}

echo "Verifying security configuration..."

check_setting allowBlobPublicAccess false
check_setting allowSharedKeyAccess false
check_setting enableHttpsTrafficOnly true
check_setting minimumTlsVersion TLS1_2


# ==========================================
# 5. ENSURE PRIVATE CONTAINERS EXIST
# ==========================================

for container in originals temporary-shares
do
    echo "Checking container: $container"

    az storage container create \
        --name "$container" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --public-access off \
        --output none

    access=$(az storage container show \
        --name "$container" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --query properties.publicAccess \
        --output tsv)

    case "${access,,}" in
        ""|none|null)
            echo "PASS: $container is private."
            ;;
        *)
            echo "ERROR: Container $container has public access." >&2
            exit 1
            ;;
    esac
done


# ==========================================
# 6. VERIFY DEPLOYMENT
# ==========================================

echo "Listing LedgerPoint containers..."

az storage container list \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login \
    --query "[].{Name:name,PublicAccess:properties.publicAccess}" \
    --output table

echo "========================================"
echo "SUCCESS: LedgerPoint infrastructure verified."
echo "Resource Group: $RESOURCE_GROUP"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "========================================"


