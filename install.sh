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

install_paru() {
    log_info "Installing paru AUR helper..."
    
    # Check for required dependencies
    if ! command -v git &> /dev/null || ! command -v make &> /dev/null; then
        log_info "Installing base-devel and git..."
        sudo pacman -S --needed --noconfirm base-devel git
    fi
    
    # Clone and build paru
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1
    
    log_info "Downloading paru from AUR..."
    git clone https://aur.archlinux.org/paru.git
    cd paru || exit 1
    
    log_info "Building and installing paru..."
    makepkg -si --noconfirm
    
    # Cleanup
    cd "$HOME" || exit 1
    rm -rf "$temp_dir"
    
    log_success "paru installed successfully"
}

check_requirements() {
    log_info "Checking system requirements..."
    
    # Check if running on Arch
    if ! command -v pacman &> /dev/null; then
        log_error "This script is for Arch Linux only"
        exit 1
    fi
    
    # Check if paru is installed
    if ! command -v paru &> /dev/null; then
        log_warning "paru AUR helper is not installed"
        echo ""
        if prompt_yes_no "Would you like to install paru now?" "y"; then
            install_paru
        else
            log_error "paru is required to continue. Exiting."
            exit 1
        fi
    fi
    
    log_success "System requirements met"
}

# ============================================================================
# Package Selection Functions
# ============================================================================

# Arrays to store app information
declare -A APP_CATEGORIES
declare -A APP_NAMES
declare -A APP_DESCRIPTIONS
declare -A APP_STARTUP_CMDS
declare -A APP_AUTOSTART
declare -a APP_ORDER

load_optional_apps() {
    local config_file="$SCRIPT_DIR/optional-apps.conf"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    local idx=0
    while IFS='|' read -r category name description startup_cmd autostart; do
        # Skip comments and empty lines
        [[ "$category" =~ ^#.*$ ]] && continue
        [[ -z "$category" ]] && continue
        
        local key="${category}_${name}"
        APP_CATEGORIES[$key]="$category"
        APP_NAMES[$key]="$name"
        APP_DESCRIPTIONS[$key]="$description"
        APP_STARTUP_CMDS[$key]="$startup_cmd"
        APP_AUTOSTART[$key]="$autostart"
        APP_ORDER[idx]="$key"
        ((idx++))
    done < "$config_file"
}

prompt_category_selection() {
    local category="$1"
    local category_display="$2"
    local default_install="$3"
    local is_personal="${4:-no}"
    
    # Get all apps in this category
    local apps=()
    local app_list=""
    local count=0
    
    for key in "${APP_ORDER[@]}"; do
        if [[ "${APP_CATEGORIES[$key]}" == "$category" ]]; then
            apps+=("$key")
            ((count++))
            app_list+="    $count) ${APP_NAMES[$key]}"
            if [[ -n "${APP_DESCRIPTIONS[$key]}" ]]; then
                app_list+=" - ${APP_DESCRIPTIONS[$key]}"
            fi
            app_list+=$'\n'
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        return
    fi
    
    echo ""
    log_info "$category_display"
    echo "================================================================"
    
    if [[ "$is_personal" == "yes" ]]; then
        log_warning "These apps must be installed separately (proprietary/AUR)."
        log_warning "Only select if already installed on your system."
        echo ""
    fi
    
    echo -e "$app_list"
    
    # Ask for selection
    echo "Enter numbers separated by spaces (e.g., '1 3 4'), 'all' for all, or 'none' for none"
    if [[ "$default_install" == "all" ]]; then
        echo -n "Default: all [Enter to select all]: "
    else
        echo -n "Selection: "
    fi
    
    read -r selection
    
    # Handle empty input (default)
    if [[ -z "$selection" ]] && [[ "$default_install" == "all" ]]; then
        selection="all"
    fi
    
    # Process selection
    if [[ "$selection" == "all" ]]; then
        for key in "${apps[@]}"; do
            INSTALL_OPTIONAL[$key]="yes"
        done
    elif [[ "$selection" != "none" ]]; then
        # Parse number selection
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le $count ]]; then
                local idx=$((num - 1))
                INSTALL_OPTIONAL[${apps[$idx]}]="yes"
            fi
        done
    fi
}

prompt_optional_packages() {
    load_optional_apps
    
    echo ""
    log_info "Optional Package Selection"
    echo "================================================================"
    echo "Select which optional packages you want to install."
    echo ""
    
    # File Manager
    prompt_category_selection "filemanager" "File Manager" "all" "no"
    
    # Development Tools
    prompt_category_selection "development" "Development Tools" "all" "no"
    
    # System Monitoring
    prompt_category_selection "monitoring" "System Monitoring" "all" "no"
    
    # Hardware Control
    prompt_category_selection "hardware" "Hardware Control" "all" "no"
    
    # Personal Applications
    prompt_category_selection "personal" "Personal Applications (Startup Apps)" "none" "yes"
    
    echo ""
    log_info "Selection complete!"
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
    for key in "${APP_ORDER[@]}"; do
        if [[ "${INSTALL_OPTIONAL[$key]:-}" == "yes" ]]; then
            local name="${APP_NAMES[$key]}"
            local category="${APP_CATEGORIES[$key]}"
            
            # Skip personal apps as they must be installed separately
            if [[ "$category" != "personal" ]]; then
                echo "$name" >> "$temp_packages"
            fi
        fi
    done
    
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
    
    # Add applications based on user selection
    local has_personal_apps=false
    
    for key in "${APP_ORDER[@]}"; do
        if [[ "${INSTALL_OPTIONAL[$key]:-}" == "yes" ]]; then
            local autostart="${APP_AUTOSTART[$key]}"
            
            if [[ "$autostart" == "yes" ]]; then
                local name="${APP_NAMES[$key]}"
                local startup_cmd="${APP_STARTUP_CMDS[$key]}"
                local description="${APP_DESCRIPTIONS[$key]}"
                
                # Add comment with description
                if [[ -n "$description" ]]; then
                    echo "# $description" >> "$autostart_file"
                else
                    echo "# $name" >> "$autostart_file"
                fi
                
                # Add startup command
                echo "exec-once = $startup_cmd" >> "$autostart_file"
                has_personal_apps=true
            fi
        fi
    done
    
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
    # Check if vim was selected
    local vim_selected=false
    for key in "${APP_ORDER[@]}"; do
        if [[ "${APP_CATEGORIES[$key]}" == "development" ]] && [[ "${APP_NAMES[$key]}" == "vim" ]] && [[ "${INSTALL_OPTIONAL[$key]:-}" == "yes" ]]; then
            vim_selected=true
            break
        fi
    done
    
    if [[ "$vim_selected" == "false" ]]; then
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
    
    # Check if vim is installed
    for key in "${APP_ORDER[@]}"; do
        if [[ "${APP_CATEGORIES[$key]}" == "development" ]] && [[ "${APP_NAMES[$key]}" == "vim" ]] && [[ "${INSTALL_OPTIONAL[$key]:-}" == "yes" ]]; then
            echo "  ✓ Vim with NERDTree, coc.nvim, and colorschemes"
            break
        fi
    done
    
    echo "  ✓ Custom colorful bash prompt with git branch"
    echo "  ✓ PipeWire audio with GTK device selector popups"
    echo "  ✓ Weather widget with interactive forecast popup"
    
    # List other installed optional packages
    for key in "${APP_ORDER[@]}"; do
        if [[ "${INSTALL_OPTIONAL[$key]:-}" == "yes" ]]; then
            local name="${APP_NAMES[$key]}"
            local description="${APP_DESCRIPTIONS[$key]}"
            local category="${APP_CATEGORIES[$key]}"
            
            # Skip vim (already shown above) and personal apps
            if [[ "$name" != "vim" ]] && [[ "$category" != "personal" ]]; then
                if [[ -n "$description" ]]; then
                    echo "  ✓ $description"
                else
                    echo "  ✓ $name"
                fi
            fi
        fi
    done
    
    # Show personal apps with autostart
    local has_autostart=false
    for key in "${APP_ORDER[@]}"; do
        if [[ "${INSTALL_OPTIONAL[$key]:-}" == "yes" ]] && [[ "${APP_AUTOSTART[$key]}" == "yes" ]]; then
            if [[ "$has_autostart" == "false" ]]; then
                echo ""
                echo "Autostart apps:"
                has_autostart=true
            fi
            local description="${APP_DESCRIPTIONS[$key]}"
            local name="${APP_NAMES[$key]}"
            if [[ -n "$description" ]]; then
                echo "  ✓ $description"
            else
                echo "  ✓ $name"
            fi
        fi
    done
    
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
