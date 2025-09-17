#!/bin/bash
################################################################################
# Njord Menu Core Library
# Core functions and utilities for Valheim server management
# Author: ZeroBandwidth & Team
# Version: 5.0-Odin
################################################################################

# Prevent double-sourcing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly" >&2
    exit 1
fi

# Set strict error handling
set -euo pipefail

################################################################################
# GLOBAL VARIABLES
################################################################################

# Script information
SCRIPT_NAME="$(basename "${BASH_SOURCE[1]:-${0}}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-${0}}")" && pwd)"
SCRIPT_VERSION="5.0-Odin"

# Default paths
DEFAULT_VALHEIM_PATH="/home/steam/valheimserver"
DEFAULT_WORLD_PATH="/home/steam/.config/unity3d/IronGate/Valheim"
DEFAULT_BACKUP_PATH="/home/steam/backups"
DEFAULT_WORLDS_FILE="/home/steam/worlds.txt"
DEFAULT_LOG_PATH="/var/log/njordmenu.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Log levels
LOG_ERROR=1
LOG_WARN=2
LOG_INFO=3
LOG_DEBUG=4

################################################################################
# LOGGING FUNCTIONS
################################################################################

# Initialize logging
init_logging() {
    local log_level="${1:-$LOG_INFO}"
    local log_file="${2:-$DEFAULT_LOG_PATH}"
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$log_file")"
    
    # Set global log variables
    export NJORD_LOG_LEVEL="$log_level"
    export NJORD_LOG_FILE="$log_file"
}

# Log function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local level_name=""
    
    case "$level" in
        $LOG_ERROR) level_name="ERROR" ;;
        $LOG_WARN)  level_name="WARN"  ;;
        $LOG_INFO)  level_name="INFO"  ;;
        $LOG_DEBUG) level_name="DEBUG" ;;
        *)          level_name="UNKNOWN" ;;
    esac
    
    # Only log if level is enabled
    if [[ "$level" -le "${NJORD_LOG_LEVEL:-$LOG_INFO}" ]]; then
        echo "[$timestamp] [$level_name] $message" >> "${NJORD_LOG_FILE:-$DEFAULT_LOG_PATH}"
    fi
}

# Convenience logging functions
log_error() { log $LOG_ERROR "$@"; }
log_warn()  { log $LOG_WARN "$@"; }
log_info()  { log $LOG_INFO "$@"; }
log_debug() { log $LOG_DEBUG "$@"; }

################################################################################
# COLOR OUTPUT FUNCTIONS
################################################################################

# Color output functions
print_red()    { echo -e "${RED}$*${NC}"; }
print_green()  { echo -e "${GREEN}$*${NC}"; }
print_yellow() { echo -e "${YELLOW}$*${NC}"; }
print_blue()   { echo -e "${BLUE}$*${NC}"; }
print_purple() { echo -e "${PURPLE}$*${NC}"; }
print_cyan()   { echo -e "${CYAN}$*${NC}"; }
print_white()  { echo -e "${WHITE}$*${NC}"; }

# Colored output with logging
print_error() {
    print_red "$*"
    log_error "$*"
}

print_warning() {
    print_yellow "$*"
    log_warn "$*"
}

print_success() {
    print_green "$*"
    log_info "$*"
}

print_info() {
    print_blue "$*"
    log_info "$*"
}

################################################################################
# UTILITY FUNCTIONS
################################################################################

# Check if running as root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if file exists and is readable
file_exists() {
    [[ -f "$1" && -r "$1" ]]
}

# Check if directory exists and is writable
dir_exists() {
    [[ -d "$1" && -w "$1" ]]
}

# Create directory with proper permissions
create_dir() {
    local dir="$1"
    local owner="${2:-steam}"
    local perms="${3:-755}"
    
    if ! dir_exists "$dir"; then
        mkdir -p "$dir"
        chown "$owner:$owner" "$dir"
        chmod "$perms" "$dir"
        log_info "Created directory: $dir"
    fi
}

# Safe file copy with backup
safe_copy() {
    local src="$1"
    local dest="$2"
    local backup_suffix="${3:-.bak}"
    
    if [[ -f "$dest" ]]; then
        cp "$dest" "${dest}${backup_suffix}"
        log_info "Backed up existing file: $dest -> ${dest}${backup_suffix}"
    fi
    
    cp "$src" "$dest"
    log_info "Copied file: $src -> $dest"
}

# Generate random password
generate_password() {
    local length="${1:-12}"
    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local password=""
    
    for ((i=0; i<length; i++)); do
        password="${password}${chars:$((RANDOM % ${#chars})):1}"
    done
    
    echo "$password"
}

# Validate password strength
validate_password() {
    local password="$1"
    local min_length="${2:-6}"
    
    if [[ ${#password} -lt $min_length ]]; then
        return 1
    fi
    
    if [[ ! "$password" =~ [[:lower:]] ]]; then
        return 1
    fi
    
    if [[ ! "$password" =~ [[:upper:]] ]]; then
        return 1
    fi
    
    if [[ ! "$password" =~ [[:digit:]] ]]; then
        return 1
    fi
    
    return 0
}

# Validate world name
validate_world_name() {
    local world_name="$1"
    local min_length="${2:-4}"
    
    if [[ ${#world_name} -lt $min_length ]]; then
        return 1
    fi
    
    if [[ ! "$world_name" =~ ^[a-zA-Z0-9]+$ ]]; then
        return 1
    fi
    
    return 0
}

# Validate server name
validate_server_name() {
    local server_name="$1"
    
    if [[ -z "$server_name" ]]; then
        return 1
    fi
    
    # Allow spaces, brackets, apostrophes, and basic punctuation
    # Use a simpler validation approach - check for invalid characters
    if echo "$server_name" | grep -q '[^a-zA-Z0-9\ \[\]'"'"'.,!-]'; then
        return 1
    fi
    
    return 0
}

# Validate port number
validate_port() {
    local port="$1"
    
    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    if [[ "$port" -lt 1024 || "$port" -gt 65535 ]]; then
        return 1
    fi
    
    return 0
}

################################################################################
# SYSTEM FUNCTIONS
################################################################################

# Get system information
get_system_info() {
    local info=""
    
    info+="Hostname: $(hostname)\n"
    info+="OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)\n"
    info+="Kernel: $(uname -r)\n"
    info+="Architecture: $(uname -m)\n"
    info+="Uptime: $(uptime -p 2>/dev/null || uptime)\n"
    info+="Memory: $(free -h | awk '/^Mem:/ {print $2}')\n"
    info+="Disk: $(df -h / | awk 'NR==2 {print $2}')\n"
    
    echo -e "$info"
}

# Check if service is running
is_service_running() {
    local service_name="$1"
    systemctl is-active --quiet "$service_name"
}

# Check if service exists
service_exists() {
    local service_name="$1"
    systemctl list-unit-files --type=service | grep -q "^$service_name.service"
}

# Get service status
get_service_status() {
    local service_name="$1"
    
    if service_exists "$service_name"; then
        if is_service_running "$service_name"; then
            echo "running"
        else
            echo "stopped"
        fi
    else
        echo "not_installed"
    fi
}

# Wait for service to stop
wait_for_service_stop() {
    local service_name="$1"
    local max_wait="${2:-60}"
    local wait_time=0
    
    while is_service_running "$service_name" && [[ $wait_time -lt $max_wait ]]; do
        sleep 1
        ((wait_time++))
    done
    
    if is_service_running "$service_name"; then
        log_error "Service $service_name failed to stop within $max_wait seconds"
        return 1
    fi
    
    return 0
}

################################################################################
# ERROR HANDLING
################################################################################

# Error trap function
error_handler() {
    local line_number="$1"
    local error_code="$2"
    local command="$3"
    
    log_error "Error on line $line_number: Command '$command' failed with exit code $error_code"
    print_error "An error occurred. Check the log file for details: ${NJORD_LOG_FILE:-$DEFAULT_LOG_PATH}"
}

# Set up error handling
setup_error_handling() {
    trap 'error_handler ${LINENO} $? "$BASH_COMMAND"' ERR
    set -E
}

################################################################################
# INITIALIZATION
################################################################################

# Initialize core library
init_core() {
    setup_error_handling
    init_logging
    log_info "Core library initialized - Version: $SCRIPT_VERSION"
}

# Auto-initialize when sourced
init_core
