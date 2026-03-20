#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
check_cmd terraform

# Guardrail: Requires a 'force' argument to prevent accidental AI deletion
if [ "$1" != "--force" ]; then
    log_error "Safety Lock Active. Use './destroy.sh --force' to terminate infrastructure."
    exit 1
fi

log_warn "🧨 DESTROYING ALL INFRASTRUCTURE in 5 seconds... (Ctrl+C to abort)"
sleep 5

terraform -chdir=terraform destroy -auto-approve
if [ $? -eq 0 ]; then
    log_success "Infrastructure wiped. Resource Group is clean."
else
    log_error "Destroy failed. Some resources may still exist in Azure."
    exit 1
fi