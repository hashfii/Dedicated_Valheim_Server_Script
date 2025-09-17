#!/bin/bash
################################################################################
# Njord Menu UI Library
# Handles user interface, menus, and display functions
# Author: ZeroBandwidth & Team
# Version: 5.0-Odin
################################################################################

# Prevent double-sourcing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly" >&2
    exit 1
fi

# Source core library
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

################################################################################
# UI CONSTANTS
################################################################################

# Box drawing characters
readonly BOX_HORIZONTAL="─"
readonly BOX_VERTICAL="│"
readonly BOX_TOP_LEFT="┌"
readonly BOX_TOP_RIGHT="┐"
readonly BOX_BOTTOM_LEFT="└"
readonly BOX_BOTTOM_RIGHT="┘"
readonly BOX_CROSS="┼"
readonly BOX_T_UP="┴"
readonly BOX_T_DOWN="┬"
readonly BOX_T_LEFT="┤"
readonly BOX_T_RIGHT="├"

# Menu dimensions
readonly MENU_WIDTH=60
readonly MENU_PADDING=2

################################################################################
# DISPLAY FUNCTIONS
################################################################################

# Clear screen
clear_screen() {
    clear
}

# Print header
print_header() {
    local title="$1"
    local subtitle="${2:-}"
    
    clear_screen
    
    # Top border
    echo -n "$(print_cyan "$BOX_TOP_LEFT")"
    for ((i=0; i<MENU_WIDTH-2; i++)); do
        echo -n "$(print_cyan "$BOX_HORIZONTAL")"
    done
    echo "$(print_cyan "$BOX_TOP_RIGHT")"
    
    # Title
    local title_padding=$((MENU_WIDTH - ${#title} - 4))
    local left_padding=$((title_padding / 2))
    local right_padding=$((title_padding - left_padding))
    
    echo -n "$(print_cyan "$BOX_VERTICAL")"
    printf "%*s" $left_padding ""
    echo -n "$(print_white "$title")"
    printf "%*s" $right_padding ""
    echo "$(print_cyan "$BOX_VERTICAL")"
    
    # Subtitle
    if [[ -n "$subtitle" ]]; then
        local subtitle_padding=$((MENU_WIDTH - ${#subtitle} - 4))
        local left_padding=$((subtitle_padding / 2))
        local right_padding=$((subtitle_padding - left_padding))
        
        echo -n "$(print_cyan "$BOX_VERTICAL")"
        printf "%*s" $left_padding ""
        echo -n "$(print_yellow "$subtitle")"
        printf "%*s" $right_padding ""
        echo "$(print_cyan "$BOX_VERTICAL")"
    fi
    
    # Bottom border
    echo -n "$(print_cyan "$BOX_BOTTOM_LEFT")"
    for ((i=0; i<MENU_WIDTH-2; i++)); do
        echo -n "$(print_cyan "$BOX_HORIZONTAL")"
    done
    echo "$(print_cyan "$BOX_BOTTOM_RIGHT")"
    echo
}

# Print section header
print_section() {
    local title="$1"
    local width="${2:-$MENU_WIDTH}"
    
    echo
    echo -n "$(print_blue "╔")"
    for ((i=0; i<width-2; i++)); do
        echo -n "$(print_blue "═")"
    done
    echo "$(print_blue "╗")"
    
    local title_padding=$((width - ${#title} - 4))
    local left_padding=$((title_padding / 2))
    local right_padding=$((title_padding - left_padding))
    
    echo -n "$(print_blue "║")"
    printf "%*s" $left_padding ""
    echo -n "$(print_white "$title")"
    printf "%*s" $right_padding ""
    echo "$(print_blue "║")"
    
    echo -n "$(print_blue "╚")"
    for ((i=0; i<width-2; i++)); do
        echo -n "$(print_blue "═")"
    done
    echo "$(print_blue "╝")"
    echo
}

# Print separator line
print_separator() {
    local char="${1:-─}"
    local width="${2:-$MENU_WIDTH}"
    
    for ((i=0; i<width; i++)); do
        echo -n "$char"
    done
    echo
}

# Print menu item
print_menu_item() {
    local number="$1"
    local text="$2"
    local color="${3:-green}"
    
    printf "  $(print_$color "$number)") %s\n" "$text"
}

# Print status line
print_status() {
    local label="$1"
    local value="$2"
    local status="${3:-info}"
    local width="${4:-$MENU_WIDTH}"
    
    local label_width=25
    local value_width=$((width - label_width - 4))
    
    printf "  %-${label_width}s: " "$label"
    
    case "$status" in
        "success")
            printf "%-${value_width}s\n" "$(print_green "$value")"
            ;;
        "warning")
            printf "%-${value_width}s\n" "$(print_yellow "$value")"
            ;;
        "error")
            printf "%-${value_width}s\n" "$(print_red "$value")"
            ;;
        "info")
            printf "%-${value_width}s\n" "$(print_blue "$value")"
            ;;
        *)
            printf "%-${value_width}s\n" "$value"
            ;;
    esac
}

# Print progress bar
print_progress() {
    local current="$1"
    local total="$2"
    local width="${3:-40}"
    local label="${4:-Progress}"
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r  %s: [" "$label"
    
    # Filled portion
    for ((i=0; i<filled; i++)); do
        echo -n "$(print_green "█")"
    done
    
    # Empty portion
    for ((i=0; i<empty; i++)); do
        echo -n " "
    done
    
    printf "] %d%% (%d/%d)" "$percentage" "$current" "$total"
}

# Print confirmation dialog
print_confirm() {
    local message="$1"
    local default="${2:-n}"
    
    local prompt=""
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    echo
    print_warning "$message"
    read -p "  $prompt: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
        return 1
    else
        # Use default
        if [[ "$default" == "y" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Print input prompt
print_input() {
    local prompt="$1"
    local default="${2:-}"
    local secure="${3:-false}"
    
    local full_prompt="$prompt"
    if [[ -n "$default" ]]; then
        full_prompt="$prompt [$default]"
    fi
    
    echo -n "  $full_prompt: "
    
    if [[ "$secure" == "true" ]]; then
        read -s -r value
        echo
    else
        read -r value
    fi
    
    if [[ -z "$value" && -n "$default" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Print table header
print_table_header() {
    local columns=("$@")
    local width=$((MENU_WIDTH - 2))
    local col_width=$((width / ${#columns[@]}))
    
    echo -n "  $(print_cyan "┌")"
    for ((i=0; i<${#columns[@]}; i++)); do
        for ((j=0; j<col_width-1; j++)); do
            echo -n "$(print_cyan "─")"
        done
        if [[ $i -lt $((${#columns[@]}-1)) ]]; then
            echo -n "$(print_cyan "┬")"
        fi
    done
    echo "$(print_cyan "┐")"
    
    echo -n "  $(print_cyan "│")"
    for ((i=0; i<${#columns[@]}; i++)); do
        printf "%-${col_width}s" "${columns[$i]}"
        if [[ $i -lt $((${#columns[@]}-1)) ]]; then
            echo -n "$(print_cyan "│")"
        fi
    done
    echo "$(print_cyan "│")"
    
    echo -n "  $(print_cyan "├")"
    for ((i=0; i<${#columns[@]}; i++)); do
        for ((j=0; j<col_width-1; j++)); do
            echo -n "$(print_cyan "─")"
        done
        if [[ $i -lt $((${#columns[@]}-1)) ]]; then
            echo -n "$(print_cyan "┼")"
        fi
    done
    echo "$(print_cyan "┤")"
}

# Print table row
print_table_row() {
    local values=("$@")
    local width=$((MENU_WIDTH - 2))
    local col_width=$((width / ${#values[@]}))
    
    echo -n "  $(print_cyan "│")"
    for ((i=0; i<${#values[@]}; i++)); do
        printf "%-${col_width}s" "${values[$i]}"
        if [[ $i -lt $((${#values[@]}-1)) ]]; then
            echo -n "$(print_cyan "│")"
        fi
    done
    echo "$(print_cyan "│")"
}

# Print table footer
print_table_footer() {
    local columns=("$@")
    local width=$((MENU_WIDTH - 2))
    local col_width=$((width / ${#columns[@]}))
    
    echo -n "  $(print_cyan "└")"
    for ((i=0; i<${#columns[@]}; i++)); do
        for ((j=0; j<col_width-1; j++)); do
            echo -n "$(print_cyan "─")"
        done
        if [[ $i -lt $((${#columns[@]}-1)) ]]; then
            echo -n "$(print_cyan "┴")"
        fi
    done
    echo "$(print_cyan "┘")"
}

################################################################################
# MENU FUNCTIONS
################################################################################

# Display main menu
display_main_menu() {
    print_header "Njord Menu 5.0 - Odin" "Valheim Server Management System"
    
    echo "  $(print_cyan "╔══════════════════════════════════════════════════════════╗")"
    echo "  $(print_cyan "║") $(print_white "Server Management")                                    $(print_cyan "║")"
    echo "  $(print_cyan "╠══════════════════════════════════════════════════════════╣")"
    print_menu_item "1" "Install Valheim Server" "green"
    print_menu_item "2" "List Servers" "blue"
    print_menu_item "3" "Start Server" "green"
    print_menu_item "4" "Stop Server" "red"
    print_menu_item "5" "Restart Server" "yellow"
    print_menu_item "6" "Server Status" "blue"
    echo
    echo "  $(print_cyan "╠══════════════════════════════════════════════════════════╣")"
    echo "  $(print_cyan "║") $(print_white "Backup & Restore")                                    $(print_cyan "║")"
    echo "  $(print_cyan "╠══════════════════════════════════════════════════════════╣")"
    print_menu_item "7" "Create Backup" "green"
    print_menu_item "8" "Restore Backup" "yellow"
    print_menu_item "9" "List Backups" "blue"
    print_menu_item "10" "Backup All Worlds" "green"
    echo
    echo "  $(print_cyan "╠══════════════════════════════════════════════════════════╣")"
    echo "  $(print_cyan "║") $(print_white "System Management")                                   $(print_cyan "║")"
    echo "  $(print_cyan "╠══════════════════════════════════════════════════════════╣")"
    print_menu_item "11" "Update Valheim Server" "blue"
    print_menu_item "12" "System Information" "blue"
    print_menu_item "13" "Configuration" "yellow"
    print_menu_item "14" "Logs" "blue"
    echo
    echo "  $(print_cyan "╠══════════════════════════════════════════════════════════╣")"
    echo "  $(print_cyan "║") $(print_white "Advanced")                                           $(print_cyan "║")"
    echo "  $(print_cyan "╠══════════════════════════════════════════════════════════╣")"
    print_menu_item "15" "Mod Management" "purple"
    print_menu_item "16" "Firewall Management" "red"
    print_menu_item "17" "Maintenance" "yellow"
    echo
    echo "  $(print_cyan "╠══════════════════════════════════════════════════════════╣")"
    print_menu_item "0" "Exit" "red"
    echo "  $(print_cyan "╚══════════════════════════════════════════════════════════╝")"
    echo
}

# Display server status
display_server_status() {
    local world_name="$1"
    
    print_section "Server Status - $world_name"
    
    # Get service status
    local service_name="valheimserver_${world_name}"
    local status=$(get_service_status "$service_name")
    
    case "$status" in
        "running")
            print_status "Status" "Running" "success"
            ;;
        "stopped")
            print_status "Status" "Stopped" "warning"
            ;;
        "not_installed")
            print_status "Status" "Not Installed" "error"
            ;;
        *)
            print_status "Status" "Unknown" "error"
            ;;
    esac
    
    # Get service info
    if service_exists "$service_name"; then
        local service_file="/etc/systemd/system/${service_name}.service"
        if [[ -f "$service_file" ]]; then
            local working_dir=$(grep "^WorkingDirectory=" "$service_file" | cut -d'=' -f2)
            local exec_start=$(grep "^ExecStart=" "$service_file" | cut -d'=' -f2)
            
            print_status "Service File" "$service_file" "info"
            print_status "Working Directory" "$working_dir" "info"
        fi
    fi
    
    # Get recent logs
    echo
    print_section "Recent Logs"
    get_server_logs "$world_name" 10
}

# Display system information
display_system_info() {
    print_section "System Information"
    
    local info=$(get_system_info)
    echo "$info" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local key=$(echo "$line" | cut -d: -f1)
            local value=$(echo "$line" | cut -d: -f2- | sed 's/^ *//')
            print_status "$key" "$value" "info"
        fi
    done
}

# Display configuration
display_configuration() {
    print_section "Current Configuration"
    
    print_status "Valheim Install Path" "${valheim_install_path:-$DEFAULT_VALHEIM_PATH}" "info"
    print_status "World Path" "${world_path:-$DEFAULT_WORLD_PATH}" "info"
    print_status "Backup Path" "${backupPath:-$DEFAULT_BACKUP_PATH}" "info"
    print_status "Language" "${language:-EN}" "info"
    print_status "Log Level" "${log_level:-INFO}" "info"
    print_status "Use Firewall" "${use_firewall:-false}" "info"
    print_status "Firewall Type" "${firewall_type:-ufw}" "info"
    print_status "Debug Mode" "${debug_mode:-false}" "info"
}

# Display backup list
display_backup_list() {
    local world_name="$1"
    
    print_section "Backups - $world_name"
    
    local backup_path="${backupPath:-$DEFAULT_BACKUP_PATH}"
    local world_backup_dir="$backup_path/$world_name"
    
    if [[ ! -d "$world_backup_dir" ]]; then
        print_info "No backups found for world: $world_name"
        return 0
    fi
    
    # Get backup files
    local backups=()
    while IFS= read -r -d '' backup_file; do
        backups+=("$backup_file")
    done < <(find "$world_backup_dir" -name "*.tar.gz" -type f -print0 | sort -rz)
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        print_info "No backup files found for world: $world_name"
        return 0
    fi
    
    # Display table
    print_table_header "File Name" "Size" "Date" "Time"
    
    for backup_file in "${backups[@]}"; do
        local file_name=$(basename "$backup_file")
        local file_size=$(du -h "$backup_file" | cut -f1)
        local file_date=$(stat -c %y "$backup_file" | cut -d' ' -f1)
        local file_time=$(stat -c %y "$backup_file" | cut -d' ' -f2 | cut -d'.' -f1)
        
        print_table_row "$file_name" "$file_size" "$file_date" "$file_time"
    done
    
    print_table_footer "File Name" "Size" "Date" "Time"
}

# Display server list
display_server_list() {
    print_section "Installed Servers"
    
    local instances=($(get_server_instances))
    
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_info "No Valheim servers installed"
        return 0
    fi
    
    # Display table
    print_table_header "World Name" "Status" "Service" "Port"
    
    for world_name in "${instances[@]}"; do
        local status=$(get_server_status "$world_name")
        local service_name="valheimserver_${world_name}"
        local port="N/A"
        
        # Get port from service file
        local service_file="/etc/systemd/system/${service_name}.service"
        if [[ -f "$service_file" ]]; then
            local exec_start=$(grep "^ExecStart=" "$service_file" | cut -d'=' -f2)
            if [[ $exec_start =~ -port[[:space:]]+([0-9]+) ]]; then
                port="${BASH_REMATCH[1]}"
            fi
        fi
        
        case "$status" in
            "running")
                status="$(print_green "Running")"
                ;;
            "stopped")
                status="$(print_yellow "Stopped")"
                ;;
            "not_installed")
                status="$(print_red "Not Installed")"
                ;;
            *)
                status="$(print_red "Unknown")"
                ;;
        esac
        
        print_table_row "$world_name" "$status" "$service_name" "$port"
    done
    
    print_table_footer "World Name" "Status" "Service" "Port"
}

################################################################################
# INPUT FUNCTIONS
################################################################################

# Get menu selection
get_menu_selection() {
    local max_option="$1"
    local prompt="${2:-Choose an option:}"
    
    while true; do
        echo -n "  $prompt "
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 0 ]] && [[ $selection -le $max_option ]]; then
            echo "$selection"
            return 0
        else
            print_error "Invalid selection. Please enter a number between 0 and $max_option."
        fi
    done
}

# Get world name input
get_world_name() {
    local prompt="${1:-Enter world name:}"
    local min_length="${2:-4}"
    
    while true; do
        local world_name=$(print_input "$prompt")
        
        if validate_world_name "$world_name" "$min_length"; then
            echo "$world_name"
            return 0
        else
            print_error "Invalid world name. Must be at least $min_length characters and contain only letters and numbers."
        fi
    done
}

# Get server name input
get_server_name() {
    local prompt="${1:-Enter server name:}"
    
    while true; do
        local server_name=$(print_input "$prompt")
        
        if validate_server_name "$server_name"; then
            echo "$server_name"
            return 0
        else
            print_error "Invalid server name. Only letters, numbers, spaces, brackets, and basic punctuation allowed."
        fi
    done
}

# Get password input
get_password() {
    local prompt="${1:-Enter password:}"
    local min_length="${2:-6}"
    local secure="${3:-true}"
    
    while true; do
        local password=$(print_input "$prompt" "" "$secure")
        
        if validate_password "$password" "$min_length"; then
            echo "$password"
            return 0
        else
            print_error "Invalid password. Must be at least $min_length characters with uppercase, lowercase, and numbers."
        fi
    done
}

# Get port input
get_port() {
    local prompt="${1:-Enter port number:}"
    local default="${2:-2456}"
    
    while true; do
        local port=$(print_input "$prompt" "$default")
        
        if validate_port "$port"; then
            echo "$port"
            return 0
        else
            print_error "Invalid port number. Must be between 1024 and 65535."
        fi
    done
}

# Wait for user input
wait_for_input() {
    local message="${1:-Press Enter to continue...}"
    echo
    read -p "  $message" -r
}
