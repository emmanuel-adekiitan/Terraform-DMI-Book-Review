#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
check_cmd terraform

log_info "🚀 Executing Deployment (Auto-Approve)..."
terraform -chdir=terraform apply -auto-approve
if [ $? -eq 0 ]; then
    log_success "Deployment successful!"
    # Trigger sync automatically after apply
    ./skills/automation/sync-env.sh
else
    log_error "Deployment failed. Run check-drift.sh to investigate."
    exit 1
fi