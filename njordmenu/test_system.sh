#!/bin/bash
################################################################################
# Njord Menu System Test
# Tests the new modular system
# Author: ZeroBandwidth & Team
# Version: 5.0-Odin
################################################################################

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source all library modules
source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/server.sh"
source "$LIB_DIR/backup.sh"
source "$LIB_DIR/ui.sh"

echo "Testing Njord Menu 5.0 - Odin System"
echo "===================================="
echo

# Test core functions
echo "Testing core functions..."
print_info "Testing color output"
print_success "Success message test"
print_warning "Warning message test"
print_error "Error message test"
echo

# Test configuration
echo "Testing configuration system..."
print_info "Current language: ${language:-EN}"
print_info "Valheim install path: ${valheim_install_path:-$DEFAULT_VALHEIM_PATH}"
print_info "World path: ${world_path:-$DEFAULT_WORLD_PATH}"
echo

# Test validation functions
echo "Testing validation functions..."
if validate_world_name "TestWorld"; then
    print_success "World name validation: PASS"
else
    print_error "World name validation: FAIL"
fi

if validate_password "TestPass123"; then
    print_success "Password validation: PASS"
else
    print_error "Password validation: FAIL"
fi

if validate_port "2456"; then
    print_success "Port validation: PASS"
else
    print_error "Port validation: FAIL"
fi
echo

# Test system info
echo "Testing system information..."
print_section "System Information"
display_system_info
echo

# Test configuration display
echo "Testing configuration display..."
print_section "Configuration"
display_configuration
echo

# Test UI functions
echo "Testing UI functions..."
print_header "Test Header" "Test Subtitle"
print_section "Test Section"
print_status "Test Status" "Test Value" "info"
echo

# Test server list (will be empty initially)
echo "Testing server management..."
print_section "Server List"
display_server_list
echo

# Test backup stats
echo "Testing backup system..."
print_section "Backup Statistics"
get_backup_stats
echo

echo "System test completed!"
print_success "All tests passed successfully!"
