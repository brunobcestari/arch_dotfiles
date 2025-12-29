# Arch Linux Dotfiles - Hyprland Setup

Personal dotfiles for Arch Linux with Hyprland window manager.

**Now with modular architecture, dry-run mode, and easy maintenance!**

## 📖 Table of Contents
- [Features](#-features)
- [Installation](#-installation)
- [Installer Features](#-installer-features) - **NEW: Dry-run & custom backups**
- [Maintenance Guide](#-maintenance-guide) - **How to add new dotfiles**
- [Keybindings](#-keybindings)
- [Customization](#-customization)
- [Directory Structure](#-directory-structure)
- [Troubleshooting](#-troubleshooting)

## 🎨 Features

- **Window Manager**: Hyprland (Wayland compositor)
- **Display Manager**: SDDM with HiDPI support
- **Status Bar**: Dual Waybar setup (top + bottom) with modular config, grouped modules, and GTK popups
- **Terminal**: Alacritty with Tokyo Night theme
- **Notifications**: Mako
- **Lock Screen**: Hyprlock
- **App Launcher**: Rofi
- **Audio**: PipeWire with WirePlumber and GTK device selector popups
- **Weather**: wttrbar widget with interactive GTK forecast popup
- **Power Menu**: GTK menu with shutdown/reboot/suspend/hibernate options
- **Editor**: Vim with NERDTree, coc.nvim, and colorschemes
- **Shell**: Custom colorful PS1 bash prompt with git branch info

## 🖥️ System Configuration

### Display Setup
- **Primary Monitor (DP-1)**: 3840x2160@60Hz (4K, HiDPI 2x scaling)
- **Secondary Monitor (DP-2)**: Disabled during login, available after login
- SDDM shows only on primary monitor with proper HiDPI scaling

### Keyboard Layout
- US International (with dead keys for accents)
- Configured in both Hyprland and SDDM

### Audio
- Multiple input/output device support
- Volume wheel integration
- PipeWire with WirePlumber
- GTK popup device selector (click microphone/speaker icons)
- Real-time device switching with visual feedback

## 📦 Installation

### Prerequisites

- **Arch Linux** with base system installed
- **paru** AUR helper (auto-installed if missing)

### Quick Install (Recommended)

```bash
git clone <your-repo-url> ~/gitrepos/arch_dotfiles
cd ~/gitrepos/arch_dotfiles
./install.sh
```

**The installer will:**
1. Check system requirements and **auto-install paru** if needed
2. Display essential packages from `packages.txt`
3. Ask simple yes/no questions for optional package categories:
   ```
   File Manager:
     ✓ thunar - Thunar file manager [official]

   Install File Manager? [Y/n]:
   ```
4. Show installation summary before proceeding
5. Backup existing configurations automatically
6. Install selected packages
7. Generate custom `autostart.conf` based on your selections
8. Set up all configurations and enable services

**Available optional categories:**
- **File Manager**: Thunar
- **Development Tools**: Vim, Node.js, npm, git
- **System Monitoring**: btop
- **Hardware Control**: brightnessctl, playerctl, OpenLinkHub (Corsair), razercfg (Razer)
- **System Customization**: SDDM Silent Theme
- **Personal Applications**: ProtonMail Bridge, Proton Mail, Proton Pass, pCloud Drive, Das Keyboard Q, Birdtray *(AUR, will autostart)*

### Configuration Files

Package installation is controlled by two config files:

**packages.txt** - Essential packages (always installed):
```
hyprland
waybar
alacritty
# ... etc
```

**optional-apps.conf** - Optional packages grouped by category:
```
# Format: category|name|description|repo|autostart|startup_command
filemanager|thunar|Thunar file manager|official|no|
development|vim|Vim text editor with plugins|official|no|
personal|protonmail-bridge|ProtonMail Bridge|aur|yes|protonmail-bridge
```

This makes it easy to:
- Add/remove packages by editing config files
- Specify package source (official repos or AUR)
- Control which apps autostart on login
- Maintain consistent setup across installations

### Manual Install

If you prefer manual control, you can install components individually:

1. **Install packages**:
   ```bash
   paru -S --needed - < packages.txt
   ```

2. **Copy configs**:
   ```bash
   cp -r hypr ~/.config/
   cp -r waybar ~/.config/
   cp -r mako ~/.config/
   cp -r alacritty ~/.config/
   cp -r rofi ~/.config/
   ```

3. **Install SDDM configs** (requires sudo):
   ```bash
   sudo cp sddm/*.conf /etc/sddm.conf.d/
   sudo cp sddm/Xsetup /usr/share/sddm/scripts/Xsetup
   sudo chmod +x /usr/share/sddm/scripts/Xsetup
   ```

4. **Enable SDDM**:
   ```bash
   sudo systemctl enable sddm.service
   ```

5. **Reboot** and select Hyprland from SDDM

### Syncing Changes Back to Repo

After making changes to your configs, use the sync script to backup to the repo:

```bash
./sync-from-system.sh
```

**The sync script will:**
1. Copy all configs from `~/.config` back to the repo
2. Copy `.vimrc` and `custom_ps1.sh` back to the repo
3. Optionally sync SDDM configs (requires sudo)
4. Show git diff of changes
5. Optionally commit and push changes

This makes it easy to keep your dotfiles repo in sync with your actual system configs!

## 🎯 Installer Features

### Core Features
- **Config-driven**: All packages defined in `packages.txt` and `optional-apps.conf`
- **Modular architecture**: Centralized configuration arrays for easy maintenance
- **Less interactive**: Simple yes/no prompts instead of complex selections
- **Auto-install paru**: Automatically builds and installs paru if missing
- **Clear display**: Shows what will be installed with repository sources
- **Installation summary**: Review package counts before proceeding
- **Automatic backups**: Creates timestamped backups before overwriting configs
- **Dynamic autostart**: Generates `autostart.conf` based on your selections
- **Error handling**: Robust error handling with `set -euo pipefail`
- **Colored output**: Clear status messages for better readability
- **Safe operations**: Confirmation prompts before destructive operations
- **Structure verification**: Validates all required files/directories before installation

### Command-Line Options

```bash
./install.sh [OPTIONS]
```

**Available Options:**
- `-h, --help` - Show help message and exit
- `-d, --dry-run` - Preview what would be installed without making any changes
- `-b, --backup-dir DIR` - Specify custom backup directory (default: `~/.config-backup-YYYYMMDD-HHMMSS`)

**Examples:**
```bash
# Normal installation
./install.sh

# Preview installation without making changes
./install.sh --dry-run

# Use custom backup directory
./install.sh --backup-dir ~/my-backups

# Combine options
./install.sh --dry-run --backup-dir /tmp/test-backup
```

### Dry-Run Mode

The `--dry-run` flag lets you preview exactly what the installer will do without making any changes:

```bash
./install.sh --dry-run
```

**What it shows:**
- ✓ All packages that would be installed
- ✓ All directories that would be created
- ✓ All files that would be copied
- ✓ All commands that would run (including sudo commands)
- ✓ Backup locations and what would be backed up

**Perfect for:**
- Testing the installer before running it
- Validating your dotfiles structure
- Understanding what will happen on a fresh install
- Debugging installation issues

## ⌨️ Keybindings

| Key | Action |
|-----|--------|
| `Super + Return` | Open terminal (Alacritty) |
| `Super + D` | App launcher (Rofi) |
| `Super + L` | Lock screen |
| `Super + E` | File manager (Thunar) |
| `Super + Shift + Q` | Close window |
| `Super + Shift + E` | Exit Hyprland |
| `Super + 1-9` | Switch to workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Super + V` | Toggle floating |
| `Super + P` | Pseudo-tiling |

### Media Keys
- Volume wheel works automatically
- `XF86AudioRaiseVolume/LowerVolume` - Volume control
- `XF86AudioMute` - Mute toggle
- `XF86AudioPlay/Pause` - Media control

## 🎨 Customization

### Hyprland

**Modular Configuration Structure:**
The Hyprland configuration is organized into separate files for better maintainability:

- **hyprland.conf** - Main config that sources all modules
- **monitors.conf** - Display and monitor setup
- **programs.conf** - Default applications ($terminal, $fileManager, etc.)
- **autostart.conf** - Startup applications (dynamically generated by installer based on your selections)
- **environment.conf** - Environment variables (cursor size, Electron flags, etc.)
- **look-and-feel.conf** - Appearance, decorations, animations, layouts
- **input.conf** - Keyboard layout, mouse settings, touchpad, gestures
- **keybindings.conf** - All keyboard shortcuts and binds
- **rules.conf** - Window rules and workspace rules

**Benefits:**
- 📝 Easy to share core config without personal apps
- 🔧 Modify sections independently
- 📚 Clear organization and documentation
- 🎯 Installer generates `autostart.conf` with only the apps you selected
- ⚠️ No need to worry about missing dependencies - only selected apps are included

### Waybar

**Dual Bar Setup:**
Two separate Waybar instances for better organization:

- **Top Bar** (`config-top.jsonc`):
  - Left: Window title
  - Center: Clock, Weather widget
  - Right: Updates, VPN, System monitors (CPU, Memory, Disk), Network

- **Bottom Bar** (`config-bottom.jsonc`):
  - Left: Hyprland workspaces
  - Right: Media player, Audio controls (input/output/slider), System tray, Power menu

**Modular Configuration Structure:**
The Waybar configuration uses a modular approach inspired by the HyDE project, with modules organized into separate JSON files and grouped for better organization:

- **Module Groups**:
  - `group/system` - CPU, memory, disk monitoring
  - `group/audio` - Audio input/output/slider controls
  - `group/utilities` - Updates, VPN status

- **Module Files** (`modules/*.json`): Individual JSON files for each component
- **Custom Menus** (`menus/`): XML menu files (e.g., power menu)

**Interactive Features:**
- **Audio Input/Output Selector**: Click microphone/speaker icons to open GTK device selector
  - Shows all available audio devices
  - Checkmark (✓) and bold text indicate current device
  - Single-click to switch devices
  - Auto-closes after selection
- **Weather Forecast**: Click weather widget to see detailed forecast
  - Fetches data from wttr.in
  - Beautiful ASCII art display
  - Auto-closes after 30 seconds
- **Power Menu**: Click power icon for shutdown/reboot/suspend/hibernate options
- **Volume Control**:
  - Middle-click volume icon to mute/unmute
  - Scroll on volume icon to adjust volume
- Custom Catppuccin styling in `waybar/style.css`

### Alacritty
- Tokyo Night color scheme
- 95% opacity for transparency
- No title bar for cleaner look
- Config: `alacritty/alacritty.toml`

### Hyprlock
- Blurred screenshot background
- Shows only on primary monitor
- Time, date, and password input
- Config: `hypr/hyprlock.conf`

### Rofi
- **Application Launcher**: Shows desktop applications by default
- **Mode Switching**: Cycle through modes with Ctrl+Tab (Applications → Windows → Run → SSH)
- **Custom Theme**: Catppuccin-inspired design matching Waybar
  - Same dark background (#1A1B26) and cyan accent (#33ccff)
  - Rounded corners and clean spacing
  - Icon support with Papirus-Dark theme
- **Keybind**: `Super + D` to launch
- Config: `rofi/config.rasi`

### Vim
- **Plugins**: NERDTree (file explorer), coc.nvim (LSP/completion), colorschemes
- **Theme**: Deus colorscheme
- **Features**: Smart indentation, search highlighting, Git integration
- **Plugin Manager**: vim-plug (auto-installed)
- Config: `vim/vimrc`

### Bash Prompt (PS1)
- **Features**: Colorful prompt with timestamp, git branch, exit status, background jobs
- **Colors**: Green for normal user, red for root
- **Git Integration**: Shows current branch when in git repo
- **Location**: `/etc/profile.d/custom_ps1.sh` (system-wide)
- Config: `ps1/custom_ps1.sh`

## 📁 Directory Structure

```
arch_dotfiles/
├── hypr/                  # Hyprland & Hyprlock configs
├── waybar/                # Dual Waybar setup (modular structure)
│   ├── config-top.jsonc   # Top bar configuration
│   ├── config-bottom.jsonc # Bottom bar configuration
│   ├── style.css          # Catppuccin styling
│   ├── modules/           # Modular JSON configs
│   │   ├── workspaces.json      # Hyprland workspaces & windows
│   │   ├── clock.json           # Clock with calendar
│   │   ├── system.json          # CPU, memory, disk
│   │   ├── audio.json           # Audio input/output/slider
│   │   ├── network.json         # Network status
│   │   ├── media.json           # Media player controls
│   │   ├── custom-modules.json  # Weather, VPN, updates, mail
│   │   ├── power.json           # Power menu
│   │   └── tray.json            # System tray
│   ├── menus/             # XML menu definitions
│   │   └── power.xml            # Power menu options
│   └── scripts/           # Python & bash scripts
│       ├── audio-selector.py    # GTK audio device selector
│       ├── weather-popup.py     # GTK weather forecast popup
│       ├── thunderbird-mail.sh  # Email notification checker
│       ├── vpn-status.sh        # VPN status indicator
│       └── updates.sh           # System update checker
├── mako/                  # Notification daemon
├── alacritty/             # Terminal emulator
├── rofi/                  # Application launcher
├── sddm/                  # Display manager configs
├── xdg-desktop-portal/    # Portal config for screen sharing
├── vim/                   # Vim configuration & plugins
├── ps1/                   # Custom bash prompt
├── workstyle/             # Workstyle config (workspace icons)
├── packages.txt           # Essential packages (always installed)
├── optional-apps.conf     # Optional packages with categories & autostart
├── install.sh             # Modular installation script with config arrays
├── sync-from-system.sh    # Sync system configs back to repo
└── README.md              # This file
```

## 🎥 Screen Sharing

Screen sharing works with apps like Slack, Discord, Zoom, etc.

**Requirements:**
- `xdg-desktop-portal-hyprland` (included in packages.txt)
- Portal configuration (included in `xdg-desktop-portal/portals.conf`)

**Known Issues:**
- Electron apps (Slack, Discord) may require clicking multiple times to confirm screen selection
- Workaround: Press Enter instead of clicking, or click and wait a second

**Environment Variables:**
The Hyprland config includes `ELECTRON_OZONE_PLATFORM_HINT=wayland` for better Electron app support.

## 🔧 Maintenance Guide

### Adding New Dotfiles

The installer uses **centralized configuration arrays** at the top of `install.sh` (lines 19-43). This makes adding new dotfiles super easy!

#### 1. Add a Standard Config Directory (goes to `~/.config/`)

Edit `install.sh` and add to the `CONFIG_DIRS` array:

```bash
readonly CONFIG_DIRS=(
    "hypr"
    "mako"
    "neovim"        # <- Add your new config here!
)
```

Then create the directory in your repo:
```bash
mkdir ~/gitrepos/arch_dotfiles/neovim
# Add your config files...
```

**That's it!** The installer will automatically:
- ✓ Verify the directory exists before installation
- ✓ Create `~/.config/neovim` directory
- ✓ Copy all files from `neovim/` to `~/.config/neovim/`
- ✓ Include it in backups

#### 2. Add a Home Directory File (goes to `~/`)

Edit `install.sh` and add to the `HOME_FILES` array:

```bash
readonly HOME_FILES=(
    "vim/vimrc:.vimrc"
    "zsh/zshrc:.zshrc"    # <- Add your new file here!
)
```

Format: `"source_path:destination_filename"`

#### 3. Add a Conditional Config (only if package is selected)

For configs that should only install when a specific package is selected:

```bash
readonly CONDITIONAL_CONFIGS=(
    "workstyle-git:workstyle:workstyle"
    "neovim:nvim:nvim"    # <- package_name:source_dir:dest_dir
)
```

Format: `"package_name:source_directory:destination_directory"`

The package must be listed in `optional-apps.conf` for this to work.

#### 4. Use Different Source and Destination Names

```bash
readonly CONFIG_DIRS=(
    "kitty-config:kitty"   # <- repo/kitty-config -> ~/.config/kitty
)
```

### Adding New Packages

#### Essential Packages (always installed)

Edit `packages.txt` and add the package name:

```
## Terminal Emulators
alacritty
kitty           # <- Add here
```

#### Optional Packages (user can choose)

Edit `optional-apps.conf`:

```
# Format: category|name|description|repo|autostart|startup_command
development|neovim|Neovim text editor|official|no|
personal|spotify|Spotify music player|aur|yes|spotify
```

**Fields explained:**
- `category` - Group name (development, personal, etc.)
- `name` - Package name (must match the actual package)
- `description` - Human-readable description
- `repo` - Either `official` or `aur`
- `autostart` - `yes` to add to autostart, `no` otherwise
- `startup_command` - Command to run on startup (empty if autostart=no)

### Testing Your Changes

Always test with dry-run first:

```bash
./install.sh --dry-run
```

This shows exactly what would be installed/copied without making any changes!

### Best Practices

1. **Keep it simple** - Don't add configs you don't use
2. **Test with dry-run** - Always preview changes before installing
3. **Document changes** - Update this README when adding major configs
4. **Use sync script** - Keep repo in sync with `./sync-from-system.sh`
5. **Commit regularly** - Small, focused commits are easier to track

## 🔧 Troubleshooting

### USB Input Devices Not Working on Login
- This is why we use SDDM instead of LightDM
- SDDM properly initializes USB devices on Wayland

### Volume Wheel Not Working
- Ensure PipeWire and WirePlumber are running
- Check `wpctl status` to see audio devices

### Audio/Weather Popups Not Appearing
- Ensure Python GTK dependencies are installed: `python-gobject`, `gtk3`, `gtk-layer-shell`
- Check that scripts are executable: `chmod +x ~/.config/waybar/scripts/*.py`
- GTK Layer Shell provides proper Wayland positioning but gracefully falls back if unavailable

### HiDPI Issues
- SDDM Xsetup script sets DPI to 192 (2x scaling)
- Waybar and Hyprland inherit proper scaling

## 📝 Notes

- Configured for Brazilian user (US International keyboard for accents)
- Multiple audio devices supported (gaming headsets, USB mics, etc.)
- HiDPI aware (4K primary display)
- Dual monitor setup optimized

## 🙏 Credits

- [Hyprland](https://hyprland.org/)
- [Waybar](https://github.com/Alexays/Waybar)
- Configured with assistance from Claude Code

---

**Author**: Bruno
**Last Updated**: December 29, 2024

## 📋 Recent Updates

### December 2024
- ✨ Added modular configuration arrays for easy maintenance
- ✨ Added `--dry-run` mode to preview installation without making changes
- ✨ Added `--backup-dir` option to customize backup location
- ✨ Added source structure verification before installation
- ✨ Added workstyle configuration for workspace icons
- 🔧 Refactored installer to use centralized config arrays
- 🔧 Improved backup system with dynamic config detection
- 📚 Enhanced documentation with maintenance guide
