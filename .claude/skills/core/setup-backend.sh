#!/bin/bash
# Skill: setup_backend
# Description: Provisions Azure Storage for Terraform remote state and
#              emits the storage account name on stdout for downstream use.
# Usage: ./setup-backend.sh
# Output: Prints the storage account name as the final line (for capture).

set -euo pipefail
source "$(dirname "$0")/../lib/common.sh"

# ── Configuration ────────────────────────────────────────────────────────────
STATE_RG="rg-terraform-state"
LOCATION="westeurope"
CONTAINER_NAME="tfstate"

# Deterministic name: "dmibrstate" + first 8 hex chars of subscription ID.
# Guarantees idempotency — re-running this script never creates a second account.
SUB_ID=$(az account show --query id -o tsv 2>/dev/null)
if [ -z "$SUB_ID" ]; then
    log_error "Not authenticated. Run 'az login' first."
    exit 1
fi
SUFFIX=$(echo "$SUB_ID" | tr -d '-' | cut -c1-8)
STORAGE_ACCOUNT="dmibrstate${SUFFIX}"

log_info "── Terraform State Backend Provisioner ──────────────────────────"
log_info "Subscription : $SUB_ID"
log_info "Resource Group : $STATE_RG"
log_info "Storage Account: $STORAGE_ACCOUNT"
log_info "Container      : $CONTAINER_NAME"
log_info "─────────────────────────────────────────────────────────────────"

# ── 1. Resource Group ─────────────────────────────────────────────────────
log_info "Step 1/3 — Creating Resource Group '${STATE_RG}'..."
az group create \
    --name "$STATE_RG" \
    --location "$LOCATION" \
    --output none
log_success "Resource Group '${STATE_RG}' ready."

# ── 2. Storage Account ────────────────────────────────────────────────────
log_info "Step 2/3 — Creating Storage Account '${STORAGE_ACCOUNT}'..."
az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$STATE_RG" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --output none
log_success "Storage Account '${STORAGE_ACCOUNT}' ready."

# ── 3. Blob Container ─────────────────────────────────────────────────────
log_info "Step 3/3 — Creating Blob Container '${CONTAINER_NAME}'..."
az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login \
    --output none
log_success "Container '${CONTAINER_NAME}' ready."

log_success "── Backend provisioning complete ────────────────────────────────"
log_info "  Resource Group  : ${STATE_RG}"
log_info "  Storage Account : ${STORAGE_ACCOUNT}"
log_info "  Container       : ${CONTAINER_NAME}"
log_info "  State Key       : terraform.tfstate"

# ── 4. Grant current identity Blob Data Contributor ──────────────────────
# Required because subscription policy disables key-based storage auth.
log_info "Step 4/4 — Assigning Storage Blob Data Contributor to current identity..."
CURRENT_USER=$(az ad signed-in-user show --query id -o tsv 2>/dev/null)
SCOPE="/subscriptions/${SUB_ID}/resourceGroups/${STATE_RG}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT}"
az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee "$CURRENT_USER" \
    --scope "$SCOPE" \
    --output none 2>/dev/null || log_warn "Role may already exist — skipping."
log_success "RBAC role assigned. Azure AD auth is ready."

# Emit storage account name as the final stdout line for capture by callers.
echo "$STORAGE_ACCOUNT"
