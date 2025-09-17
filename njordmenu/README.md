# Njord Menu 5.0 - Odin

A completely overhauled, modular Valheim server management system built with modern bash best practices.

## 🚀 What's New in 5.0

### Complete Architecture Overhaul
- **Modular Design**: Split the massive 3,500+ line monolithic script into focused, maintainable modules
- **Modern Bash**: Implemented strict error handling, proper logging, and input validation
- **Clean Separation**: UI, business logic, and system operations are now properly separated
- **Extensible**: Easy to add new features without touching core code

### New Features
- **Centralized Logging**: All operations are logged with proper levels and timestamps
- **Configuration Management**: JSON-style configuration with validation and migration
- **Better Error Handling**: Consistent error reporting and recovery mechanisms
- **Improved UI**: Modern, colorful interface with better user experience
- **Command Line Interface**: Full CLI support for automation and scripting
- **Backward Compatibility**: Migration script to transition from 4.0-Thor

## 📁 New Directory Structure

```
njordmenu/
├── njordmenu.sh          # Main entry point (streamlined)
├── lib/                  # Core libraries
│   ├── core.sh          # Core functions and utilities
│   ├── config.sh        # Configuration management
│   ├── server.sh        # Server operations
│   ├── backup.sh        # Backup and restore
│   └── ui.sh            # User interface
├── mods/                # Mod management (future)
├── config/              # Configuration files
├── migrate.sh           # Migration from 4.0-Thor
├── test_system.sh       # System testing
└── README.md            # This file
```

## 🛠️ Installation

### For New Installations
1. Clone the repository
2. Navigate to the `njordmenu` directory
3. Run the main script:
   ```bash
   sudo ./njordmenu.sh
   ```

### For Existing 4.0-Thor Users
1. Navigate to the `njordmenu` directory
2. Run the migration script:
   ```bash
   sudo ./migrate.sh
   ```
3. Follow the migration prompts

## 🎮 Usage

### Interactive Mode
```bash
sudo ./njordmenu.sh
```

### Command Line Mode
```bash
# Install a new server
sudo ./njordmenu.sh install

# Start a server
sudo ./njordmenu.sh start [world_name]

# Stop a server
sudo ./njordmenu.sh stop [world_name]

# Create a backup
sudo ./njordmenu.sh backup [world_name]

# List all servers
sudo ./njordmenu.sh list

# Show system info
sudo ./njordmenu.sh info

# Get help
sudo ./njordmenu.sh help
```

## 🔧 Configuration

The new system uses centralized configuration files:

- **Main Config**: `/etc/njordmenu/njordmenu.conf`
- **Server Config**: `/etc/njordmenu/servers.conf`
- **Language Config**: `/etc/njordmenu/language.conf`

### Key Configuration Options

```bash
# Paths
valheim_install_path="/home/steam/valheimserver"
world_path="/home/steam/.config/unity3d/IronGate/Valheim"
backup_path="/home/steam/backups"

# Settings
log_level="INFO"
language="EN"
use_firewall="false"
debug_mode="false"
```

## 📊 Logging

All operations are logged to `/var/log/njordmenu.log` with different levels:

- **ERROR**: Critical errors that prevent operation
- **WARN**: Warnings that don't stop execution
- **INFO**: General information about operations
- **DEBUG**: Detailed debugging information

## 🔄 Migration from 4.0-Thor

The migration script automatically:

1. **Backs up** your old system
2. **Migrates** configuration files
3. **Preserves** existing servers and worlds
4. **Creates** backward compatibility symlinks
5. **Tests** the new system

### Migration Steps
```bash
cd njordmenu
sudo ./migrate.sh
```

## 🧪 Testing

Test the new system:
```bash
sudo ./test_system.sh
```

## 🚧 Development

### Adding New Features
1. Create new functions in appropriate library files
2. Add UI elements in `lib/ui.sh`
3. Update main menu in `njordmenu.sh`
4. Test thoroughly

### Library Structure
- **core.sh**: Basic utilities, validation, system functions
- **config.sh**: Configuration management and validation
- **server.sh**: Valheim server operations
- **backup.sh**: Backup and restore operations
- **ui.sh**: User interface and display functions

## 🐛 Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure running as root or with sudo
2. **Configuration Issues**: Check `/etc/njordmenu/` directory permissions
3. **Service Issues**: Verify systemd service files are properly created
4. **Log Issues**: Check `/var/log/njordmenu.log` for detailed error information

### Debug Mode
Enable debug mode in configuration:
```bash
echo 'debug_mode="true"' >> /etc/njordmenu/njordmenu.conf
```

## 📈 Performance Improvements

- **Faster Startup**: Modular loading reduces initialization time
- **Better Memory Usage**: Only load required modules
- **Improved Error Recovery**: Better error handling and recovery
- **Cleaner Code**: Easier to maintain and debug

## 🔮 Future Roadmap

### Phase 2: Enhanced Features
- [ ] Web-based management interface
- [ ] Advanced mod management system
- [ ] Automated backup scheduling
- [ ] Server health monitoring
- [ ] Multi-instance management improvements

### Phase 3: Advanced Features
- [ ] Plugin system for custom extensions
- [ ] API for external integrations
- [ ] Advanced logging and analytics
- [ ] Performance monitoring dashboard

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 Changelog

### 5.0-Odin (Current)
- Complete architecture overhaul
- Modular design implementation
- Modern bash best practices
- Centralized logging system
- Configuration management
- Command line interface
- Migration tools
- Improved error handling

### 4.0-Thor (Previous)
- Monolithic script architecture
- Basic server management
- Simple backup system
- Limited error handling

## 📞 Support

- **Discord**: https://discord.gg/ejgQUfc
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Check the wiki for detailed guides

## 🙏 Acknowledgments

- **ZeroBandwidth**: Original creator and maintainer
- **Development Team**: All contributors and testers
- **Community**: Valheim server administrators and players

---

**Happy Gaming!** 🎮

*ZeroBandwidth & Team*
