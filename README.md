# Arch Linux Dotfiles - Hyprland Setup

Personal dotfiles for Arch Linux with Hyprland window manager.

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
- **Hardware Control**: brightnessctl, playerctl
- **Personal Applications**: ProtonMail Bridge, pCloud, Das Keyboard Q, Birdtray *(AUR, will autostart)*

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

## 🎯 Installer Features

- **Config-driven**: All packages defined in `packages.txt` and `optional-apps.conf`
- **Less interactive**: Simple yes/no prompts instead of complex selections
- **Auto-install paru**: Automatically builds and installs paru if missing
- **Clear display**: Shows what will be installed with repository sources
- **Installation summary**: Review package counts before proceeding
- **Automatic backups**: Creates timestamped backups before overwriting configs
- **Dynamic autostart**: Generates `autostart.conf` based on your selections
- **Error handling**: Robust error handling with `set -euo pipefail`
- **Colored output**: Clear status messages for better readability
- **Safe operations**: Confirmation prompts before destructive operations

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
├── packages.txt           # Essential packages (always installed)
├── optional-apps.conf     # Optional packages with categories & autostart
├── install.sh             # Installation script
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
**Last Updated**: December 2024
