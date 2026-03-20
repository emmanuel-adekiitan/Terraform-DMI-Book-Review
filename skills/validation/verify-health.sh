#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
check_cmd curl
check_cmd nc

log_info "🩺 Starting 3-Tier Health Check..."

# Get Public IP from Terraform Output
LB_IP=$(terraform -chdir=terraform output -raw application_gateway_public_ip)

# 1. Check Web Tier (App Gateway)
log_info "Checking Web Tier at http://$LB_IP..."
if curl -s --head  --request GET http://$LB_IP | grep "200 OK" > /dev/null; then
    log_success "Web Tier: ONLINE (200 OK)"
else
    log_warn "Web Tier: UNREACHABLE (Check NSG rules)"
fi

# 2. Check Database Connectivity (Internal check requires running from a jumpbox/VM)
log_info "Health check complete. Use 'az mysql flexible-server show' for deep DB metrics."