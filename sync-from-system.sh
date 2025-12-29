#!/bin/bash
# Sync current system configs back to the dotfiles repo
# This is the reverse of install.sh - copies FROM system TO repo

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

readonly CONFIG_HOME="${HOME}/.config"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

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

# ============================================================================
# Sync Functions
# ============================================================================

sync_config_dir() {
    local name="$1"
    local source="$CONFIG_HOME/$name"
    local dest="$SCRIPT_DIR/$name"

    if [[ ! -d "$source" ]]; then
        log_warning "Config not found: $source (skipping)"
        return
    fi

    log_info "Syncing $name..."
    mkdir -p "$dest"
    rsync -av --delete "$source/" "$dest/"
}

sync_file() {
    local name="$1"
    local source="$2"
    local dest="$3"

    if [[ ! -f "$source" ]]; then
        log_warning "File not found: $source (skipping)"
        return
    fi

    log_info "Syncing $name..."
    mkdir -p "$(dirname "$dest")"
    cp "$source" "$dest"
}

sync_sddm_configs() {
    log_info "Syncing SDDM configs (requires sudo)..."

    if ! sudo -v; then
        log_error "sudo access required for SDDM configs"
        return 1
    fi

    mkdir -p "$SCRIPT_DIR/sddm"

    # Copy conf files
    if [[ -d "/etc/sddm.conf.d" ]]; then
        sudo cp /etc/sddm.conf.d/*.conf "$SCRIPT_DIR/sddm/" 2>/dev/null || true
        sudo chown "$USER:$USER" "$SCRIPT_DIR/sddm/"*.conf 2>/dev/null || true
    fi

    # Copy Xsetup script
    if [[ -f "/usr/share/sddm/scripts/Xsetup" ]]; then
        sudo cp /usr/share/sddm/scripts/Xsetup "$SCRIPT_DIR/sddm/"
        sudo chown "$USER:$USER" "$SCRIPT_DIR/sddm/Xsetup"
    fi
}

show_changes() {
    log_info "Checking for changes..."
    echo ""

    cd "$SCRIPT_DIR" || exit 1

    if ! git diff --quiet || ! git diff --cached --quiet || [[ -n $(git ls-files --others --exclude-standard) ]]; then
        echo "Changes detected:"
        echo ""
        git status --short
        echo ""

        if prompt_yes_no "Show detailed diff?" "n"; then
            echo ""
            git diff
        fi

        return 0
    else
        log_success "No changes detected - configs are already in sync!"
        return 1
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo "=== Dotfiles Config Sync (System → Repo) ==="
    echo ""

    # Check if we're in a git repo
    if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
        log_error "Not a git repository: $SCRIPT_DIR"
        exit 1
    fi

    log_info "Syncing configs from system to repo..."
    echo ""

    # Sync all config directories
    sync_config_dir "hypr"
    sync_config_dir "waybar"
    sync_config_dir "mako"
    sync_config_dir "alacritty"
    sync_config_dir "rofi"
    sync_config_dir "xdg-desktop-portal"

    # Sync individual files
    sync_file "vimrc" "$HOME/.vimrc" "$SCRIPT_DIR/vim/vimrc"
    sync_file "custom PS1" "/etc/profile.d/custom_ps1.sh" "$SCRIPT_DIR/ps1/custom_ps1.sh"

    # Sync SDDM configs
    if prompt_yes_no "Sync SDDM configs? (requires sudo)" "y"; then
        sync_sddm_configs
    fi

    echo ""
    log_success "Config sync complete!"
    echo ""

    # Show what changed
    if show_changes; then
        echo ""
        if prompt_yes_no "Commit these changes?" "y"; then
            echo ""
            read -r -p "Commit message: " commit_msg

            if [[ -n "$commit_msg" ]]; then
                git add -A
                git commit -m "$commit_msg"
                log_success "Changes committed!"

                if prompt_yes_no "Push to remote?" "y"; then
                    git push
                    log_success "Changes pushed!"
                fi
            else
                log_warning "Empty commit message - skipping commit"
            fi
        fi
    fi
}

main "$@"
