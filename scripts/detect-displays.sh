#!/bin/bash
#
# Display Detection and Configuration Script
# Detects connected displays and generates Hyprland monitor configuration
#
# Usage: ./detect-displays.sh
#
# Optional: Install 'edid-decode' for automatic refresh rate detection
#

set -euo pipefail

# Configuration paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MONITORS_CONF="$REPO_ROOT/hypr/monitors.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if edid-decode is available
HAS_EDID_DECODE=false
if command -v edid-decode &>/dev/null; then
    HAS_EDID_DECODE=true
fi

# Arrays to store display information
declare -a DISPLAYS=()
declare -a DISPLAY_PATHS=()
declare -a SUGGESTED_RES=()
declare -A DISPLAY_RES=()
declare -A DISPLAY_SCALE=()

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Display Detection and Configuration               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get available modes from EDID using edid-decode
get_edid_modes() {
    local edid_path="$1"
    if [[ "$HAS_EDID_DECODE" == "true" ]] && [[ -f "$edid_path" ]] && [[ -s "$edid_path" ]]; then
        edid-decode "$edid_path" 2>/dev/null | \
            grep -oE "[0-9]+x[0-9]+\s+[0-9]+\.[0-9]+ Hz" | \
            awk '{printf "%s@%.0f\n", $1, $2}' | \
            sort -t'x' -k1 -rn | \
            uniq
    fi
}

# Detect connected displays from /sys/class/drm/
detect_displays() {
    print_info "Scanning for connected displays..."
    echo

    if [[ "$HAS_EDID_DECODE" == "true" ]]; then
        print_success "edid-decode found - refresh rates will be auto-detected"
    else
        print_warning "edid-decode not found - install it for auto refresh rate detection"
    fi
    echo

    local index=0
    for card_dir in /sys/class/drm/card*-*; do
        [[ -d "$card_dir" ]] || continue

        # Skip writeback connectors
        [[ "$card_dir" == *"Writeback"* ]] && continue

        # Check if display is connected
        if [[ -f "$card_dir/status" ]] && grep -q "^connected$" "$card_dir/status" 2>/dev/null; then
            # Extract display name (e.g., DP-1, HDMI-A-1)
            local display_name
            display_name=$(basename "$card_dir" | sed 's/card[0-9]*-//')

            # Get suggested resolution (first line from modes file)
            local suggested_res="1920x1080"
            if [[ -f "$card_dir/modes" ]] && [[ -s "$card_dir/modes" ]]; then
                suggested_res=$(head -1 "$card_dir/modes")
            fi

            DISPLAYS+=("$display_name")
            DISPLAY_PATHS+=("$card_dir")
            SUGGESTED_RES+=("$suggested_res")

            echo -e "  ${GREEN}[$index]${NC} $display_name - Max resolution: ${YELLOW}$suggested_res${NC}"
            index=$((index + 1))
        fi
    done

    echo

    if [[ ${#DISPLAYS[@]} -eq 0 ]]; then
        print_error "No connected displays found!"
        echo "Make sure your displays are connected and detected by the system."
        exit 1
    fi

    print_success "Found ${#DISPLAYS[@]} connected display(s)"
    echo
}

# Prompt user to select primary monitor
select_primary() {
    if [[ ${#DISPLAYS[@]} -eq 1 ]]; then
        PRIMARY_INDEX=0
        print_info "Only one display detected, setting ${DISPLAYS[0]} as primary"
        echo
        return
    fi

    echo -e "${CYAN}Select PRIMARY monitor (number):${NC}"
    while true; do
        read -rp "> " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -lt ${#DISPLAYS[@]} ]]; then
            PRIMARY_INDEX=$selection
            break
        fi
        print_warning "Invalid selection. Enter a number between 0 and $((${#DISPLAYS[@]} - 1))"
    done

    print_success "Primary monitor: ${DISPLAYS[$PRIMARY_INDEX]}"
    echo
}

# Configure resolution and scale for a single display
configure_display_settings() {
    local index=$1
    local display="${DISPLAYS[$index]}"
    local card_path="${DISPLAY_PATHS[$index]}"
    local suggested="${SUGGESTED_RES[$index]}"

    echo -e "${CYAN}━━━ $display ━━━${NC}"
    if [[ "$index" -eq "$PRIMARY_INDEX" ]]; then
        echo -e "  ${GREEN}(PRIMARY)${NC}"
    fi

    # Try to get modes from EDID
    local edid_path="$card_path/edid"
    local modes=()
    if [[ "$HAS_EDID_DECODE" == "true" ]]; then
        mapfile -t modes < <(get_edid_modes "$edid_path")
    fi

    local resolution=""

    if [[ ${#modes[@]} -gt 0 ]]; then
        # Show available modes
        echo -e "  ${BLUE}Available modes:${NC}"
        local mode_index=0
        for mode in "${modes[@]}"; do
            echo -e "    [$mode_index] $mode"
            mode_index=$((mode_index + 1))
        done
        echo -e "    [m] Enter manually"
        echo
        echo -e "  Select mode (number or 'm' for manual):"

        while true; do
            read -rp "  > " mode_selection

            if [[ "$mode_selection" == "m" ]]; then
                # Manual entry
                echo -e "  Resolution@RefreshRate [${YELLOW}${suggested}@60${NC}]:"
                read -rp "  > " res_input
                resolution="${res_input:-${suggested}@60}"
                break
            elif [[ "$mode_selection" =~ ^[0-9]+$ ]] && [[ "$mode_selection" -lt ${#modes[@]} ]]; then
                resolution="${modes[$mode_selection]}"
                break
            fi
            print_warning "Invalid selection"
        done
    else
        # Manual entry (no edid-decode)
        echo -e "  Resolution@RefreshRate [${YELLOW}${suggested}@60${NC}]:"
        echo -e "  ${BLUE}(e.g., 1920x1080@144, 3840x2160@60)${NC}"
        read -rp "  > " res_input
        resolution="${res_input:-${suggested}@60}"
    fi

    # Add @60 if no refresh rate specified
    if [[ ! "$resolution" =~ @ ]]; then
        resolution="${resolution}@60"
    fi
    DISPLAY_RES["$display"]="$resolution"

    # Scale
    echo -e "  Scale [${YELLOW}1${NC}]:"
    read -rp "  > " scale_input
    DISPLAY_SCALE["$display"]="${scale_input:-1}"

    echo
}

# Ask for left-to-right order of monitors
configure_order() {
    if [[ ${#DISPLAYS[@]} -eq 1 ]]; then
        ORDERED_DISPLAYS=("${DISPLAYS[0]}")
        return
    fi

    echo -e "${CYAN}━━━ Monitor Positioning ━━━${NC}"
    echo
    echo "Enter the order of monitors from LEFT to RIGHT."
    echo "Available monitors:"
    for i in "${!DISPLAYS[@]}"; do
        local mark=""
        [[ "$i" -eq "$PRIMARY_INDEX" ]] && mark=" ${GREEN}(PRIMARY)${NC}"
        echo -e "  [$i] ${DISPLAYS[$i]}$mark"
    done
    echo
    echo -e "Enter numbers separated by spaces (e.g., ${YELLOW}1 0${NC} for monitor 1 on left, monitor 0 on right):"

    while true; do
        read -rp "> " order_input

        # Parse the input
        IFS=' ' read -ra ORDER_INDICES <<< "$order_input"

        # Validate
        if [[ ${#ORDER_INDICES[@]} -ne ${#DISPLAYS[@]} ]]; then
            print_warning "Please specify all ${#DISPLAYS[@]} monitors"
            continue
        fi

        # Check all indices are valid and unique
        local valid=true
        declare -A seen=()
        for idx in "${ORDER_INDICES[@]}"; do
            if [[ ! "$idx" =~ ^[0-9]+$ ]] || [[ "$idx" -ge ${#DISPLAYS[@]} ]]; then
                print_warning "Invalid monitor index: $idx"
                valid=false
                break
            fi
            if [[ -n "${seen[$idx]:-}" ]]; then
                print_warning "Duplicate index: $idx"
                valid=false
                break
            fi
            seen["$idx"]=1
        done

        if [[ "$valid" == "true" ]]; then
            break
        fi
    done

    # Build ordered array
    ORDERED_DISPLAYS=()
    for idx in "${ORDER_INDICES[@]}"; do
        ORDERED_DISPLAYS+=("${DISPLAYS[$idx]}")
    done

    echo
    print_success "Order (left to right): ${ORDERED_DISPLAYS[*]}"
    echo
}

# Calculate positions and generate config
generate_config() {
    local primary="${DISPLAYS[$PRIMARY_INDEX]}"

    print_info "Generating configuration..."
    echo

    # Calculate positions based on order
    declare -A DISPLAY_POS=()
    local current_x=0

    for display in "${ORDERED_DISPLAYS[@]}"; do
        DISPLAY_POS["$display"]="${current_x}x0"

        # Calculate width for next position
        local res="${DISPLAY_RES[$display]}"
        local scale="${DISPLAY_SCALE[$display]}"
        local width
        width=$(echo "$res" | sed 's/x.*//')

        # Account for scale (width / scale)
        local scaled_width
        scaled_width=$(echo "$width / $scale" | bc 2>/dev/null || echo "$width")

        current_x=$((current_x + scaled_width))
    done

    # Build the config content
    local config_content=""
    config_content+="################\n"
    config_content+="### MONITORS ###\n"
    config_content+="################\n"
    config_content+="\n"
    config_content+="# Environment variable for waybar (auto-generated by detect-displays.sh)\n"
    config_content+="env = MONITOR_PRIMARY, $primary\n"
    config_content+="\n"

    # Add monitorv2 blocks in the order they appear (left to right)
    for display in "${ORDERED_DISPLAYS[@]}"; do
        local res="${DISPLAY_RES[$display]}"
        local scale="${DISPLAY_SCALE[$display]}"
        local pos="${DISPLAY_POS[$display]}"

        config_content+="monitorv2 {\n"
        config_content+="  output = $display\n"
        config_content+="  mode = $res\n"
        config_content+="  position = $pos\n"
        config_content+="  scale = $scale\n"
        config_content+="}\n"
        config_content+="\n"
    done

    # Show preview
    echo -e "${CYAN}━━━ Generated Configuration Preview ━━━${NC}"
    echo
    echo -e "$config_content"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    # Confirm before writing
    echo -e "Write configuration to ${YELLOW}$MONITORS_CONF${NC}?"
    read -rp "[y/N] > " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "$config_content" > "$MONITORS_CONF"
        print_success "Configuration written to $MONITORS_CONF"
    else
        print_warning "Configuration not saved"
    fi
}

# Main function
main() {
    print_header

    # Step 1: Detect displays
    detect_displays

    # Step 2: Select primary
    select_primary

    # Step 3: Configure resolution and scale for each display
    echo -e "${CYAN}━━━ Display Settings ━━━${NC}"
    echo
    for i in "${!DISPLAYS[@]}"; do
        configure_display_settings "$i"
    done

    # Step 4: Configure left-to-right order
    configure_order

    # Step 5: Generate config
    generate_config

    echo
    print_success "Display configuration complete!"
    echo
    echo "Note: Restart Hyprland or run 'hyprctl reload' to apply changes."
}

main "$@"
