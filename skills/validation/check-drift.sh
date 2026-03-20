#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"

log_info "🛡️ Auditing for Destructive Changes..."
terraform -chdir=terraform plan -out=tfplan > /dev/null

DELETIONS=$(terraform -chdir=terraform show tfplan | grep "to destroy")

if [ ! -z "$DELETIONS" ]; then
    log_warn "⚠️ WARNING: DESTRUCTIVE CHANGES DETECTED!"
    echo "$DELETIONS"
    exit 2 
fi

log_success "Plan is non-destructive. Safe to proceed."