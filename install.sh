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
    Installer for Hyprland dotfiles on Arch Linux.

    The installer will:
    - Check system requirements (Arch Linux, paru)
    - Display essential packages from packages.txt
    - Prompt for optional package categories from optional-apps.conf
    - Show installation summary before proceeding
    - Backup existing configurations
    - Install selected packages
    - Copy configuration files
    - Generate custom autostart.conf based on selections
    - Set up services and system integration

CONFIGURATION FILES:
    packages.txt         - Essential packages installed by default
    optional-apps.conf   - Optional packages grouped by category

REQUIREMENTS:
    - Arch Linux
    - paru (AUR helper) - will be auto-installed if missing

EXAMPLES:
    ./install.sh            Run the installer
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
declare -A APP_REPOS
declare -A APP_AUTOSTART
declare -A APP_STARTUP_CMDS
declare -a APP_ORDER

load_optional_apps() {
    local config_file="$SCRIPT_DIR/optional-apps.conf"

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        exit 1
    fi

    while IFS='|' read -r category name description repo autostart startup_cmd; do
        # Skip comments and empty lines
        [[ "$category" =~ ^#.*$ ]] && continue
        [[ -z "$category" ]] && continue

        local key="${category}_${name}"
        APP_CATEGORIES[$key]="$category"
        APP_NAMES[$key]="$name"
        APP_DESCRIPTIONS[$key]="$description"
        APP_REPOS[$key]="$repo"
        APP_AUTOSTART[$key]="$autostart"
        APP_STARTUP_CMDS[$key]="$startup_cmd"
        APP_ORDER+=("$key")
    done < "$config_file"
}

display_category_packages() {
    local category="$1"
    local indent="  "

    for key in "${APP_ORDER[@]}"; do
        if [[ "${APP_CATEGORIES[$key]}" == "$category" ]]; then
            local name="${APP_NAMES[$key]}"
            local description="${APP_DESCRIPTIONS[$key]}"
            local repo="${APP_REPOS[$key]}"

            if [[ -n "$description" ]]; then
                echo "${indent}✓ $name - $description [$repo]"
            else
                echo "${indent}✓ $name [$repo]"
            fi
        fi
    done
}

prompt_category_selection() {
    local category="$1"
    local category_display="$2"
    local default_install="$3"
    local is_personal="${4:-no}"

    # Get all apps in this category
    local apps=()
    local count=0

    for key in "${APP_ORDER[@]}"; do
        if [[ "${APP_CATEGORIES[$key]}" == "$category" ]]; then
            apps+=("$key")
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]]; then
        return
    fi

    echo ""
    echo -e "${BLUE}$category_display:${NC}"
    display_category_packages "$category"

    if [[ "$is_personal" == "yes" ]]; then
        echo ""
        log_warning "These apps must be installed separately (proprietary/AUR)"
        log_warning "Only enable autostart if already installed on your system"
    fi

    echo ""
    local default_answer="y"
    [[ "$default_install" != "all" ]] && default_answer="n"

    if prompt_yes_no "Install $category_display?" "$default_answer"; then
        for key in "${apps[@]}"; do
            INSTALL_OPTIONAL[$key]="yes"
        done
    fi
}

display_essential_packages() {
    local packages_file="$SCRIPT_DIR/packages.txt"

    if [[ ! -f "$packages_file" ]]; then
        log_error "Packages file not found: $packages_file"
        exit 1
    fi

    log_info "Essential Packages (will be installed automatically):"
    echo ""

    # Read and display packages with categories
    local current_category=""
    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Check if it's a category header
        if [[ "$line" =~ ^##[[:space:]](.+)$ ]]; then
            current_category="${BASH_REMATCH[1]}"
            echo -e "${BLUE}${current_category}:${NC}"
        # Skip general comments
        elif [[ "$line" =~ ^# ]]; then
            continue
        # It's a package name
        else
            echo "  ✓ $line"
        fi
    done < "$packages_file"
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
    # Create temporary package list
    local temp_packages="/tmp/install-packages-$$.txt"

    # Read core packages from packages.txt
    local packages_file="$SCRIPT_DIR/packages.txt"
    if [[ ! -f "$packages_file" ]]; then
        log_error "Packages file not found: $packages_file"
        exit 1
    fi

    # Copy essential packages (skip comments and empty lines)
    grep -v '^#' "$packages_file" | grep -v '^$' > "$temp_packages"

    # Count essential packages
    local essential_count
    essential_count=$(wc -l < "$temp_packages")

    # Add optional packages based on user selection
    local optional_count=0
    for key in "${APP_ORDER[@]}"; do
        if [[ "${INSTALL_OPTIONAL[$key]:-}" == "yes" ]]; then
            local name="${APP_NAMES[$key]}"
            local category="${APP_CATEGORIES[$key]}"

            # Skip personal apps as they must be installed separately
            if [[ "$category" != "personal" ]]; then
                echo "$name" >> "$temp_packages"
                ((optional_count++))
            fi
        fi
    done

    # Display installation summary
    echo ""
    log_info "Installation Summary"
    echo "================================================================"
    echo "Essential packages: $essential_count"
    echo "Optional packages:  $optional_count"
    echo "Total packages:     $((essential_count + optional_count))"
    echo ""

    if [[ $optional_count -gt 0 ]]; then
        echo "Optional packages to install:"
        for key in "${APP_ORDER[@]}"; do
            if [[ "${INSTALL_OPTIONAL[$key]:-}" == "yes" ]]; then
                local name="${APP_NAMES[$key]}"
                local category="${APP_CATEGORIES[$key]}"
                local description="${APP_DESCRIPTIONS[$key]}"

                if [[ "$category" != "personal" ]]; then
                    if [[ -n "$description" ]]; then
                        echo "  ✓ $name - $description"
                    else
                        echo "  ✓ $name"
                    fi
                fi
            fi
        done
        echo ""
    fi

    if ! prompt_yes_no "Proceed with package installation?" "y"; then
        log_info "Installation cancelled by user"
        rm -f "$temp_packages"
        exit 0
    fi

    # Install packages
    echo ""
    log_info "Installing packages with paru..."
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

    # Display essential packages
    echo ""
    display_essential_packages

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
