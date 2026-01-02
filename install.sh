#!/bin/bash
# Hyprland Dotfiles Installation Script

set -euo pipefail

# ============================================================================
# Configuration Variables
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

readonly CONFIG_HOME="${HOME}/.config"

# Backup directory (can be overridden with --backup-dir)
BACKUP_DIR="${HOME}/.config-backup-$(date +%Y%m%d-%H%M%S)"

# ============================================================================
# Dotfiles Configuration
# ============================================================================
# Add new dotfiles here to have them automatically installed

# Standard config directories (source -> ~/.config/destination)
# Format: "source_dir:destination_dir" or just "dir" if source and dest are the same
readonly CONFIG_DIRS=(
    "hypr"
    "mako"
    "alacritty"
    "xdg-desktop-portal"
    "rofi"
    "waybar"
    "uwsm"
)

# Home directory files (source -> ~/destination)
# Format: "source_path:destination_filename"
readonly HOME_FILES=(
    "vim/vimrc:.vimrc"
)

# Conditional configs (package_name:source_dir:dest_dir)
readonly CONDITIONAL_CONFIGS=(
    "workstyle-git:workstyle:workstyle"
)

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# Dry-run mode
DRY_RUN=false

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
    -h, --help              Show this help message and exit
    -d, --dry-run           Show what would be done without making changes
    -b, --backup-dir DIR    Specify custom backup directory (default: ~/.config-backup-YYYYMMDD-HHMMSS)

DESCRIPTION:
    Installer for Hyprland dotfiles on Arch Linux.

    The installer will:
    - Check system requirements (Arch Linux, paru)
    - Display essential packages from packages.txt
    - Prompt for optional package categories from optional-apps.conf
    - Show installation summary before proceeding
    - Backup existing configurations
    - Install selected packages with paru
    - Copy configuration files
    - Set up services and system integration
    - Optionally configure display settings (resolution, position, scale)

CONFIGURATION FILES:
    packages.txt         - Essential packages installed by default
    optional-apps.conf   - Optional packages grouped by category

REQUIREMENTS:
    - Arch Linux
    - paru (AUR helper) - will be auto-installed if missing

EXAMPLES:
    ./install.sh                              Run the installer
    ./install.sh --dry-run                    Preview what would be installed
    ./install.sh --backup-dir ~/my-backups    Use custom backup directory
    ./install.sh --help                       Show this help message

EOF
}

# ============================================================================
# Helper Functions
# ============================================================================

run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would run: $*"
        return 0
    else
        "$@"
    fi
}

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

# Check if a package was selected for installation
# Usage: is_package_selected "package_name"
is_package_selected() {
    local package_name="$1"
    for key in "${APP_ORDER[@]}"; do
        if [[ "${APP_NAMES[$key]}" == "$package_name" ]] && [[ "${INSTALL_OPTIONAL[$key]:-}" == "yes" ]]; then
            return 0
        fi
    done
    return 1
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

verify_source_structure() {
    log_info "Verifying dotfiles structure..."

    local missing=()

    # Check essential files
    local essential_files=(
        "$SCRIPT_DIR/packages.txt"
        "$SCRIPT_DIR/optional-apps.conf"
        "$SCRIPT_DIR/greetd/config.toml"
        "$SCRIPT_DIR/ps1/custom_ps1.sh"
        "$SCRIPT_DIR/backgrounds"
    )

    for item in "${essential_files[@]}"; do
        if [[ ! -e "$item" ]]; then
            missing+=("$item")
        fi
    done

    # Check config directories
    for dir in "${CONFIG_DIRS[@]}"; do
        local source_dir="${dir%%:*}"  # Get part before : if exists
        if [[ ! -d "$SCRIPT_DIR/$source_dir" ]]; then
            missing+=("$SCRIPT_DIR/$source_dir")
        fi
    done

    # Check home files
    for file_mapping in "${HOME_FILES[@]}"; do
        local source_file="${file_mapping%%:*}"
        if [[ ! -f "$SCRIPT_DIR/$source_file" ]]; then
            missing+=("$SCRIPT_DIR/$source_file")
        fi
    done

    # Check conditional configs (these might not exist, so just warn)
    for config in "${CONDITIONAL_CONFIGS[@]}"; do
        local source_dir
        IFS=':' read -r _ source_dir _ <<< "$config"
        if [[ ! -d "$SCRIPT_DIR/$source_dir" ]]; then
            log_warning "Optional config not found: $SCRIPT_DIR/$source_dir (will skip if selected)"
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required files/directories:"
        printf '  %s\n' "${missing[@]}"
        exit 1
    fi

    log_success "Dotfiles structure verified"
}

# ============================================================================
# Package Selection Functions
# ============================================================================

# Arrays to store app information
declare -A APP_CATEGORIES
declare -A APP_NAMES
declare -A APP_DESCRIPTIONS
declare -A APP_REPOS
declare -a APP_ORDER

load_optional_apps() {
    local config_file="$SCRIPT_DIR/optional-apps.conf"

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        exit 1
    fi

    while IFS='|' read -r category name description repo; do
        # Skip comments and empty lines
        [[ "$category" =~ ^#.*$ ]] && continue
        [[ -z "$category" ]] && continue

        local key="${category}_${name}"
        APP_CATEGORIES[$key]="$category"
        APP_NAMES[$key]="$name"
        APP_DESCRIPTIONS[$key]="$description"
        APP_REPOS[$key]="$repo"
        APP_ORDER+=("$key")
    done < "$config_file"
}

# Interactive multi-select menu for package selection
# Usage: multiselect_menu "Category Name" category_key
multiselect_menu() {
    local category_display="$1"
    local category="$2"

    # Get all apps in this category
    local -a keys=()
    local -a selected=()

    for key in "${APP_ORDER[@]}"; do
        if [[ "${APP_CATEGORIES[$key]}" == "$category" ]]; then
            keys+=("$key")
            selected+=(1)  # All selected by default
        fi
    done

    local count=${#keys[@]}
    if [[ $count -eq 0 ]]; then
        return
    fi

    local cur=0
    local esc
    esc=$(printf '\033')

    echo ""
    echo -e "${BLUE}${category_display}:${NC}"
    echo -e "${YELLOW}  Use ↑/↓ to navigate, SPACE or ENTER to confirm, any key to toggle${NC}"
    echo ""

    # Clear any pending input in the buffer and wait a moment
    read -t 0.1 -n 10000 discard < /dev/tty 2>/dev/null || true
    sleep 0.1

    # Hide cursor and set trap to restore it on interrupt
    printf '\033[?25l'
    trap 'printf "\033[?25h"; exit 130' INT

    while true; do
        # Render the menu
        local index=0
        for key in "${keys[@]}"; do
            local name="${APP_NAMES[$key]}"
            local description="${APP_DESCRIPTIONS[$key]}"
            local repo="${APP_REPOS[$key]}"

            # Build the checkbox
            local checkbox
            if [[ ${selected[$index]} -eq 1 ]]; then
                checkbox="${GREEN}[x]${NC}"
            else
                checkbox="[ ]"
            fi

            # Build the label
            local label
            if [[ -n "$description" ]]; then
                label="$name - $description ${BLUE}[$repo]${NC}"
            else
                label="$name ${BLUE}[$repo]${NC}"
            fi

            # Highlight current item
            if [[ $index -eq $cur ]]; then
                echo -e "  ${YELLOW}>${NC} $checkbox $label"
            else
                echo -e "    $checkbox $label"
            fi

            ((++index))
        done

        # Read user input from terminal
        read -rsn1 key < /dev/tty

        if [[ "$key" == "$esc" ]]; then
            # Read the rest of the escape sequence
            read -rsn2 -t 0.1 key < /dev/tty
            if [[ "$key" == "[A" ]]; then
                # Up arrow
                if [[ $cur -eq 0 ]]; then
                    cur=$((count - 1))
                else
                    cur=$((cur - 1))
                fi
            elif [[ "$key" == "[B" ]]; then
                # Down arrow
                cur=$((cur + 1))
                if [[ $cur -ge $count ]]; then
                    cur=0
                fi
            fi
        elif [[ -z "$key" ]]; then
            # Enter - confirm (empty string)
            break
        else
            # Any other key (including space) - toggle selection
            if [[ ${selected[$cur]} -eq 1 ]]; then
                selected[$cur]=0
            else
                selected[$cur]=1
            fi
        fi

        # Move cursor up to re-render
        printf '\033[%dA' "$count"
    done

    # Show cursor and reset trap
    printf '\033[?25h'
    trap - INT

    # Save selections to INSTALL_OPTIONAL
    local index=0
    for key in "${keys[@]}"; do
        if [[ ${selected[$index]} -eq 1 ]]; then
            INSTALL_OPTIONAL[$key]="yes"
        fi
        ((++index))
    done

    echo ""
}

# Get unique categories from loaded apps (preserves order of first appearance)
# Populates the global UNIQUE_CATEGORIES array
declare -a UNIQUE_CATEGORIES
get_unique_categories() {
    UNIQUE_CATEGORIES=()
    local -a seen=()

    for key in "${APP_ORDER[@]}"; do
        local cat="${APP_CATEGORIES[$key]}"
        local found=0

        for s in "${seen[@]}"; do
            if [[ "$s" == "$cat" ]]; then
                found=1
                break
            fi
        done

        if [[ $found -eq 0 ]]; then
            seen+=("$cat")
            UNIQUE_CATEGORIES+=("$cat")
        fi
    done
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

    # Get unique categories dynamically from the config
    get_unique_categories

    # In dry-run mode, show all packages without interactive menu
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "All optional packages would be available for selection:"
        echo ""

        for category in "${UNIQUE_CATEGORIES[@]}"; do
            local display_name
            display_name=$category
            echo -e "${BLUE}${display_name}:${NC}"

            for key in "${APP_ORDER[@]}"; do
                if [[ "${APP_CATEGORIES[$key]}" == "$category" ]]; then
                    local name="${APP_NAMES[$key]}"
                    local description="${APP_DESCRIPTIONS[$key]}"
                    local repo="${APP_REPOS[$key]}"

                    if [[ -n "$description" ]]; then
                        echo "    [x] $name - $description [$repo]"
                    else
                        echo "    [x] $name [$repo]"
                    fi

                    # Mark all as selected for dry-run
                    INSTALL_OPTIONAL[$key]="yes"
                fi
            done
            echo ""
        done

        log_info "Dry-run: All optional packages selected"
        return
    fi

    echo "For each category, select packages to install."
    echo "All packages are selected by default."

    # Loop through each category
    for category in "${UNIQUE_CATEGORIES[@]}"; do
        local display_name
        display_name=$category
        multiselect_menu "$display_name" "$category"
    done

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
            echo "$name" >> "$temp_packages"
            optional_count=$((optional_count + 1))
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
                local description="${APP_DESCRIPTIONS[$key]}"
                local repo="${APP_REPOS[$key]}"

                if [[ -n "$description" ]]; then
                    echo "  ✓ $name - $description [$repo]"
                else
                    echo "  ✓ $name [$repo]"
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
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would install packages:"
        sed 's/^/  - /' "$temp_packages"
    else
        if paru -S --noconfirm --needed - < "$temp_packages"; then
            log_success "Packages installed successfully"
        else
            log_error "Package installation failed"
            rm -f "$temp_packages"
            exit 1
        fi
    fi

    rm -f "$temp_packages"
}

# ============================================================================
# Configuration Functions
# ============================================================================

backup_existing_configs() {
    log_info "Backing up existing configurations..."

    local configs_to_backup=()

    # Add config directories
    for dir in "${CONFIG_DIRS[@]}"; do
        local dest_dir="${dir##*:}"  # Get part after : if exists, otherwise whole string
        configs_to_backup+=("$CONFIG_HOME/$dest_dir")
    done

    # Add home files
    for file_mapping in "${HOME_FILES[@]}"; do
        local dest_file="${file_mapping##*:}"
        configs_to_backup+=("$HOME/$dest_file")
    done

    # Add .bashrc (for PS1 modifications)
    configs_to_backup+=("$HOME/.bashrc")

    # Add conditional configs if they exist
    for config in "${CONDITIONAL_CONFIGS[@]}"; do
        local dest_dir
        IFS=':' read -r _ _ dest_dir <<< "$config"
        if [[ -e "$CONFIG_HOME/$dest_dir" ]]; then
            configs_to_backup+=("$CONFIG_HOME/$dest_dir")
        fi
    done

    local needs_backup=false
    for config in "${configs_to_backup[@]}"; do
        if [[ -e "$config" ]]; then
            needs_backup=true
            break
        fi
    done

    if [[ "$needs_backup" == "true" ]]; then
        if [[ "$DRY_RUN" == "false" ]]; then
            if ! prompt_yes_no "Existing configurations found. Create backup?" "y"; then
                if ! prompt_yes_no "Continue without backup? (existing configs will be overwritten)" "n"; then
                    log_info "Installation cancelled by user"
                    exit 0
                fi
                return
            fi
        fi

        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "${YELLOW}[DRY-RUN]${NC} Would create backup at: $BACKUP_DIR"
            echo -e "${YELLOW}[DRY-RUN]${NC} Would backup:"
            for config in "${configs_to_backup[@]}"; do
                if [[ -e "$config" ]]; then
                    echo "  - $config"
                fi
            done
        else
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
    fi
}

create_config_directories() {
    log_info "Creating config directories..."

    # Create main config directory
    run_cmd mkdir -p "$CONFIG_HOME"

    # Create standard config directories
    for dir in "${CONFIG_DIRS[@]}"; do
        local dest_dir="${dir##*:}"  # Get destination (after :) or whole string
        run_cmd mkdir -p "$CONFIG_HOME/$dest_dir"
    done

    # Create conditional config directories if selected
    for config in "${CONDITIONAL_CONFIGS[@]}"; do
        local package_name source_dir dest_dir
        IFS=':' read -r package_name source_dir dest_dir <<< "$config"

        if is_package_selected "$package_name"; then
            run_cmd mkdir -p "$CONFIG_HOME/$dest_dir"
        fi
    done

    log_success "Config directories created"
}

copy_configuration_files() {
    log_info "Copying configuration files..."

    # Copy standard config directories
    for dir in "${CONFIG_DIRS[@]}"; do
        local source_dir="${dir%%:*}"  # Get source (before :) or whole string
        local dest_dir="${dir##*:}"    # Get destination (after :) or whole string

        if [[ -d "$SCRIPT_DIR/$source_dir" ]]; then
            run_cmd cp -r "$SCRIPT_DIR/$source_dir"/* "$CONFIG_HOME/$dest_dir/"
            log_info "Copied $source_dir config"
        fi
    done

    # Make waybar scripts executable (use find to handle empty globs safely)
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would make waybar scripts executable"
    else
        find "$CONFIG_HOME/waybar/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true
    fi

    # Copy home directory files
    for file_mapping in "${HOME_FILES[@]}"; do
        local source_file="${file_mapping%%:*}"
        local dest_file="${file_mapping##*:}"

        if [[ -f "$SCRIPT_DIR/$source_file" ]]; then
            run_cmd cp "$SCRIPT_DIR/$source_file" "$HOME/$dest_file"
            log_info "Copied $dest_file to home directory"
        fi
    done

    # Copy conditional configs if selected
    for config in "${CONDITIONAL_CONFIGS[@]}"; do
        local package_name source_dir dest_dir
        IFS=':' read -r package_name source_dir dest_dir <<< "$config"

        if is_package_selected "$package_name" && [[ -d "$SCRIPT_DIR/$source_dir" ]]; then
            run_cmd cp -r "$SCRIPT_DIR/$source_dir"/* "$CONFIG_HOME/$dest_dir/"
            log_info "Copied $source_dir config"
        fi
    done

    log_success "Configuration files copied"
}

install_greetd_config() {
    log_info "Installing greetd display manager config (requires sudo)..."

    local greetd_config="$SCRIPT_DIR/greetd/config.toml"
    local greetd_path="$SCRIPT_DIR/greetd"

    if [[ ! -f "$greetd_config" ]]; then
        log_error "greetd config not found: $greetd_config"
        exit 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would run: sudo cp $greetd_path/* /etc/greetd/"
        return
    fi

    if ! sudo -v; then
        log_error "sudo access required for greetd installation"
        exit 1
    fi

    # greetd creates /etc/greetd on package install, but ensure it exists
    sudo mkdir -p /etc/greetd
    sudo cp $SCRIPT_DIR/greetd/* /etc/greetd/

    log_success "greetd config installed"
}

install_backgrounds() {
    log_info "Installing background images (requires sudo)..."

    local backgrounds_path="$SCRIPT_DIR/backgrounds"

    if [[ ! -d "$backgrounds_path" ]]; then
        log_warning "Backgrounds directory not found, skipping"
        return
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would run: sudo cp $backgrounds_path/* /usr/share/backgrounds/"
        return
    fi

    if ! sudo -v; then
        log_error "sudo access required for backgrounds installation"
        exit 1
    fi

    sudo mkdir -p /usr/share/backgrounds
    sudo cp "$backgrounds_path"/* /usr/share/backgrounds/

    log_success "Background images installed"
}

setup_vim() {
    # Check if vim was selected
    if ! is_package_selected "vim"; then
        log_info "Skipping Vim setup (not selected)"
        return
    fi

    log_info "Setting up Vim with plugins..."

    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
            echo -e "${YELLOW}[DRY-RUN]${NC} Would run: curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
        fi
        echo -e "${YELLOW}[DRY-RUN]${NC} Would run: cp $SCRIPT_DIR/vim/vimrc $HOME/.vimrc"
        echo -e "${YELLOW}[DRY-RUN]${NC} Would run: vim +PlugInstall +qall"
        return
    fi

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

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would run: sudo cp $SCRIPT_DIR/ps1/custom_ps1.sh /etc/profile.d/custom_ps1.sh"
        echo -e "${YELLOW}[DRY-RUN]${NC} Would run: sudo chmod +x /etc/profile.d/custom_ps1.sh"
        if ! grep -q "custom_ps1.sh" "$HOME/.bashrc" 2>/dev/null; then
            echo -e "${YELLOW}[DRY-RUN]${NC} Would add custom PS1 sourcing to .bashrc"
        fi
        return
    fi

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

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would disable any existing display manager"
        echo -e "${YELLOW}[DRY-RUN]${NC} Would run: sudo systemctl enable greetd.service"
        return
    fi

    # Disable any existing display manager first
    if [[ -L /etc/systemd/system/display-manager.service ]]; then
        local current_dm
        current_dm=$(readlink /etc/systemd/system/display-manager.service | xargs basename)
        log_info "Disabling existing display manager: $current_dm"
        sudo systemctl disable "$current_dm" 2>/dev/null || true
    fi

    # Enable greetd (it manages its own VT via config.toml)
    sudo systemctl enable greetd.service

    log_success "greetd display manager enabled"
}

configure_displays() {
    local detect_script="$SCRIPT_DIR/scripts/detect-displays.sh"

    if [[ ! -x "$detect_script" ]]; then
        log_warning "Display detection script not found, skipping"
        return
    fi

    echo ""
    log_info "Display Configuration"
    echo "================================================================"
    echo "The display detection script can configure your monitors"
    echo "(resolution, refresh rate, positioning) for Hyprland."
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would prompt to run: $detect_script"
        return
    fi

    if prompt_yes_no "Would you like to configure your displays now?" "y"; then
        echo ""
        "$detect_script"
    else
        log_info "Skipping display configuration"
        echo "You can run it later with: $detect_script"
    fi
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
    echo "2. Select 'Hyprland (uwsm)' from ReGreet login screen"
    echo "3. Press Super+Return to open terminal"
    echo "4. Enjoy your setup!"
    echo ""
    echo "What's installed:"
    echo "  ✓ Hyprland with Waybar, Mako, Hyprlock"
    echo "  ✓ Alacritty terminal with Tokyo Night theme"

    # Check if vim is installed
    if is_package_selected "vim"; then
        echo "  ✓ Vim with NERDTree, coc.nvim, and colorschemes"
    fi

    echo "  ✓ Custom colorful bash prompt with git branch"
    echo "  ✓ PipeWire audio with GTK device selector popups"
    echo "  ✓ Weather widget with interactive forecast popup"

    # List other installed optional packages
    for key in "${APP_ORDER[@]}"; do
        if [[ "${INSTALL_OPTIONAL[$key]:-}" == "yes" ]]; then
            local name="${APP_NAMES[$key]}"
            local description="${APP_DESCRIPTIONS[$key]}"

            # Skip vim (already shown above)
            if [[ "$name" != "vim" ]]; then
                if [[ -n "$description" ]]; then
                    echo "  ✓ $description"
                else
                    echo "  ✓ $name"
                fi
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
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -b|--backup-dir)
                if [[ -z "${2:-}" ]]; then
                    log_error "Error: --backup-dir requires a directory path"
                    exit 1
                fi
                BACKUP_DIR="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Show dry-run banner if enabled
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}DRY-RUN MODE - No changes will be made${NC}"
        echo -e "${YELLOW}========================================${NC}"
        echo ""
    fi

    # Set up error handling
    trap cleanup EXIT

    echo "=== Hyprland Dotfiles Installer ==="
    echo ""

    # Run checks
    check_requirements
    verify_source_structure

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
    install_greetd_config
    install_backgrounds
    setup_vim
    setup_custom_ps1
    enable_services

    # Configure displays (after all configs are copied)
    configure_displays

    # Show summary
    show_summary
}

# Run main function
main "$@"
