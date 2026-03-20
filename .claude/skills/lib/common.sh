#!/bin/bash
# Shared Library for Agentic Skills - Terraform-DMI Project

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $(date +'%H:%M:%S') - $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $(date +'%H:%M:%S') - $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $(date +'%H:%M:%S') - $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $(date +'%H:%M:%S') - $1"; }

# Function to check if a required CLI tool is installed
check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Dependency Missing: '$1' is not installed or in PATH."
        exit 1
    fi
}