# Arch Linux Dotfiles - Hyprland Setup

Personal dotfiles for Arch Linux with Hyprland window manager.

## 🎨 Features

- **Window Manager**: Hyprland (Wayland compositor)
- **Display Manager**: SDDM with HiDPI support
- **Status Bar**: Waybar with custom styling
- **Terminal**: Alacritty with Tokyo Night theme
- **Notifications**: Mako
- **Lock Screen**: Hyprlock
- **App Launcher**: Rofi
- **Audio**: PipeWire with WirePlumber
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
- PipeWire with pwvucontrol for device management

## 📦 Installation

### Quick Install

```bash
git clone <your-repo-url> ~/gitrepos/arch_dotfiles
cd ~/gitrepos/arch_dotfiles
./install.sh
```

### Manual Install

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

### Waybar
- Click volume icon to open pwvucontrol (audio device selector)
- Middle-click volume icon to mute/unmute
- Scroll on volume icon to adjust volume
- Custom styling in `waybar/style.css`

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
├── waybar/                # Waybar status bar
├── mako/                  # Notification daemon
├── alacritty/             # Terminal emulator
├── sddm/                  # Display manager configs
├── xdg-desktop-portal/    # Portal config for screen sharing
├── vim/                   # Vim configuration & plugins
├── ps1/                   # Custom bash prompt
├── packages.txt           # Package dependencies
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
