#!/bin/bash
# Skill: verify_environment
# Description: Checks Azure CLI login and Subscription ID sync.

echo "🔍 Checking Azure Authentication..."
AZ_SUB=$(az account show --query id -o tsv 2>/dev/null)
TF_SUB=$(grep "subscription_id" terraform/terraform.tfvars | awk -F '"' '{print $2}')

if [ -z "$AZ_SUB" ]; then
    echo "❌ Error: Not logged into Azure CLI. Run 'az login'."
    exit 1
fi

if [ "$AZ_SUB" != "$TF_SUB" ]; then
    echo "❌ Error: Subscription Mismatch!"
    echo "CLI is on: $AZ_SUB"
    echo "Terraform expects: $TF_SUB"
    exit 1
fi

echo "✅ Environment synced to Subscription: $AZ_SUB"