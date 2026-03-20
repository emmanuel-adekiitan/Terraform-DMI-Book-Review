#!/bin/bash
# Hook Orchestrator for Agentic DevOps
# Project: DMI-Book-Review-Production

source "./skills/lib/common.sh"

COMMAND=$1

case $COMMAND in
  "deploy")
    log_info "🛡️ Hook Triggered: Pre-Deployment Audit (Sentry Persona)"
    # 1. Verify Environment
    ./skills/validation/verify-env.sh || { log_error "Environment Mismatch. Aborting."; exit 1; }
    
    # 2. Run Drift Check
    ./skills/validation/check-drift.sh
    DRIFT_STATUS=$?
    
    if [ $DRIFT_STATUS -eq 2 ]; then
        log_warn "🛑 CRITICAL: Destructive changes detected. Manual Approval Required."
        exit 2
    elif [ $DRIFT_STATUS -eq 0 ]; then
        log_success "✅ Audit Passed. Handing over to Pilot Persona..."
        ./skills/core/apply.sh
    else
        log_error "Audit failed due to technical error."
        exit 1
    fi
    ;;

  "sync")
    log_info "🔗 Hook Triggered: Post-Apply Sync & Health"
    ./skills/automation/sync-env.sh
    ./skills/validation/verify-health.sh
    ;;

  "teardown")
    log_warn "⚠️ Hook Triggered: Destruction Guard"
    if [[ "$2" != "--force" ]]; then
        log_error "Destruction blocked. Manual --force flag required."
        exit 1
    fi
    ./skills/core/destroy.sh --force
    ;;

  *)
    log_error "Usage: ./hooks.sh {deploy|sync|teardown}"
    exit 1
    ;;
esac