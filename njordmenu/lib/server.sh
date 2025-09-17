#!/bin/bash
################################################################################
# Njord Menu Server Management Library
# Handles Valheim server operations, installation, and management
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
# SERVER MANAGEMENT FUNCTIONS
################################################################################

# Install Valheim server
install_valheim_server() {
    local world_name="$1"
    local server_name="$2"
    local server_password="$3"
    local public_listing="${4:-1}"
    local port="${5:-${default_port:-2456}}"
    
    log_info "Starting Valheim server installation for world: $world_name"
    
    # Validate inputs
    if ! validate_world_name "$world_name"; then
        print_error "Invalid world name: $world_name"
        return 1
    fi
    
    if ! validate_password "$server_password" "${password_min_length:-6}"; then
        print_error "Invalid server password"
        return 1
    fi
    
    if ! validate_port "$port"; then
        print_error "Invalid port number: $port"
        return 1
    fi
    
    # Create steam user if it doesn't exist
    if ! id "steam" &>/dev/null; then
        create_steam_user
    fi
    
    # Install required packages
    install_required_packages
    
    # Install SteamCMD
    install_steamcmd
    
    # Download and install Valheim server
    download_valheim_server
    
    # Create server configuration
    create_server_config "$world_name" "$server_name" "$server_password" "$public_listing" "$port"
    
    # Create systemd service
    create_systemd_service "$world_name" "$port"
    
    # Add to worlds file
    add_server_instance "$world_name"
    
    # Start the service
    start_valheim_service "$world_name"
    
    log_info "Valheim server installation completed for world: $world_name"
    print_success "Valheim server '$server_name' installed successfully!"
}

# Create steam user
create_steam_user() {
    log_info "Creating steam user account"
    
    local steam_password=$(generate_password 12)
    
    if command_exists apt-get; then
        useradd --create-home --shell /bin/bash --password "$steam_password" steam
        cp /etc/skel/.bashrc /home/steam/.bashrc
        cp /etc/skel/.profile /home/steam/.profile
    elif command_exists yum; then
        useradd -mU -s /bin/bash -p "$steam_password" steam
    else
        log_error "Unsupported package manager"
        return 1
    fi
    
    # Set up steam user environment
    sudo -u steam mkdir -p /home/steam/.steam
    sudo -u steam mkdir -p /home/steam/steamcmd
    
    log_info "Steam user created with password: $steam_password"
    print_warning "IMPORTANT: Save this steam password: $steam_password"
}

# Install required packages
install_required_packages() {
    log_info "Installing required packages"
    
    if command_exists apt-get; then
        apt-get update
        apt-get install -y software-properties-common curl wget unzip net-tools lib32gcc-s1 lib32stdc++6
    elif command_exists yum; then
        yum update -y
        yum install -y curl wget unzip net-tools glibc.i686 libstdc++.i686
    else
        log_error "Unsupported package manager"
        return 1
    fi
    
    log_info "Required packages installed successfully"
}

# Install SteamCMD
install_steamcmd() {
    local steamcmd_path="${valheim_install_path:-$DEFAULT_VALHEIM_PATH}/steamcmd"
    
    log_info "Installing SteamCMD"
    
    # Create steamcmd directory
    create_dir "$steamcmd_path" "steam" "755"
    
    # Download SteamCMD
    cd "$steamcmd_path"
    sudo -u steam wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
    sudo -u steam tar -xzf steamcmd_linux.tar.gz
    sudo -u steam rm steamcmd_linux.tar.gz
    
    # Create symbolic link
    ln -sf "$steamcmd_path/steamcmd.sh" /usr/local/bin/steamcmd
    chmod +x /usr/local/bin/steamcmd
    
    log_info "SteamCMD installed successfully"
}

# Download Valheim server
download_valheim_server() {
    local install_path="${valheim_install_path:-$DEFAULT_VALHEIM_PATH}"
    
    log_info "Downloading Valheim server"
    
    # Create installation directory
    create_dir "$install_path" "steam" "755"
    
    # Download server files
    cd "$install_path"
    sudo -u steam steamcmd +login anonymous +force_install_dir "$install_path" +app_update 896660 validate +quit
    
    log_info "Valheim server downloaded successfully"
}

# Create server configuration
create_server_config() {
    local world_name="$1"
    local server_name="$2"
    local server_password="$3"
    local public_listing="$4"
    local port="$5"
    local install_path="${valheim_install_path:-$DEFAULT_VALHEIM_PATH}"
    
    log_info "Creating server configuration for world: $world_name"
    
    # Create start script
    cat > "$install_path/start_valheim_${world_name}.sh" << EOF
#!/bin/bash
# Valheim Server Start Script for $world_name
# Generated on $(date)

export SteamAppId=892970
export LD_LIBRARY_PATH="$install_path/linux64:$install_path"

cd "$install_path"
exec ./valheim_server.x86_64 \\
    -name "$server_name" \\
    -port $port \\
    -world "$world_name" \\
    -password "$server_password" \\
    -public $public_listing \\
    -savedir "${world_path:-$DEFAULT_WORLD_PATH}"
EOF
    
    chmod +x "$install_path/start_valheim_${world_name}.sh"
    chown steam:steam "$install_path/start_valheim_${world_name}.sh"
    
    # Create world directory
    local world_dir="${world_path:-$DEFAULT_WORLD_PATH}/$world_name"
    create_dir "$world_dir" "steam" "755"
    
    log_info "Server configuration created for world: $world_name"
}

# Create systemd service
create_systemd_service() {
    local world_name="$1"
    local port="$2"
    local install_path="${valheim_install_path:-$DEFAULT_VALHEIM_PATH}"
    local service_name="valheimserver_${world_name}"
    
    log_info "Creating systemd service for world: $world_name"
    
    cat > "/etc/systemd/system/${service_name}.service" << EOF
[Unit]
Description=Valheim Server - $world_name
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=steam
Group=steam
WorkingDirectory=$install_path
ExecStart=$install_path/start_valheim_${world_name}.sh
ExecStop=/bin/kill -SIGINT \$MAINPID
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable "$service_name"
    
    log_info "Systemd service created: $service_name"
}

# Start Valheim service
start_valheim_service() {
    local world_name="$1"
    local service_name="valheimserver_${world_name}"
    
    log_info "Starting Valheim service: $service_name"
    
    if systemctl start "$service_name"; then
        sleep 5
        if is_service_running "$service_name"; then
            log_info "Valheim service started successfully: $service_name"
            print_success "Valheim server '$world_name' is now running!"
        else
            log_error "Valheim service failed to start: $service_name"
            return 1
        fi
    else
        log_error "Failed to start Valheim service: $service_name"
        return 1
    fi
}

# Stop Valheim service
stop_valheim_service() {
    local world_name="$1"
    local service_name="valheimserver_${world_name}"
    
    log_info "Stopping Valheim service: $service_name"
    
    if systemctl stop "$service_name"; then
        if wait_for_service_stop "$service_name" "${max_wait_time:-60}"; then
            log_info "Valheim service stopped successfully: $service_name"
            print_success "Valheim server '$world_name' stopped!"
        else
            log_error "Valheim service failed to stop: $service_name"
            return 1
        fi
    else
        log_error "Failed to stop Valheim service: $service_name"
        return 1
    fi
}

# Restart Valheim service
restart_valheim_service() {
    local world_name="$1"
    local service_name="valheimserver_${world_name}"
    
    log_info "Restarting Valheim service: $service_name"
    
    if systemctl restart "$service_name"; then
        sleep 5
        if is_service_running "$service_name"; then
            log_info "Valheim service restarted successfully: $service_name"
            print_success "Valheim server '$world_name' restarted!"
        else
            log_error "Valheim service failed to restart: $service_name"
            return 1
        fi
    else
        log_error "Failed to restart Valheim service: $service_name"
        return 1
    fi
}

# Get server status
get_server_status() {
    local world_name="$1"
    local service_name="valheimserver_${world_name}"
    
    if service_exists "$service_name"; then
        get_service_status "$service_name"
    else
        echo "not_installed"
    fi
}

# List all servers
list_servers() {
    local instances=($(get_server_instances))
    
    if [[ ${#instances[@]} -eq 0 ]]; then
        print_info "No Valheim servers installed"
        return 0
    fi
    
    print_info "Installed Valheim servers:"
    echo
    
    for world_name in "${instances[@]}"; do
        local status=$(get_server_status "$world_name")
        local service_name="valheimserver_${world_name}"
        
        case "$status" in
            "running")
                print_success "  $world_name - Running"
                ;;
            "stopped")
                print_warning "  $world_name - Stopped"
                ;;
            "not_installed")
                print_error "  $world_name - Not Installed"
                ;;
            *)
                print_info "  $world_name - Unknown Status"
                ;;
        esac
    done
}

# Update Valheim server
update_valheim_server() {
    local world_name="$1"
    local install_path="${valheim_install_path:-$DEFAULT_VALHEIM_PATH}"
    
    log_info "Updating Valheim server for world: $world_name"
    
    # Stop the service if running
    if is_service_running "valheimserver_${world_name}"; then
        stop_valheim_service "$world_name"
    fi
    
    # Update server files
    cd "$install_path"
    sudo -u steam steamcmd +login anonymous +force_install_dir "$install_path" +app_update 896660 validate +quit
    
    # Start the service
    start_valheim_service "$world_name"
    
    log_info "Valheim server updated for world: $world_name"
    print_success "Valheim server '$world_name' updated successfully!"
}

# Remove Valheim server
remove_valheim_server() {
    local world_name="$1"
    local service_name="valheimserver_${world_name}"
    
    log_info "Removing Valheim server: $world_name"
    
    # Stop and disable service
    if service_exists "$service_name"; then
        systemctl stop "$service_name" 2>/dev/null || true
        systemctl disable "$service_name" 2>/dev/null || true
        rm -f "/etc/systemd/system/${service_name}.service"
        systemctl daemon-reload
    fi
    
    # Remove from worlds file
    remove_server_instance "$world_name"
    
    # Remove world data (with confirmation)
    local world_dir="${world_path:-$DEFAULT_WORLD_PATH}/$world_name"
    if [[ -d "$world_dir" ]]; then
        print_warning "World data directory exists: $world_dir"
        read -p "Do you want to remove world data? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$world_dir"
            log_info "World data removed: $world_dir"
        else
            log_info "World data preserved: $world_dir"
        fi
    fi
    
    log_info "Valheim server removed: $world_name"
    print_success "Valheim server '$world_name' removed successfully!"
}

# Get server logs
get_server_logs() {
    local world_name="$1"
    local service_name="valheimserver_${world_name}"
    local lines="${2:-50}"
    
    if service_exists "$service_name"; then
        journalctl -u "$service_name" -n "$lines" --no-pager
    else
        print_error "Service not found: $service_name"
        return 1
    fi
}

# Monitor server status
monitor_server() {
    local world_name="$1"
    local service_name="valheimserver_${world_name}"
    local refresh_interval="${2:-5}"
    
    if ! service_exists "$service_name"; then
        print_error "Service not found: $service_name"
        return 1
    fi
    
    print_info "Monitoring Valheim server: $world_name (Press Ctrl+C to stop)"
    echo
    
    while true; do
        clear
        print_info "Valheim Server Monitor - $world_name"
        echo "================================================"
        echo
        
        # Service status
        local status=$(get_service_status "$service_name")
        case "$status" in
            "running")
                print_success "Status: Running"
                ;;
            "stopped")
                print_warning "Status: Stopped"
                ;;
            *)
                print_error "Status: Unknown"
                ;;
        esac
        
        # Recent logs
        echo
        print_info "Recent logs:"
        get_server_logs "$world_name" 10
        
        echo
        print_info "Refreshing in $refresh_interval seconds..."
        sleep "$refresh_interval"
    done
}
