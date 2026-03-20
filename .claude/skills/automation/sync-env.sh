#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"

log_info "🔐 Syncing Terraform Outputs to App .env..."

# Fetch outputs raw
DB_HOST=$(terraform -chdir=terraform output -raw database_fqdn)
LB_IP=$(terraform -chdir=terraform output -raw application_gateway_public_ip)

# Path to your Book Review App directory (adjust if different)
APP_DIR="../book-review-app"

if [ -d "$APP_DIR" ]; then
    cat <<EOF > "$APP_DIR/.env"
DB_HOST=$DB_HOST
DB_USER=dbadmin
DB_PASS=$(grep "db_password" terraform/terraform.tfvars | awk -F '"' '{print $2}' | tr -d ' ')
LB_PUBLIC_IP=$LB_IP
NODE_ENV=production
EOF
    log_success "Generated $APP_DIR/.env"
else
    log_warn "App directory not found. .env created in skills/tmp/ instead."
    cp "$APP_DIR/.env" "skills/tmp/.env.bak" 2>/dev/null
fi