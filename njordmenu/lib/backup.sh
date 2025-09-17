#!/bin/bash
################################################################################
# Njord Menu Backup Management Library
# Handles Valheim server backup and restore operations
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
# BACKUP FUNCTIONS
################################################################################

# Create backup of Valheim world
create_backup() {
    local world_name="$1"
    local backup_name="${2:-}"
    local backup_path="${backupPath:-$DEFAULT_BACKUP_PATH}"
    local world_path="${world_path:-$DEFAULT_WORLD_PATH}"
    
    log_info "Creating backup for world: $world_name"
    
    # Validate world name
    if [[ -z "$world_name" ]]; then
        print_error "World name cannot be empty"
        return 1
    fi
    
    # Check if world exists
    local world_dir="$world_path/$world_name"
    if [[ ! -d "$world_dir" ]]; then
        print_error "World directory not found: $world_dir"
        return 1
    fi
    
    # Create backup directory
    local world_backup_dir="$backup_path/$world_name"
    create_dir "$world_backup_dir" "steam" "755"
    
    # Generate backup name if not provided
    if [[ -z "$backup_name" ]]; then
        backup_name="valheim-backup-$(date +%Y-%m-%d-%H%M%S)"
    fi
    
    local backup_file="$world_backup_dir/${backup_name}.tar.gz"
    
    # Stop server if running
    local service_name="valheimserver_${world_name}"
    local was_running=false
    if is_service_running "$service_name"; then
        log_info "Stopping server for clean backup: $world_name"
        stop_valheim_service "$world_name"
        was_running=true
        
        # Wait for complete shutdown
        sleep 10
    fi
    
    # Clear system cache
    clear_system_cache
    
    # Create backup
    log_info "Creating backup archive: $backup_file"
    if tar -czf "$backup_file" -C "$world_path" "$world_name"; then
        chown steam:steam "$backup_file"
        chmod 644 "$backup_file"
        
        # Get backup size
        local backup_size=$(du -h "$backup_file" | cut -f1)
        
        log_info "Backup created successfully: $backup_file ($backup_size)"
        print_success "Backup created: $backup_name ($backup_size)"
        
        # Clean old backups
        clean_old_backups "$world_name"
        
        # Restart server if it was running
        if [[ "$was_running" == true ]]; then
            log_info "Restarting server after backup: $world_name"
            start_valheim_service "$world_name"
        fi
        
        return 0
    else
        log_error "Failed to create backup: $backup_file"
        print_error "Backup creation failed"
        
        # Restart server if it was running
        if [[ "$was_running" == true ]]; then
            start_valheim_service "$world_name"
        fi
        
        return 1
    fi
}

# Restore backup
restore_backup() {
    local world_name="$1"
    local backup_file="$2"
    local world_path="${world_path:-$DEFAULT_WORLD_PATH}"
    
    log_info "Restoring backup for world: $world_name"
    
    # Validate inputs
    if [[ -z "$world_name" ]]; then
        print_error "World name cannot be empty"
        return 1
    fi
    
    if [[ -z "$backup_file" ]]; then
        print_error "Backup file cannot be empty"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    # Stop server if running
    local service_name="valheimserver_${world_name}"
    local was_running=false
    if is_service_running "$service_name"; then
        log_info "Stopping server for restore: $world_name"
        stop_valheim_service "$world_name"
        was_running=true
    fi
    
    # Create backup of current world data
    local current_backup="$world_path/${world_name}_pre_restore_$(date +%Y%m%d_%H%M%S).bak"
    if [[ -d "$world_path/$world_name" ]]; then
        log_info "Creating backup of current world data: $current_backup"
        mv "$world_path/$world_name" "$current_backup"
    fi
    
    # Create world directory
    create_dir "$world_path/$world_name" "steam" "755"
    
    # Extract backup
    log_info "Extracting backup: $backup_file"
    if tar -xzf "$backup_file" -C "$world_path"; then
        chown -R steam:steam "$world_path/$world_name"
        chmod -R 755 "$world_path/$world_name"
        
        log_info "Backup restored successfully: $world_name"
        print_success "Backup restored: $world_name"
        
        # Restart server if it was running
        if [[ "$was_running" == true ]]; then
            log_info "Restarting server after restore: $world_name"
            start_valheim_service "$world_name"
        fi
        
        return 0
    else
        log_error "Failed to extract backup: $backup_file"
        print_error "Backup restore failed"
        
        # Restore original data if extraction failed
        if [[ -d "$current_backup" ]]; then
            log_info "Restoring original world data"
            rm -rf "$world_path/$world_name"
            mv "$current_backup" "$world_path/$world_name"
        fi
        
        # Restart server if it was running
        if [[ "$was_running" == true ]]; then
            start_valheim_service "$world_name"
        fi
        
        return 1
    fi
}

# List available backups
list_backups() {
    local world_name="$1"
    local backup_path="${backupPath:-$DEFAULT_BACKUP_PATH}"
    
    if [[ -n "$world_name" ]]; then
        local world_backup_dir="$backup_path/$world_name"
        if [[ -d "$world_backup_dir" ]]; then
            print_info "Backups for world '$world_name':"
            ls -la "$world_backup_dir"/*.tar.gz 2>/dev/null | while read -r line; do
                local file_info=($line)
                local file_name=$(basename "${file_info[8]}")
                local file_size="${file_info[4]}"
                local file_date="${file_info[5]} ${file_info[6]} ${file_info[7]}"
                echo "  $file_name ($file_size bytes) - $file_date"
            done
        else
            print_info "No backups found for world: $world_name"
        fi
    else
        print_info "All available backups:"
        if [[ -d "$backup_path" ]]; then
            for world_dir in "$backup_path"/*; do
                if [[ -d "$world_dir" ]]; then
                    local world=$(basename "$world_dir")
                    echo
                    print_info "World: $world"
                    list_backups "$world"
                fi
            done
        else
            print_info "No backup directory found: $backup_path"
        fi
    fi
}

# Clean old backups
clean_old_backups() {
    local world_name="$1"
    local retention_days="${backup_retention_days:-14}"
    local backup_path="${backupPath:-$DEFAULT_BACKUP_PATH}"
    local world_backup_dir="$backup_path/$world_name"
    
    if [[ ! -d "$world_backup_dir" ]]; then
        return 0
    fi
    
    log_info "Cleaning backups older than $retention_days days for world: $world_name"
    
    local removed_count=0
    while IFS= read -r -d '' backup_file; do
        rm "$backup_file"
        ((removed_count++))
        log_debug "Removed old backup: $(basename "$backup_file")"
    done < <(find "$world_backup_dir" -name "*.tar.gz" -mtime +"$retention_days" -type f -print0)
    
    if [[ $removed_count -gt 0 ]]; then
        log_info "Cleaned $removed_count old backup(s) for world: $world_name"
        print_info "Cleaned $removed_count old backup(s)"
    else
        log_info "No old backups to clean for world: $world_name"
    fi
}

# Clear system cache
clear_system_cache() {
    log_info "Clearing system cache"
    
    # Sync filesystem
    sync
    
    # Clear page cache, dentries and inodes
    if [[ -w /proc/sys/vm/drop_caches ]]; then
        echo 3 > /proc/sys/vm/drop_caches
        log_info "System cache cleared"
    else
        log_warn "Cannot clear system cache (insufficient permissions)"
    fi
}

# Backup all worlds
backup_all_worlds() {
    local instances=($(get_server_instances))
    local success_count=0
    local total_count=${#instances[@]}
    
    if [[ $total_count -eq 0 ]]; then
        print_info "No worlds to backup"
        return 0
    fi
    
    log_info "Starting backup of all worlds ($total_count total)"
    print_info "Backing up $total_count world(s)..."
    
    for world_name in "${instances[@]}"; do
        echo
        print_info "Backing up world: $world_name"
        if create_backup "$world_name"; then
            ((success_count++))
        fi
    done
    
    echo
    log_info "Backup completed: $success_count/$total_count worlds backed up successfully"
    
    if [[ $success_count -eq $total_count ]]; then
        print_success "All worlds backed up successfully!"
        return 0
    else
        print_warning "Some backups failed ($success_count/$total_count successful)"
        return 1
    fi
}

# Interactive backup selection
interactive_backup_restore() {
    local world_name="$1"
    local backup_path="${backupPath:-$DEFAULT_BACKUP_PATH}"
    local world_backup_dir="$backup_path/$world_name"
    
    if [[ ! -d "$world_backup_dir" ]]; then
        print_error "No backups found for world: $world_name"
        return 1
    fi
    
    # Get list of backup files
    local backups=()
    while IFS= read -r -d '' backup_file; do
        backups+=("$backup_file")
    done < <(find "$world_backup_dir" -name "*.tar.gz" -type f -print0 | sort -rz)
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        print_error "No backup files found for world: $world_name"
        return 1
    fi
    
    # Display backup list
    print_info "Available backups for world '$world_name':"
    echo
    for i in "${!backups[@]}"; do
        local backup_file="${backups[$i]}"
        local file_name=$(basename "$backup_file")
        local file_size=$(du -h "$backup_file" | cut -f1)
        local file_date=$(stat -c %y "$backup_file" | cut -d' ' -f1-2)
        printf "  %2d) %s (%s) - %s\n" $((i+1)) "$file_name" "$file_size" "$file_date"
    done
    
    echo
    read -p "Select backup to restore (1-${#backups[@]}, 0 to cancel): " selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 0 ]] && [[ $selection -le ${#backups[@]} ]]; then
        if [[ $selection -eq 0 ]]; then
            print_info "Backup restore cancelled"
            return 0
        else
            local selected_backup="${backups[$((selection-1))]}"
            echo
            print_warning "You are about to restore backup: $(basename "$selected_backup")"
            read -p "This will replace current world data. Continue? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                restore_backup "$world_name" "$selected_backup"
            else
                print_info "Backup restore cancelled"
            fi
        fi
    else
        print_error "Invalid selection"
        return 1
    fi
}

# Schedule automatic backups
schedule_backups() {
    local cron_schedule="${1:-0 2 * * *}"  # Default: daily at 2 AM
    local script_path="$(dirname "${BASH_SOURCE[0]}")/../njordmenu.sh"
    
    log_info "Scheduling automatic backups: $cron_schedule"
    
    # Create cron job
    local cron_job="$cron_schedule root $script_path backup-all"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "njordmenu.sh backup-all"; echo "$cron_job") | crontab -
    
    log_info "Automatic backups scheduled: $cron_schedule"
    print_success "Automatic backups scheduled successfully!"
}

# Remove backup schedule
remove_backup_schedule() {
    log_info "Removing automatic backup schedule"
    
    # Remove from crontab
    crontab -l 2>/dev/null | grep -v "njordmenu.sh backup-all" | crontab -
    
    log_info "Automatic backup schedule removed"
    print_success "Automatic backup schedule removed successfully!"
}

# Get backup statistics
get_backup_stats() {
    local backup_path="${backupPath:-$DEFAULT_BACKUP_PATH}"
    
    if [[ ! -d "$backup_path" ]]; then
        print_info "No backup directory found: $backup_path"
        return 0
    fi
    
    print_info "Backup Statistics:"
    echo "==================="
    
    local total_size=0
    local total_files=0
    
    for world_dir in "$backup_path"/*; do
        if [[ -d "$world_dir" ]]; then
            local world=$(basename "$world_dir")
            local world_size=0
            local world_files=0
            
            while IFS= read -r -d '' backup_file; do
                local file_size=$(stat -c %s "$backup_file")
                ((world_size += file_size))
                ((world_files++))
            done < <(find "$world_dir" -name "*.tar.gz" -type f -print0)
            
            if [[ $world_files -gt 0 ]]; then
                local size_mb=$((world_size / 1024 / 1024))
                echo "  $world: $world_files backup(s), ${size_mb}MB"
                ((total_size += world_size))
                ((total_files += world_files))
            fi
        fi
    done
    
    if [[ $total_files -gt 0 ]]; then
        local total_size_mb=$((total_size / 1024 / 1024))
        echo
        echo "  Total: $total_files backup(s), ${total_size_mb}MB"
    else
        echo "  No backups found"
    fi
}
