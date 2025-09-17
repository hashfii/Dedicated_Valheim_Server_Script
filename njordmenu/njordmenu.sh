#!/bin/bash
################################################################################
# Njord Menu 5.0 - Odin
# Valheim Server Management System
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

################################################################################
# MAIN FUNCTIONS
################################################################################

# Main menu handler
main_menu() {
    while true; do
        display_main_menu
        local selection=$(get_menu_selection 17)
        
        case "$selection" in
            1) install_server_menu ;;
            2) list_servers_menu ;;
            3) start_server_menu ;;
            4) stop_server_menu ;;
            5) restart_server_menu ;;
            6) server_status_menu ;;
            7) create_backup_menu ;;
            8) restore_backup_menu ;;
            9) list_backups_menu ;;
            10) backup_all_menu ;;
            11) update_server_menu ;;
            12) system_info_menu ;;
            13) configuration_menu ;;
            14) logs_menu ;;
            15) mod_management_menu ;;
            16) firewall_menu ;;
            17) maintenance_menu ;;
            0) exit_menu ;;
            *) print_error "Invalid selection" ;;
        esac
        
        if [[ "$selection" -ne 0 ]]; then
            wait_for_input
        fi
    done
}

# Install server menu
install_server_menu() {
    print_header "Install Valheim Server"
    
    # Get server details
    local world_name=$(get_world_name)
    local server_name=$(get_server_name)
    local server_password=$(get_password "Enter server password")
    local port=$(get_port "Enter server port" "${default_port:-2456}")
    
    # Public listing
    echo
    if print_confirm "Make server publicly visible?" "n"; then
        local public_listing="1"
    else
        local public_listing="0"
    fi
    
    # Confirm installation
    echo
    print_warning "You are about to install a Valheim server with the following settings:"
    print_status "World Name" "$world_name" "info"
    print_status "Server Name" "$server_name" "info"
    print_status "Port" "$port" "info"
    print_status "Public Listing" "$public_listing" "info"
    
    if print_confirm "Continue with installation?" "y"; then
        print_info "Installing Valheim server..."
        if install_valheim_server "$world_name" "$server_name" "$server_password" "$public_listing" "$port"; then
            print_success "Valheim server installed successfully!"
        else
            print_error "Valheim server installation failed!"
        fi
    else
        print_info "Installation cancelled"
    fi
}

# List servers menu
list_servers_menu() {
    print_header "Server List"
    display_server_list
}

# Start server menu
start_server_menu() {
    print_header "Start Valheim Server"
    
    local instances=($(get_server_instances))
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_error "No servers installed"
        return 1
    fi
    
    echo "Available servers:"
    for i in "${!instances[@]}"; do
        local world_name="${instances[$i]}"
        local status=$(get_server_status "$world_name")
        printf "  %2d) %s (%s)\n" $((i+1)) "$world_name" "$status"
    done
    
    local selection=$(get_menu_selection ${#instances[@]} "Select server to start")
    local world_name="${instances[$((selection-1))]}"
    
    print_info "Starting server: $world_name"
    if start_valheim_service "$world_name"; then
        print_success "Server started successfully!"
    else
        print_error "Failed to start server!"
    fi
}

# Stop server menu
stop_server_menu() {
    print_header "Stop Valheim Server"
    
    local instances=($(get_server_instances))
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_error "No servers installed"
        return 1
    fi
    
    echo "Available servers:"
    for i in "${!instances[@]}"; do
        local world_name="${instances[$i]}"
        local status=$(get_server_status "$world_name")
        printf "  %2d) %s (%s)\n" $((i+1)) "$world_name" "$status"
    done
    
    local selection=$(get_menu_selection ${#instances[@]} "Select server to stop")
    local world_name="${instances[$((selection-1))]}"
    
    print_info "Stopping server: $world_name"
    if stop_valheim_service "$world_name"; then
        print_success "Server stopped successfully!"
    else
        print_error "Failed to stop server!"
    fi
}

# Restart server menu
restart_server_menu() {
    print_header "Restart Valheim Server"
    
    local instances=($(get_server_instances))
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_error "No servers installed"
        return 1
    fi
    
    echo "Available servers:"
    for i in "${!instances[@]}"; do
        local world_name="${instances[$i]}"
        local status=$(get_server_status "$world_name")
        printf "  %2d) %s (%s)\n" $((i+1)) "$world_name" "$status"
    done
    
    local selection=$(get_menu_selection ${#instances[@]} "Select server to restart")
    local world_name="${instances[$((selection-1))]}"
    
    print_info "Restarting server: $world_name"
    if restart_valheim_service "$world_name"; then
        print_success "Server restarted successfully!"
    else
        print_error "Failed to restart server!"
    fi
}

# Server status menu
server_status_menu() {
    print_header "Server Status"
    
    local instances=($(get_server_instances))
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_error "No servers installed"
        return 1
    fi
    
    echo "Available servers:"
    for i in "${!instances[@]}"; do
        local world_name="${instances[$i]}"
        local status=$(get_server_status "$world_name")
        printf "  %2d) %s (%s)\n" $((i+1)) "$world_name" "$status"
    done
    
    local selection=$(get_menu_selection ${#instances[@]} "Select server to view status")
    local world_name="${instances[$((selection-1))]}"
    
    display_server_status "$world_name"
}

# Create backup menu
create_backup_menu() {
    print_header "Create Backup"
    
    local instances=($(get_server_instances))
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_error "No servers installed"
        return 1
    fi
    
    echo "Available servers:"
    for i in "${!instances[@]}"; do
        local world_name="${instances[$i]}"
        local status=$(get_server_status "$world_name")
        printf "  %2d) %s (%s)\n" $((i+1)) "$world_name" "$status"
    done
    
    local selection=$(get_menu_selection ${#instances[@]} "Select server to backup")
    local world_name="${instances[$((selection-1))]}"
    
    print_info "Creating backup for world: $world_name"
    if create_backup "$world_name"; then
        print_success "Backup created successfully!"
    else
        print_error "Backup creation failed!"
    fi
}

# Restore backup menu
restore_backup_menu() {
    print_header "Restore Backup"
    
    local instances=($(get_server_instances))
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_error "No servers installed"
        return 1
    fi
    
    echo "Available servers:"
    for i in "${!instances[@]}"; do
        local world_name="${instances[$i]}"
        local status=$(get_server_status "$world_name")
        printf "  %2d) %s (%s)\n" $((i+1)) "$world_name" "$status"
    done
    
    local selection=$(get_menu_selection ${#instances[@]} "Select server to restore")
    local world_name="${instances[$((selection-1))]}"
    
    if interactive_backup_restore "$world_name"; then
        print_success "Backup restored successfully!"
    else
        print_error "Backup restore failed!"
    fi
}

# List backups menu
list_backups_menu() {
    print_header "List Backups"
    
    local instances=($(get_server_instances))
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_error "No servers installed"
        return 1
    fi
    
    echo "Available servers:"
    for i in "${!instances[@]}"; do
        local world_name="${instances[$i]}"
        printf "  %2d) %s\n" $((i+1)) "$world_name"
    done
    
    local selection=$(get_menu_selection ${#instances[@]} "Select server to view backups")
    local world_name="${instances[$((selection-1))]}"
    
    display_backup_list "$world_name"
}

# Backup all menu
backup_all_menu() {
    print_header "Backup All Worlds"
    
    if print_confirm "This will backup all installed worlds. Continue?" "y"; then
        print_info "Starting backup of all worlds..."
        if backup_all_worlds; then
            print_success "All worlds backed up successfully!"
        else
            print_warning "Some backups failed. Check the logs for details."
        fi
    else
        print_info "Backup cancelled"
    fi
}

# Update server menu
update_server_menu() {
    print_header "Update Valheim Server"
    
    local instances=($(get_server_instances))
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_error "No servers installed"
        return 1
    fi
    
    echo "Available servers:"
    for i in "${!instances[@]}"; do
        local world_name="${instances[$i]}"
        local status=$(get_server_status "$world_name")
        printf "  %2d) %s (%s)\n" $((i+1)) "$world_name" "$status"
    done
    
    local selection=$(get_menu_selection ${#instances[@]} "Select server to update")
    local world_name="${instances[$((selection-1))]}"
    
    print_info "Updating server: $world_name"
    if update_valheim_server "$world_name"; then
        print_success "Server updated successfully!"
    else
        print_error "Server update failed!"
    fi
}

# System info menu
system_info_menu() {
    print_header "System Information"
    display_system_info
}

# Configuration menu
configuration_menu() {
    print_header "Configuration"
    display_configuration
    
    echo
    if print_confirm "Do you want to edit configuration?" "n"; then
        print_info "Configuration editing not yet implemented"
    fi
}

# Logs menu
logs_menu() {
    print_header "Server Logs"
    
    local instances=($(get_server_instances))
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_error "No servers installed"
        return 1
    fi
    
    echo "Available servers:"
    for i in "${!instances[@]}"; do
        local world_name="${instances[$i]}"
        local status=$(get_server_status "$world_name")
        printf "  %2d) %s (%s)\n" $((i+1)) "$world_name" "$status"
    done
    
    local selection=$(get_menu_selection ${#instances[@]} "Select server to view logs")
    local world_name="${instances[$((selection-1))]}"
    
    print_section "Recent Logs - $world_name"
    get_server_logs "$world_name" 50
}

# Mod management menu
mod_management_menu() {
    print_header "Mod Management"
    print_info "Mod management not yet implemented in the new architecture"
    print_info "This feature will be available in a future update"
}

# Firewall menu
firewall_menu() {
    print_header "Firewall Management"
    print_info "Firewall management not yet implemented in the new architecture"
    print_info "This feature will be available in a future update"
}

# Maintenance menu
maintenance_menu() {
    print_header "Maintenance"
    
    echo "Maintenance options:"
    print_menu_item "1" "Clean old backups" "yellow"
    print_menu_item "2" "System cleanup" "yellow"
    print_menu_item "3" "Check disk space" "blue"
    print_menu_item "4" "View backup statistics" "blue"
    print_menu_item "0" "Back to main menu" "red"
    
    local selection=$(get_menu_selection 4)
    
    case "$selection" in
        1) 
            print_info "Cleaning old backups..."
            local instances=($(get_server_instances))
            for world_name in "${instances[@]}"; do
                clean_old_backups "$world_name"
            done
            print_success "Old backups cleaned!"
            ;;
        2)
            print_info "System cleanup not yet implemented"
            ;;
        3)
            print_info "Checking disk space..."
            df -h
            ;;
        4)
            print_info "Backup statistics:"
            get_backup_stats
            ;;
        0)
            return 0
            ;;
    esac
}

# Exit menu
exit_menu() {
    print_header "Exit"
    print_info "Thank you for using Njord Menu!"
    print_info "Happy gaming - ZeroBandwidth & Team"
    exit 0
}

################################################################################
# COMMAND LINE INTERFACE
################################################################################

# Handle command line arguments
handle_cli() {
    case "${1:-}" in
        "install")
            install_server_menu
            ;;
        "start")
            if [[ -n "${2:-}" ]]; then
                start_valheim_service "$2"
            else
                start_server_menu
            fi
            ;;
        "stop")
            if [[ -n "${2:-}" ]]; then
                stop_valheim_service "$2"
            else
                stop_server_menu
            fi
            ;;
        "restart")
            if [[ -n "${2:-}" ]]; then
                restart_valheim_service "$2"
            else
                restart_server_menu
            fi
            ;;
        "status")
            if [[ -n "${2:-}" ]]; then
                display_server_status "$2"
            else
                server_status_menu
            fi
            ;;
        "backup")
            if [[ -n "${2:-}" ]]; then
                create_backup "$2"
            else
                create_backup_menu
            fi
            ;;
        "restore")
            if [[ -n "${2:-}" ]]; then
                interactive_backup_restore "$2"
            else
                restore_backup_menu
            fi
            ;;
        "backup-all")
            backup_all_worlds
            ;;
        "list")
            display_server_list
            ;;
        "logs")
            if [[ -n "${2:-}" ]]; then
                get_server_logs "$2" 50
            else
                logs_menu
            fi
            ;;
        "update")
            if [[ -n "${2:-}" ]]; then
                update_valheim_server "$2"
            else
                update_server_menu
            fi
            ;;
        "info")
            display_system_info
            ;;
        "config")
            display_configuration
            ;;
        "help"|"-h"|"--help")
            print_header "Njord Menu Help"
            echo "Usage: $0 [command] [options]"
            echo
            echo "Commands:"
            echo "  install              Install a new Valheim server"
            echo "  start [world]        Start a Valheim server"
            echo "  stop [world]         Stop a Valheim server"
            echo "  restart [world]      Restart a Valheim server"
            echo "  status [world]       Show server status"
            echo "  backup [world]       Create a backup"
            echo "  restore [world]      Restore from backup"
            echo "  backup-all           Backup all worlds"
            echo "  list                 List all servers"
            echo "  logs [world]         Show server logs"
            echo "  update [world]       Update Valheim server"
            echo "  info                 Show system information"
            echo "  config               Show configuration"
            echo "  help                 Show this help message"
            echo
            echo "If no command is provided, the interactive menu will start."
            ;;
        *)
            # No command provided, start interactive menu
            main_menu
            ;;
    esac
}

################################################################################
# MAIN EXECUTION
################################################################################

# Check if running as root
check_root

# Load language
load_language "${language:-EN}"

# Handle command line arguments or start interactive menu
handle_cli "$@"
