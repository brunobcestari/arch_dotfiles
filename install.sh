#!/bin/bash
# Hyprland Dotfiles Installation Script

set -euo pipefail

# ============================================================================
# Configuration Variables
# ============================================================================

SCRIPT_DIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

readonly CONFIG_HOME="${HOME}/.config"

BACKUP_DIR=""
BACKUP_DIR="${HOME}/.config-backup-$(date +%Y%m%d-%H%M%S)"
readonly BACKUP_DIR

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# User choices
declare -A INSTALL_OPTIONAL

# ============================================================================
# Help & Usage
# ============================================================================

show_help() {
    cat << 'EOF'
Hyprland Dotfiles Installation Script

USAGE:
    ./install.sh [OPTIONS]

OPTIONS:
    -h, --help      Show this help message and exit
    
DESCRIPTION:
    Interactive installer for Hyprland dotfiles on Arch Linux.
    
    The installer will:
    - Check system requirements (Arch Linux, paru)
    - Interactively prompt for optional package selection
    - Backup existing configurations
    - Install selected packages
    - Copy configuration files
    - Generate custom autostart.conf based on selections
    - Set up services and system integration
    
REQUIREMENTS:
    - Arch Linux
    - paru (AUR helper)
    
    To install paru:
        sudo pacman -S --needed base-devel git
        git clone https://aur.archlinux.org/paru.git
        cd paru && makepkg -si

EXAMPLES:
    ./install.sh            Run the interactive installer
    ./install.sh --help     Show this help message

EOF
}

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local answer
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -r -p "$prompt" answer
    answer="${answer:-$default}"
    
    [[ "$answer" =~ ^[Yy]$ ]]
}

cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Installation failed with exit code $exit_code"
        log_info "You can restore from backup at: $BACKUP_DIR"
    fi
    exit "$exit_code"
}

# ============================================================================
# Validation Functions
# ============================================================================

check_requirements() {
    log_info "Checking system requirements..."
    
    # Check if running on Arch
    if ! command -v pacman &> /dev/null; then
        log_error "This script is for Arch Linux only"
        exit 1
    fi
    
    # Check if paru is installed
    if ! command -v paru &> /dev/null; then
        log_error "paru not found. Please install paru first."
        echo ""
        echo "Install paru with:"
        echo "  sudo pacman -S --needed base-devel git"
        echo "  git clone https://aur.archlinux.org/paru.git"
        echo "  cd paru && makepkg -si"
        exit 1
    fi
    
    log_success "System requirements met"
}

# ============================================================================
# Package Selection Functions
# ============================================================================

prompt_optional_packages() {
    echo ""
    log_info "Optional Package Selection"
    echo "================================================================"
    echo ""
    
    # File manager
    if prompt_yes_no "Install Thunar file manager?" "y"; then
        INSTALL_OPTIONAL[thunar]="yes"
    fi
    
    # Development tools
    if prompt_yes_no "Install development tools (Vim with plugins, Node.js, npm, git)?" "y"; then
        INSTALL_OPTIONAL[development]="yes"
    fi
    
    # System monitoring
    if prompt_yes_no "Install btop system monitor?" "y"; then
        INSTALL_OPTIONAL[btop]="yes"
    fi
    
    # Brightness control
    if prompt_yes_no "Install brightnessctl (laptop brightness control)?" "y"; then
        INSTALL_OPTIONAL[brightnessctl]="yes"
    fi
    
    # Media player control
    if prompt_yes_no "Install playerctl (media player control)?" "y"; then
        INSTALL_OPTIONAL[playerctl]="yes"
    fi
    
    # Personal applications
    echo ""
    log_info "Personal Applications (startup apps)"
    echo "These will be added to Hyprland autostart if installed:"
    echo ""
    
    if prompt_yes_no "Do you use ProtonMail Bridge?" "n"; then
        INSTALL_OPTIONAL[protonmail]="yes"
    fi
    
    if prompt_yes_no "Do you use pCloud?" "n"; then
        INSTALL_OPTIONAL[pcloud]="yes"
    fi
    
    if prompt_yes_no "Do you use Das Keyboard Q?" "n"; then
        INSTALL_OPTIONAL[daskeyboard]="yes"
    fi
    
    if prompt_yes_no "Do you use Birdtray (Thunderbird tray icon)?" "n"; then
        INSTALL_OPTIONAL[birdtray]="yes"
    fi
}

install_packages() {
    log_info "Installing packages..."
    
    # Create temporary package list
    local temp_packages="/tmp/install-packages-$$.txt"
    
    # Core packages (always install)
    cat > "$temp_packages" << 'EOF'
# Core Hyprland
hyprland
hyprlock
xdg-desktop-portal-hyprland

# Display Manager
sddm

# Status Bar & Widgets
waybar
wttrbar

# Notifications
mako

# Terminal
alacritty

# Application Launcher
rofi

# Audio (PipeWire)
pipewire
wireplumber
pipewire-pulse
pipewire-alsa
pipewire-jack
pwvucontrol

# Python & GTK (for Waybar popups)
python-gobject
gtk3
gtk-layer-shell

# Utilities
wev
evtest
curl

# Fonts (for icons and UI)
ttf-font-awesome
noto-fonts
noto-fonts-emoji
EOF
    
    # Add optional packages based on user selection
    if [[ "${INSTALL_OPTIONAL[thunar]:-}" == "yes" ]]; then
        echo "thunar" >> "$temp_packages"
    fi
    
    if [[ "${INSTALL_OPTIONAL[development]:-}" == "yes" ]]; then
        {
            echo "vim"
            echo "nodejs"
            echo "npm"
            echo "git"
        } >> "$temp_packages"
    fi
    
    if [[ "${INSTALL_OPTIONAL[btop]:-}" == "yes" ]]; then
        echo "btop" >> "$temp_packages"
    fi
    
    if [[ "${INSTALL_OPTIONAL[brightnessctl]:-}" == "yes" ]]; then
        echo "brightnessctl" >> "$temp_packages"
    fi
    
    if [[ "${INSTALL_OPTIONAL[playerctl]:-}" == "yes" ]]; then
        echo "playerctl" >> "$temp_packages"
    fi
    
    # Install packages
    log_info "Installing selected packages with paru..."
    if paru -S --needed - < "$temp_packages"; then
        log_success "Packages installed successfully"
    else
        log_error "Package installation failed"
        rm -f "$temp_packages"
        exit 1
    fi
    
    rm -f "$temp_packages"
}

# ============================================================================
# Configuration Functions
# ============================================================================

backup_existing_configs() {
    log_info "Backing up existing configurations..."
    
    local configs_to_backup=(
        "$CONFIG_HOME/hypr"
        "$CONFIG_HOME/waybar"
        "$CONFIG_HOME/mako"
        "$CONFIG_HOME/alacritty"
        "$CONFIG_HOME/xdg-desktop-portal"
        "$CONFIG_HOME/rofi"
        "$HOME/.vimrc"
        "$HOME/.bashrc"
    )
    
    local needs_backup=false
    for config in "${configs_to_backup[@]}"; do
        if [[ -e "$config" ]]; then
            needs_backup=true
            break
        fi
    done
    
    if [[ "$needs_backup" == "true" ]]; then
        if ! prompt_yes_no "Existing configurations found. Create backup?" "y"; then
            if ! prompt_yes_no "Continue without backup? (existing configs will be overwritten)" "n"; then
                log_info "Installation cancelled by user"
                exit 0
            fi
            return
        fi
        
        mkdir -p "$BACKUP_DIR"
        for config in "${configs_to_backup[@]}"; do
            if [[ -e "$config" ]]; then
                local parent_dir
                parent_dir="$(dirname "$config")"
                local backup_parent="$BACKUP_DIR${parent_dir#"$HOME"}"
                mkdir -p "$backup_parent"
                cp -r "$config" "$backup_parent/" 2>/dev/null || true
            fi
        done
        log_success "Backup created at: $BACKUP_DIR"
    fi
}

create_config_directories() {
    log_info "Creating config directories..."
    mkdir -p "$CONFIG_HOME"/{hypr,waybar,mako,alacritty,xdg-desktop-portal,rofi}
    mkdir -p "$CONFIG_HOME/waybar"/{scripts,modules,menus}
    log_success "Config directories created"
}

copy_configuration_files() {
    log_info "Copying configuration files..."
    
    # Copy core configs
    cp -r "$SCRIPT_DIR/hypr"/* "$CONFIG_HOME/hypr/"
    cp -r "$SCRIPT_DIR/mako"/* "$CONFIG_HOME/mako/"
    cp -r "$SCRIPT_DIR/alacritty"/* "$CONFIG_HOME/alacritty/"
    cp -r "$SCRIPT_DIR/xdg-desktop-portal"/* "$CONFIG_HOME/xdg-desktop-portal/"
    
    # Copy Rofi config
    if [[ -d "$SCRIPT_DIR/rofi" ]]; then
        cp -r "$SCRIPT_DIR/rofi"/* "$CONFIG_HOME/rofi/"
    fi
    
    # Copy Waybar configs with modular structure
    cp "$SCRIPT_DIR/waybar/config-top.jsonc" "$CONFIG_HOME/waybar/"
    cp "$SCRIPT_DIR/waybar/config-bottom.jsonc" "$CONFIG_HOME/waybar/"
    cp "$SCRIPT_DIR/waybar/style.css" "$CONFIG_HOME/waybar/"
    cp -r "$SCRIPT_DIR/waybar/scripts"/* "$CONFIG_HOME/waybar/scripts/"
    cp -r "$SCRIPT_DIR/waybar/modules"/* "$CONFIG_HOME/waybar/modules/"
    cp -r "$SCRIPT_DIR/waybar/menus"/* "$CONFIG_HOME/waybar/menus/" 2>/dev/null || true
    
    # Make waybar scripts executable
    chmod +x "$CONFIG_HOME/waybar/scripts"/*.sh 2>/dev/null || true
    chmod +x "$CONFIG_HOME/waybar/scripts"/*.py 2>/dev/null || true
    
    log_success "Configuration files copied"
}

generate_autostart_config() {
    log_info "Generating autostart configuration..."
    
    local autostart_file="$CONFIG_HOME/hypr/autostart.conf"
    
    cat > "$autostart_file" << 'EOF'
#################
### AUTOSTART ###
#################

# Autostart necessary processes (like notifications daemons, status bars, etc.)
# See https://wiki.hypr.land/Configuring/Keywords/

EOF
    
    # Add personal applications based on user selection
    local has_personal_apps=false
    
    if [[ "${INSTALL_OPTIONAL[protonmail]:-}" == "yes" ]]; then
        echo "# ProtonMail Bridge" >> "$autostart_file"
        echo "exec-once = protonmail-bridge" >> "$autostart_file"
        has_personal_apps=true
    fi
    
    if [[ "${INSTALL_OPTIONAL[pcloud]:-}" == "yes" ]]; then
        echo "# pCloud" >> "$autostart_file"
        echo "exec-once = env DESKTOPINTEGRATION=false /usr/bin/pcloud" >> "$autostart_file"
        has_personal_apps=true
    fi
    
    if [[ "${INSTALL_OPTIONAL[daskeyboard]:-}" == "yes" ]]; then
        echo "# Das Keyboard Q" >> "$autostart_file"
        echo "exec-once = das-keyboard-q %U" >> "$autostart_file"
        has_personal_apps=true
    fi
    
    if [[ "${INSTALL_OPTIONAL[birdtray]:-}" == "yes" ]]; then
        echo "# Birdtray (Thunderbird system tray)" >> "$autostart_file"
        echo "exec-once = gtk-launch /usr/share/applications/com.ulduzsoft.Birdtray.desktop" >> "$autostart_file"
        has_personal_apps=true
    fi
    
    if [[ "$has_personal_apps" == "true" ]]; then
        echo "" >> "$autostart_file"
    fi
    
    # Add essential autostart entries
    cat >> "$autostart_file" << 'EOF'
# Start Waybar (top and bottom bars)
exec-once = waybar -c ~/.config/waybar/config-top.jsonc
exec-once = waybar -c ~/.config/waybar/config-bottom.jsonc

# Start Mako (notifications)
exec-once = mako
EOF
    
    log_success "Autostart configuration generated"
}

install_sddm_configs() {
    log_info "Installing SDDM configs (requires sudo)..."
    
    if ! sudo -v; then
        log_error "sudo access required for SDDM installation"
        exit 1
    fi
    
    sudo mkdir -p /etc/sddm.conf.d
    
    # Copy SDDM conf files
    local found_conf=false
    for conf_file in "$SCRIPT_DIR/sddm"/*.conf; do
        if [[ -f "$conf_file" ]]; then
            sudo cp "$conf_file" /etc/sddm.conf.d/
            found_conf=true
        fi
    done
    [[ "$found_conf" == "false" ]] && log_warning "No SDDM conf files found"
    
    # Copy Xsetup script
    if [[ -f "$SCRIPT_DIR/sddm/Xsetup" ]]; then
        sudo cp "$SCRIPT_DIR/sddm/Xsetup" /usr/share/sddm/scripts/Xsetup
        sudo chmod +x /usr/share/sddm/scripts/Xsetup
    else
        log_warning "No Xsetup script found"
    fi
    
    log_success "SDDM configs installed"
}

setup_vim() {
    if [[ "${INSTALL_OPTIONAL[development]:-}" != "yes" ]]; then
        log_info "Skipping Vim setup (not selected)"
        return
    fi
    
    log_info "Setting up Vim with plugins..."
    
    # Install vim-plug if not already installed
    if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
        log_info "Installing vim-plug..."
        curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    
    # Copy vimrc
    cp "$SCRIPT_DIR/vim/vimrc" "$HOME/.vimrc"
    
    # Install vim plugins
    log_info "Installing Vim plugins (this may take a moment)..."
    vim +PlugInstall +qall || log_warning "Vim plugins will install on first vim launch"
    
    log_success "Vim setup complete"
}

setup_custom_ps1() {
    log_info "Setting up custom PS1 (bash prompt)..."
    
    # Copy custom PS1 to system profile.d
    sudo cp "$SCRIPT_DIR/ps1/custom_ps1.sh" /etc/profile.d/custom_ps1.sh
    sudo chmod +x /etc/profile.d/custom_ps1.sh
    
    # Add sourcing to .bashrc if not already there
    if ! grep -q "custom_ps1.sh" "$HOME/.bashrc" 2>/dev/null; then
        {
            echo ""
            echo "# Custom PS1 prompt"
            echo "if [ -f /etc/profile.d/custom_ps1.sh ]; then"
            echo "   . /etc/profile.d/custom_ps1.sh"
            echo "fi"
        } >> "$HOME/.bashrc"
        log_success "Added custom PS1 to .bashrc"
    else
        log_info "Custom PS1 already in .bashrc"
    fi
}

enable_services() {
    log_info "Enabling services..."
    sudo systemctl enable sddm.service
    log_success "Services enabled"
}

# ============================================================================
# Main Function
# ============================================================================

show_summary() {
    echo ""
    log_success "=== Installation Complete! ==="
    echo ""
    echo "To finish setup:"
    echo "1. Reboot your system (or log out and back in for PS1)"
    echo "2. Select 'Hyprland' from SDDM login screen"
    echo "3. Press Super+Return to open terminal"
    echo "4. Enjoy your setup!"
    echo ""
    echo "What's installed:"
    echo "  ✓ Hyprland with Waybar, Mako, Hyprlock"
    echo "  ✓ Alacritty terminal with Tokyo Night theme"
    
    if [[ "${INSTALL_OPTIONAL[development]:-}" == "yes" ]]; then
        echo "  ✓ Vim with NERDTree, coc.nvim, and colorschemes"
    fi
    
    echo "  ✓ Custom colorful bash prompt with git branch"
    echo "  ✓ PipeWire audio with GTK device selector popups"
    echo "  ✓ Weather widget with interactive forecast popup"
    
    if [[ "${INSTALL_OPTIONAL[thunar]:-}" == "yes" ]]; then
        echo "  ✓ Thunar file manager"
    fi
    
    if [[ "${INSTALL_OPTIONAL[btop]:-}" == "yes" ]]; then
        echo "  ✓ btop system monitor"
    fi
    
    echo ""
    echo "Keybindings:"
    echo "  Super+Return    - Terminal"
    echo "  Super+D         - App launcher (rofi)"
    echo "  Super+L         - Lock screen"
    echo "  Super+Shift+Q   - Close window"
    echo "  Super+Shift+E   - Exit Hyprland"
    echo ""
    
    if [[ -n "${BACKUP_DIR:-}" ]] && [[ -d "$BACKUP_DIR" ]]; then
        echo "Backup location: $BACKUP_DIR"
        echo ""
    fi
}

main() {
    # Parse command line arguments
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # Set up error handling
    trap cleanup EXIT
    
    echo "=== Hyprland Dotfiles Installer ==="
    echo ""
    
    # Run checks
    check_requirements
    
    # Prompt for optional packages
    prompt_optional_packages
    
    echo ""
    log_info "Starting installation..."
    echo ""
    
    # Installation steps
    backup_existing_configs
    install_packages
    create_config_directories
    copy_configuration_files
    generate_autostart_config
    install_sddm_configs
    setup_vim
    setup_custom_ps1
    enable_services
    
    # Show summary
    show_summary
}

# Run main function
main "$@"
