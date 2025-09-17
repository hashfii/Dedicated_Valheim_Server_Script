#!/bin/bash
################################################################################
# Njord Menu Configuration Management
# Handles all configuration loading, saving, and validation
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
# CONFIGURATION VARIABLES
################################################################################

# Configuration file paths
readonly CONFIG_DIR="/etc/njordmenu"
readonly MAIN_CONFIG_FILE="$CONFIG_DIR/njordmenu.conf"
readonly SERVER_CONFIG_FILE="$CONFIG_DIR/servers.conf"
readonly LANGUAGE_CONFIG_FILE="$CONFIG_DIR/language.conf"

# Default configuration values
declare -A DEFAULT_CONFIG=(
    ["valheim_install_path"]="/home/steam/valheimserver"
    ["world_path"]="/home/steam/.config/unity3d/IronGate/Valheim"
    ["backup_path"]="/home/steam/backups"
    ["worlds_file"]="/home/steam/worlds.txt"
    ["log_file"]="/var/log/njordmenu.log"
    ["log_level"]="INFO"
    ["language"]="EN"
    ["use_firewall"]="false"
    ["firewall_type"]="ufw"
    ["fresh_install"]="false"
    ["debug_mode"]="false"
)

# Server configuration defaults
declare -A DEFAULT_SERVER_CONFIG=(
    ["default_port"]="2456"
    ["default_public"]="1"
    ["password_min_length"]="6"
    ["world_name_min_length"]="4"
    ["backup_retention_days"]="14"
    ["max_wait_time"]="60"
)

# Language configuration
declare -A LANGUAGE_CONFIG=(
    ["EN"]="English"
    ["DE"]="German"
    ["FR"]="French"
    ["SP"]="Spanish"
    ["RU"]="Russian"
    ["DA"]="Danish"
    ["DU"]="Dutch"
    ["RO"]="Romanian"
    ["SE"]="Swedish"
)

################################################################################
# CONFIGURATION FUNCTIONS
################################################################################

# Initialize configuration system
init_config() {
    log_info "Initializing configuration system"
    
    # Create configuration directory
    create_dir "$CONFIG_DIR" "root" "755"
    
    # Load main configuration
    load_main_config
    
    # Load server configuration
    load_server_config
    
    # Load language configuration
    load_language_config
    
    log_info "Configuration system initialized"
}

# Load main configuration
load_main_config() {
    if [[ -f "$MAIN_CONFIG_FILE" ]]; then
        log_debug "Loading main configuration from $MAIN_CONFIG_FILE"
        source "$MAIN_CONFIG_FILE"
    else
        log_info "Main configuration file not found, creating with defaults"
        create_default_main_config
    fi
}

# Create default main configuration
create_default_main_config() {
    cat > "$MAIN_CONFIG_FILE" << EOF
# Njord Menu Main Configuration
# Generated on $(date)

# Paths
valheim_install_path="${DEFAULT_CONFIG[valheim_install_path]}"
world_path="${DEFAULT_CONFIG[world_path]}"
backup_path="${DEFAULT_CONFIG[backup_path]}"
worlds_file="${DEFAULT_CONFIG[worlds_file]}"
log_file="${DEFAULT_CONFIG[log_file]}"

# Settings
log_level="${DEFAULT_CONFIG[log_level]}"
language="${DEFAULT_CONFIG[language]}"
use_firewall="${DEFAULT_CONFIG[use_firewall]}"
firewall_type="${DEFAULT_CONFIG[firewall_type]}"
fresh_install="${DEFAULT_CONFIG[fresh_install]}"
debug_mode="${DEFAULT_CONFIG[debug_mode]}"
EOF
    
    chmod 644 "$MAIN_CONFIG_FILE"
    log_info "Created default main configuration file"
}

# Load server configuration
load_server_config() {
    if [[ -f "$SERVER_CONFIG_FILE" ]]; then
        log_debug "Loading server configuration from $SERVER_CONFIG_FILE"
        source "$SERVER_CONFIG_FILE"
    else
        log_info "Server configuration file not found, creating with defaults"
        create_default_server_config
    fi
}

# Create default server configuration
create_default_server_config() {
    cat > "$SERVER_CONFIG_FILE" << EOF
# Njord Menu Server Configuration
# Generated on $(date)

# Server defaults
default_port="${DEFAULT_SERVER_CONFIG[default_port]}"
default_public="${DEFAULT_SERVER_CONFIG[default_public]}"
password_min_length="${DEFAULT_SERVER_CONFIG[password_min_length]}"
world_name_min_length="${DEFAULT_SERVER_CONFIG[world_name_min_length]}"
backup_retention_days="${DEFAULT_SERVER_CONFIG[backup_retention_days]}"
max_wait_time="${DEFAULT_SERVER_CONFIG[max_wait_time]}"
EOF
    
    chmod 644 "$SERVER_CONFIG_FILE"
    log_info "Created default server configuration file"
}

# Load language configuration
load_language_config() {
    if [[ -f "$LANGUAGE_CONFIG_FILE" ]]; then
        log_debug "Loading language configuration from $LANGUAGE_CONFIG_FILE"
        source "$LANGUAGE_CONFIG_FILE"
    else
        log_info "Language configuration file not found, creating with defaults"
        create_default_language_config
    fi
}

# Create default language configuration
create_default_language_config() {
    cat > "$LANGUAGE_CONFIG_FILE" << EOF
# Njord Menu Language Configuration
# Generated on $(date)

# Available languages
EOF
    
    for lang_code in "${!LANGUAGE_CONFIG[@]}"; do
        echo "language_${lang_code}=\"${LANGUAGE_CONFIG[$lang_code]}\"" >> "$LANGUAGE_CONFIG_FILE"
    done
    
    chmod 644 "$LANGUAGE_CONFIG_FILE"
    log_info "Created default language configuration file"
}

# Get configuration value
get_config() {
    local key="$1"
    local default_value="${2:-}"
    
    if [[ -n "${!key:-}" ]]; then
        echo "${!key}"
    else
        echo "$default_value"
    fi
}

# Set configuration value
set_config() {
    local key="$1"
    local value="$2"
    local config_file="${3:-$MAIN_CONFIG_FILE}"
    
    # Update the variable
    declare -g "$key"="$value"
    
    # Update the config file
    if [[ -f "$config_file" ]]; then
        if grep -q "^$key=" "$config_file"; then
            sed -i "s/^$key=.*/$key=\"$value\"/" "$config_file"
        else
            echo "$key=\"$value\"" >> "$config_file"
        fi
        log_debug "Updated configuration: $key=$value"
    else
        log_error "Configuration file not found: $config_file"
        return 1
    fi
}

# Validate configuration
validate_config() {
    local errors=0
    
    log_info "Validating configuration"
    
    # Check required paths
    local required_paths=("valheim_install_path" "world_path" "backup_path")
    for path_var in "${required_paths[@]}"; do
        local path_value="${!path_var:-}"
        if [[ -z "$path_value" ]]; then
            log_error "Required configuration missing: $path_var"
            ((errors++))
        fi
    done
    
    # Check language
    local current_lang="${language:-EN}"
    if [[ -z "${LANGUAGE_CONFIG[$current_lang]:-}" ]]; then
        log_error "Invalid language: $current_lang"
        ((errors++))
    fi
    
    # Check firewall type
    local fw_type="${firewall_type:-ufw}"
    local valid_fw_types=("ufw" "firewalld" "iptables" "none")
    if [[ ! " ${valid_fw_types[@]} " =~ " $fw_type " ]]; then
        log_error "Invalid firewall type: $fw_type"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_info "Configuration validation passed"
        return 0
    else
        log_error "Configuration validation failed with $errors errors"
        return 1
    fi
}

# Load language file
load_language() {
    local lang="${1:-${language:-EN}}"
    local lang_file="$(dirname "${BASH_SOURCE[0]}")/../lang/${lang}.conf"
    
    if [[ -f "$lang_file" ]]; then
        log_debug "Loading language file: $lang_file"
        source "$lang_file"
        log_info "Language loaded: ${LANGUAGE_CONFIG[$lang]:-$lang}"
    else
        log_error "Language file not found: $lang_file"
        return 1
    fi
}

# Get available languages
get_available_languages() {
    local lang_dir="$(dirname "${BASH_SOURCE[0]}")/../lang"
    local languages=()
    
    if [[ -d "$lang_dir" ]]; then
        for lang_file in "$lang_dir"/*.conf; do
            if [[ -f "$lang_file" ]]; then
                local lang_code=$(basename "$lang_file" .conf)
                languages+=("$lang_code")
            fi
        done
    fi
    
    printf '%s\n' "${languages[@]}"
}

# Save current configuration
save_config() {
    log_info "Saving current configuration"
    
    # Save main config
    if [[ -f "$MAIN_CONFIG_FILE" ]]; then
        # Update all current variables in the file
        for key in "${!DEFAULT_CONFIG[@]}"; do
            if [[ -n "${!key:-}" ]]; then
                set_config "$key" "${!key}" "$MAIN_CONFIG_FILE"
            fi
        done
    fi
    
    log_info "Configuration saved successfully"
}

# Reset configuration to defaults
reset_config() {
    log_info "Resetting configuration to defaults"
    
    # Remove existing config files
    rm -f "$MAIN_CONFIG_FILE" "$SERVER_CONFIG_FILE" "$LANGUAGE_CONFIG_FILE"
    
    # Recreate with defaults
    create_default_main_config
    create_default_server_config
    create_default_language_config
    
    # Reload configuration
    load_main_config
    load_server_config
    load_language_config
    
    log_info "Configuration reset to defaults"
}

# Export configuration for other scripts
export_config() {
    local output_file="${1:-/tmp/njordmenu_config.sh}"
    
    log_info "Exporting configuration to $output_file"
    
    cat > "$output_file" << EOF
#!/bin/bash
# Njord Menu Configuration Export
# Generated on $(date)

EOF
    
    # Export main configuration
    for key in "${!DEFAULT_CONFIG[@]}"; do
        if [[ -n "${!key:-}" ]]; then
            echo "export $key=\"${!key}\"" >> "$output_file"
        fi
    done
    
    # Export server configuration
    for key in "${!DEFAULT_SERVER_CONFIG[@]}"; do
        if [[ -n "${!key:-}" ]]; then
            echo "export $key=\"${!key}\"" >> "$output_file"
        fi
    done
    
    chmod 644 "$output_file"
    log_info "Configuration exported to $output_file"
}

################################################################################
# SERVER INSTANCE MANAGEMENT
################################################################################

# Get server instances
get_server_instances() {
    local instances=()
    
    if [[ -f "${worlds_file:-${DEFAULT_CONFIG[worlds_file]}}" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" && ! "$line" =~ ^# ]] && instances+=("$line")
        done < "${worlds_file:-${DEFAULT_CONFIG[worlds_file]}}"
    fi
    
    printf '%s\n' "${instances[@]}"
}

# Add server instance
add_server_instance() {
    local world_name="$1"
    local worlds_file="${worlds_file:-${DEFAULT_CONFIG[worlds_file]}}"
    
    if [[ -z "$world_name" ]]; then
        log_error "World name cannot be empty"
        return 1
    fi
    
    # Check if world already exists
    if grep -q "^$world_name$" "$worlds_file" 2>/dev/null; then
        log_warn "World '$world_name' already exists in worlds file"
        return 1
    fi
    
    # Add world to file
    echo "$world_name" >> "$worlds_file"
    log_info "Added server instance: $world_name"
}

# Remove server instance
remove_server_instance() {
    local world_name="$1"
    local worlds_file="${worlds_file:-${DEFAULT_CONFIG[worlds_file]}}"
    
    if [[ -z "$world_name" ]]; then
        log_error "World name cannot be empty"
        return 1
    fi
    
    # Remove world from file
    if grep -q "^$world_name$" "$worlds_file" 2>/dev/null; then
        sed -i "/^$world_name$/d" "$worlds_file"
        log_info "Removed server instance: $world_name"
    else
        log_warn "World '$world_name' not found in worlds file"
        return 1
    fi
}

# Check if server instance exists
server_instance_exists() {
    local world_name="$1"
    local worlds_file="${worlds_file:-${DEFAULT_CONFIG[worlds_file]}}"
    
    grep -q "^$world_name$" "$worlds_file" 2>/dev/null
}

################################################################################
# INITIALIZATION
################################################################################

# Auto-initialize when sourced
init_config
