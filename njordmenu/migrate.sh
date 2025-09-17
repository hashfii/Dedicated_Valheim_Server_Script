#!/bin/bash
################################################################################
# Njord Menu Migration Script
# Migrates from old monolithic script to new modular system
# Author: ZeroBandwidth & Team
# Version: 5.0-Odin
################################################################################

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLD_SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"

# Source core library
source "$SCRIPT_DIR/lib/core.sh"

################################################################################
# MIGRATION FUNCTIONS
################################################################################

# Check if old system exists
check_old_system() {
    local old_script="$OLD_SCRIPT_DIR/njordmenu.sh"
    
    if [[ -f "$old_script" ]]; then
        print_info "Old Njord Menu found: $old_script"
        return 0
    else
        print_error "Old Njord Menu not found: $old_script"
        return 1
    fi
}

# Backup old system
backup_old_system() {
    local backup_dir="$OLD_SCRIPT_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    
    print_info "Creating backup of old system..."
    
    mkdir -p "$backup_dir"
    
    # Backup old files
    if [[ -f "$OLD_SCRIPT_DIR/njordmenu.sh" ]]; then
        cp "$OLD_SCRIPT_DIR/njordmenu.sh" "$backup_dir/"
        print_success "Backed up old njordmenu.sh"
    fi
    
    if [[ -f "$OLD_SCRIPT_DIR/config.conf" ]]; then
        cp "$OLD_SCRIPT_DIR/config.conf" "$backup_dir/"
        print_success "Backed up old config.conf"
    fi
    
    if [[ -f "$OLD_SCRIPT_DIR/valheim_backup.sh" ]]; then
        cp "$OLD_SCRIPT_DIR/valheim_backup.sh" "$backup_dir/"
        print_success "Backed up old valheim_backup.sh"
    fi
    
    # Backup lang directory
    if [[ -d "$OLD_SCRIPT_DIR/lang" ]]; then
        cp -r "$OLD_SCRIPT_DIR/lang" "$backup_dir/"
        print_success "Backed up lang directory"
    fi
    
    print_success "Old system backed up to: $backup_dir"
    echo "$backup_dir"
}

# Migrate configuration
migrate_configuration() {
    local old_config="$OLD_SCRIPT_DIR/config.conf"
    local new_config_dir="/etc/njordmenu"
    
    print_info "Migrating configuration..."
    
    if [[ -f "$old_config" ]]; then
        # Create new config directory
        mkdir -p "$new_config_dir"
        
        # Read old config and convert to new format
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Remove quotes and clean value
            value=$(echo "$value" | sed 's/^"//;s/"$//')
            
            # Map old config keys to new ones
            case "$key" in
                "valheimInstallPath")
                    echo "valheim_install_path=\"$value\"" >> "$new_config_dir/njordmenu.conf"
                    ;;
                "backupPath")
                    echo "backup_path=\"$value\"" >> "$new_config_dir/njordmenu.conf"
                    ;;
                "logFilePath")
                    echo "log_file=\"$value\"" >> "$new_config_dir/njordmenu.conf"
                    ;;
                "defaultServerPort")
                    echo "default_port=\"$value\"" >> "$new_config_dir/servers.conf"
                    ;;
                "defaultPublicVisibility")
                    echo "default_public=\"$value\"" >> "$new_config_dir/servers.conf"
                    ;;
                "passwordRequirement")
                    # Skip regex patterns, not needed in new system
                    ;;
                "updateCheckFrequency")
                    # Skip, not used in new system
                    ;;
                *)
                    # Add unknown keys as comments
                    echo "# $key=\"$value\"" >> "$new_config_dir/njordmenu.conf"
                    ;;
            esac
        done < "$old_config"
        
        chmod 644 "$new_config_dir/njordmenu.conf"
        print_success "Configuration migrated successfully"
    else
        print_warning "No old configuration found, using defaults"
    fi
}

# Migrate language files
migrate_language_files() {
    local old_lang_dir="$OLD_SCRIPT_DIR/lang"
    local new_lang_dir="$SCRIPT_DIR/lang"
    
    print_info "Migrating language files..."
    
    if [[ -d "$old_lang_dir" ]]; then
        # Copy language files to new location
        cp -r "$old_lang_dir"/* "$new_lang_dir/" 2>/dev/null || true
        print_success "Language files migrated successfully"
    else
        print_warning "No language files found to migrate"
    fi
}

# Migrate existing servers
migrate_servers() {
    local worlds_file="/home/steam/worlds.txt"
    local new_worlds_file="${worlds_file}"
    
    print_info "Migrating existing servers..."
    
    if [[ -f "$worlds_file" ]]; then
        # Worlds file already exists, just verify it's accessible
        print_success "Existing worlds file found: $worlds_file"
        
        # Display existing worlds
        local instances=($(get_server_instances))
        if [[ ${#instances[@]} -gt 0 ]]; then
            print_info "Found existing servers:"
            for world_name in "${instances[@]}"; do
                local status=$(get_server_status "$world_name")
                print_status "  $world_name" "$status" "info"
            done
        fi
    else
        print_warning "No existing worlds file found"
    fi
}

# Create symlink for backward compatibility
create_symlink() {
    local old_script="$OLD_SCRIPT_DIR/njordmenu.sh"
    local new_script="$SCRIPT_DIR/njordmenu.sh"
    
    print_info "Creating backward compatibility symlink..."
    
    if [[ -f "$old_script" ]]; then
        # Backup old script
        mv "$old_script" "${old_script}.old"
        print_success "Old script backed up as ${old_script}.old"
    fi
    
    # Create symlink
    ln -sf "$new_script" "$old_script"
    print_success "Created symlink: $old_script -> $new_script"
}

# Test new system
test_new_system() {
    print_info "Testing new system..."
    
    # Run test script
    if [[ -f "$SCRIPT_DIR/test_system.sh" ]]; then
        bash "$SCRIPT_DIR/test_system.sh"
        if [[ $? -eq 0 ]]; then
            print_success "New system test passed!"
        else
            print_error "New system test failed!"
            return 1
        fi
    else
        print_warning "Test script not found, skipping test"
    fi
}

# Main migration function
migrate() {
    print_header "Njord Menu Migration" "From 4.0-Thor to 5.0-Odin"
    
    # Check if old system exists
    if ! check_old_system; then
        print_error "Cannot migrate: Old system not found"
        exit 1
    fi
    
    # Confirm migration
    print_warning "This will migrate your Njord Menu from version 4.0-Thor to 5.0-Odin"
    print_warning "The old system will be backed up before migration"
    echo
    
    if ! print_confirm "Do you want to continue with the migration?" "n"; then
        print_info "Migration cancelled"
        exit 0
    fi
    
    echo
    print_info "Starting migration process..."
    echo
    
    # Step 1: Backup old system
    print_section "Step 1: Backup Old System"
    local backup_dir=$(backup_old_system)
    echo
    
    # Step 2: Migrate configuration
    print_section "Step 2: Migrate Configuration"
    migrate_configuration
    echo
    
    # Step 3: Migrate language files
    print_section "Step 3: Migrate Language Files"
    migrate_language_files
    echo
    
    # Step 4: Migrate existing servers
    print_section "Step 4: Migrate Existing Servers"
    migrate_servers
    echo
    
    # Step 5: Create symlink
    print_section "Step 5: Create Backward Compatibility"
    create_symlink
    echo
    
    # Step 6: Test new system
    print_section "Step 6: Test New System"
    test_new_system
    echo
    
    # Migration complete
    print_section "Migration Complete"
    print_success "Migration completed successfully!"
    print_info "Old system backed up to: $backup_dir"
    print_info "New system is ready to use!"
    echo
    print_info "You can now run: ./njordmenu.sh"
    print_info "Or use the old command: ./njordmenu.sh (now points to new system)"
    echo
    print_warning "Please test the new system thoroughly before removing the backup!"
}

# Show help
show_help() {
    print_header "Njord Menu Migration Help"
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  migrate    Run the migration process"
    echo "  test       Test the new system only"
    echo "  help       Show this help message"
    echo
    echo "The migration process will:"
    echo "  1. Backup your old Njord Menu system"
    echo "  2. Migrate configuration files"
    echo "  3. Migrate language files"
    echo "  4. Migrate existing server configurations"
    echo "  5. Create backward compatibility symlink"
    echo "  6. Test the new system"
    echo
    echo "After migration, you can use either:"
    echo "  ./njordmenu.sh (new system)"
    echo "  ./njordmenu.sh (old command, now points to new system)"
}

################################################################################
# MAIN EXECUTION
################################################################################

case "${1:-migrate}" in
    "migrate")
        migrate
        ;;
    "test")
        test_new_system
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
