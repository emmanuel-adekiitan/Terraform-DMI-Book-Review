#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
check_cmd terraform

log_info "🏗️ Generating Infrastructure Plan..."
# -detailed-exitcode: 0=no changes, 2=changes, 1=error
terraform -chdir=terraform plan -out=tfplan -detailed-exitcode > /dev/null
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    log_success "No changes detected. Infrastructure is in sync."
elif [ $EXIT_CODE -eq 2 ]; then
    log_warn "Changes detected. Exporting plan for AI review..."
    terraform -chdir=terraform show -json tfplan > skills/tmp/last_plan.json
    log_info "Plan saved to skills/tmp/last_plan.json"
else
    log_error "Terraform plan failed!"
    exit 1
fi