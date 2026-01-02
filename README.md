# Arch Linux Dotfiles - Hyprland Setup

Personal dotfiles for Arch Linux with Hyprland window manager.

**Features modular architecture, UWSM session management, and easy maintenance!**

## Table of Contents
- [Features](#-features)
- [Installation](#-installation)
- [Installer Features](#-installer-features)
- [Maintenance Guide](#-maintenance-guide)
- [Keybindings](#-keybindings)
- [Customization](#-customization)
- [Directory Structure](#-directory-structure)
- [Troubleshooting](#-troubleshooting)

## Features

- **Window Manager**: Hyprland (Wayland compositor)
- **Session Manager**: UWSM (Universal Wayland Session Manager)
- **Display Manager**: greetd with ReGreet (GTK4 greeter)
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

## System Configuration

### Display Setup
- **Primary Monitor (DP-1)**: 3840x2160@60Hz (4K, HiDPI 2x scaling)
- **Secondary Monitor (DP-2)**: Available after login
- ReGreet shows on primary monitor with proper scaling

### Keyboard Layout
- US International (with dead keys for accents)
- Configured in Hyprland

### Audio
- Multiple input/output device support
- Volume wheel integration
- PipeWire with WirePlumber
- GTK popup device selector (click microphone/speaker icons)
- Real-time device switching with visual feedback

## Installation

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
6. Install selected packages with paru
7. Copy all configuration files
8. Install greetd config and login background
9. Disable any existing display manager and enable greetd
10. Set up all configurations and enable services

**Available optional categories:**
- **File Manager**: Thunar
- **Development Tools**: Vim, Node.js, npm, git, Waydroid, Podman, Podman Desktop
- **System Monitoring**: btop
- **Hardware Control**: brightnessctl, playerctl, OpenLinkHub (Corsair), razercfg (Razer)
- **System Customization**: workstyle-git (workspace icons)
- **Personal Applications**: ProtonMail Bridge, Proton Mail, Proton Pass, pCloud Drive, Das Keyboard Q, Thunderbird, Birdtray

### Configuration Files

Package installation is controlled by two config files:

**packages.txt** - Essential packages (always installed):
```
hyprland
waybar
alacritty
uwsm
greetd
greetd-regreet
# ... etc
```

**optional-apps.conf** - Optional packages grouped by category:
```
# Format: category|name|description|repo
filemanager|thunar|Thunar file manager|official
development|vim|Vim text editor with plugins|official
personal|protonmail-bridge|ProtonMail Bridge for email clients|aur
```

This makes it easy to:
- Add/remove packages by editing config files
- See package source (official repos or AUR) for reference
- Use XDG autostart for apps that should start on login
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
   cp -r uwsm ~/.config/
   ```

3. **Install greetd configs** (requires sudo):
   ```bash
   sudo cp greetd/* /etc/greetd/
   ```

4. **Install backgrounds** (requires sudo):
   ```bash
   sudo mkdir -p /usr/share/backgrounds
   sudo cp backgrounds/* /usr/share/backgrounds/
   ```

5. **Enable greetd**:
   ```bash
   # Disable any existing display manager first
   sudo systemctl disable sddm.service  # or gdm, lightdm, etc.
   sudo systemctl enable greetd.service
   ```

6. **Reboot** and select "Hyprland (uwsm)" from ReGreet

### Syncing Changes Back to Repo

After making changes to your configs, use the sync script to backup to the repo:

```bash
./sync-from-system.sh
```

**The sync script will:**
1. Copy all configs from `~/.config` back to the repo
2. Copy `.vimrc` and `custom_ps1.sh` back to the repo
3. Optionally sync greetd configs (requires sudo)
4. Optionally sync backgrounds (requires sudo)
5. Show git diff of changes
6. Optionally commit and push changes

This makes it easy to keep your dotfiles repo in sync with your actual system configs!

## Installer Features

### Core Features
- **Config-driven**: All packages defined in `packages.txt` and `optional-apps.conf`
- **Modular architecture**: Centralized configuration arrays for easy maintenance
- **Less interactive**: Simple yes/no prompts instead of complex selections
- **Auto-install paru**: Automatically builds and installs paru if missing
- **Clear display**: Shows what will be installed with repository sources
- **Installation summary**: Review package counts before proceeding
- **Automatic backups**: Creates timestamped backups before overwriting configs
- **Display manager handling**: Automatically disables existing display managers before enabling greetd
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
- All packages that would be installed
- All directories that would be created
- All files that would be copied
- All commands that would run (including sudo commands)
- Backup locations and what would be backed up

**Perfect for:**
- Testing the installer before running it
- Validating your dotfiles structure
- Understanding what will happen on a fresh install
- Debugging installation issues

## Keybindings

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

## Customization

### Hyprland

**Modular Configuration Structure:**
The Hyprland configuration is organized into separate files for better maintainability:

- **hyprland.conf** - Main config that sources all modules
- **monitors.conf** - Display and monitor setup
- **programs.conf** - Default applications ($terminal, $fileManager, etc.)
- **autostart.conf** - Startup applications (uses `uwsm app --` for systemd integration)
- **environment.conf** - Environment variables (cursor size, Electron flags, etc.)
- **look-and-feel.conf** - Appearance, decorations, animations, layouts
- **input.conf** - Keyboard layout, mouse settings, touchpad, gestures
- **keybindings.conf** - All keyboard shortcuts and binds
- **rules.conf** - Window rules and workspace rules

**UWSM Integration:**
Apps in autostart.conf use `uwsm app --` prefix to run as systemd user units, providing better process management and logging.

**XDG Autostart:**
Personal apps that need to start on login can use XDG desktop files in `~/.config/autostart/` instead of being added to autostart.conf.

### Waybar

**Dual Bar Setup:**
Two separate Waybar instances for better organization:

- **Top Bar** (`config-top.jsonc.tpl`):
  - Left: Window title
  - Center: Clock, Weather widget
  - Right: Updates, VPN, System monitors (CPU, Memory, Disk), Network

- **Bottom Bar** (`config-bottom.jsonc.tpl`):
  - Left: Hyprland workspaces
  - Right: Media player, Audio controls (input/output/slider), System tray, Power menu

**Modular Configuration Structure:**
The Waybar configuration uses a modular approach with modules organized into separate JSON files and grouped for better organization:

- **Module Groups**:
  - `group/system` - CPU, memory, disk monitoring
  - `group/audio` - Audio input/output/slider controls
  - `group/utilities` - Updates, VPN status

- **Module Files** (`modules/*.json`): Individual JSON files for each component
- **Custom Menus** (`menus/`): XML menu files (e.g., power menu)

**Interactive Features:**
- **Audio Input/Output Selector**: Click microphone/speaker icons to open GTK device selector
  - Shows all available audio devices
  - Checkmark and bold text indicate current device
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

### ReGreet (Login Screen)

- **Theme**: Dark GTK theme matching system
- **Background**: Custom wallpaper from `backgrounds/` folder
- **Font**: JetBrainsMono Nerd Font
- **Config**: `greetd/regreet.toml` and `greetd/regreet.css`

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
- **Mode Switching**: Cycle through modes with Ctrl+Tab (Applications -> Windows -> Run -> SSH)
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

## Directory Structure

```
arch_dotfiles/
├── hypr/                  # Hyprland & Hyprlock configs
│   ├── hyprland.conf      # Main config (sources modules)
│   ├── autostart.conf     # Startup apps (uwsm integration)
│   ├── monitors.conf      # Display setup
│   └── ...                # Other modular configs
├── waybar/                # Dual Waybar setup (modular structure)
│   ├── config-top.jsonc.tpl    # Top bar configuration
│   ├── config-bottom.jsonc.tpl # Bottom bar configuration
│   ├── style.css          # Catppuccin styling
│   ├── modules/           # Modular JSON configs
│   ├── menus/             # XML menu definitions
│   └── scripts/           # Python & bash scripts
├── mako/                  # Notification daemon
├── alacritty/             # Terminal emulator
├── rofi/                  # Application launcher
├── greetd/                # Display manager configs
│   ├── config.toml        # greetd main config
│   ├── regreet.toml       # ReGreet greeter config
│   ├── regreet.css        # ReGreet styling
│   └── hyprland.conf      # Hyprland config for greeter
├── uwsm/                  # UWSM session manager
│   └── env                # Environment variables
├── backgrounds/           # Login screen backgrounds
├── xdg-desktop-portal/    # Portal config for screen sharing
├── vim/                   # Vim configuration & plugins
├── ps1/                   # Custom bash prompt
├── workstyle/             # Workstyle config (workspace icons)
├── packages.txt           # Essential packages (always installed)
├── optional-apps.conf     # Optional packages with categories
├── install.sh             # Modular installation script
├── sync-from-system.sh    # Sync system configs back to repo
└── README.md              # This file
```

## Screen Sharing

Screen sharing works with apps like Slack, Discord, Zoom, etc.

**Requirements:**
- `xdg-desktop-portal-hyprland` (included in packages.txt)
- Portal configuration (included in `xdg-desktop-portal/portals.conf`)

**Known Issues:**
- Electron apps (Slack, Discord) may require clicking multiple times to confirm screen selection
- Workaround: Press Enter instead of clicking, or click and wait a second

**Environment Variables:**
The Hyprland config includes `ELECTRON_OZONE_PLATFORM_HINT=wayland` for better Electron app support.

## Maintenance Guide

### Adding New Dotfiles

The installer uses **centralized configuration arrays** at the top of `install.sh`. This makes adding new dotfiles super easy!

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
- Verify the directory exists before installation
- Create `~/.config/neovim` directory
- Copy all files from `neovim/` to `~/.config/neovim/`
- Include it in backups

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
# Format: category|name|description|repo
development|neovim|Neovim text editor|official
personal|spotify|Spotify music player|aur
```

**Fields explained:**
- `category` - Group name (development, personal, etc.)
- `name` - Package name (must match the actual package)
- `description` - Human-readable description
- `repo` - Either `official` or `aur` (for reference only, paru handles both)

### Adding Backgrounds

Add new background images to the `backgrounds/` folder:

```bash
cp ~/Pictures/my-wallpaper.png ~/gitrepos/arch_dotfiles/backgrounds/
```

Update `greetd/regreet.toml` to use the new background:

```toml
[background]
path = "/usr/share/backgrounds/my-wallpaper.png"
```

The installer will copy all backgrounds to `/usr/share/backgrounds/`.

### Testing Your Changes

Always test with dry-run first:

```bash
./install.sh --dry-run
```

This shows exactly what would be installed/copied without making any changes!


## Troubleshooting

### Display Manager Conflicts
If greetd fails to enable due to an existing display manager:
```bash
# The installer handles this automatically, but if needed manually:
sudo systemctl disable sddm.service  # or gdm, lightdm, etc.
sudo systemctl enable greetd.service
```

### Volume Wheel Not Working
- Ensure PipeWire and WirePlumber are running
- Check `wpctl status` to see audio devices

### Audio/Weather Popups Not Appearing
- Ensure Python GTK dependencies are installed: `python-gobject`, `gtk3`, `gtk-layer-shell`
- Check that scripts are executable: `chmod +x ~/.config/waybar/scripts/*.py`
- GTK Layer Shell provides proper Wayland positioning but gracefully falls back if unavailable

### UWSM Issues
- Check UWSM logs: `journalctl --user -u uwsm-*`
- Ensure `uwsm` package is installed
- Environment variables are set in `~/.config/uwsm/env`

### ReGreet Not Showing Background
- Ensure the background file exists at the path specified in `regreet.toml`
- Check that the path is absolute (e.g., `/usr/share/backgrounds/...`)
- Verify file permissions: `ls -la /usr/share/backgrounds/`

## Notes

- Configured for Brazilian user (US International keyboard for accents)
- Multiple audio devices supported (gaming headsets, USB mics, etc.)
- HiDPI aware (4K primary display)
- Dual monitor setup optimized

## Credits

- [Hyprland](https://hyprland.org/)
- [Waybar](https://github.com/Alexays/Waybar)
- [UWSM](https://github.com/Vladimir-csp/uwsm)
- [greetd](https://git.sr.ht/~kennylevinsen/greetd) & [ReGreet](https://github.com/rharish101/ReGreet)
- Configured with assistance from Claude Code

---

**Author**: Bruno
