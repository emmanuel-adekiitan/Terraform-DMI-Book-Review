#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"

log_info "🔐 Rotating Database Administrative Password..."

# Generate a 16-character random alphanumeric password
NEW_PASS=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
TFVARS="terraform/terraform.tfvars"

if [ -f "$TFVARS" ]; then
    # Use sed to replace the db_password line
    sed -i "s/db_password.*/db_password = \"$NEW_PASS\"/" "$TFVARS"
    log_success "Password rotated in $TFVARS. Run skills/core/apply.sh to sync with Azure."
else
    log_error "Could not find $TFVARS to rotate keys."
    exit 1
fi