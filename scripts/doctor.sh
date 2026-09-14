#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — System Doctor & Health Diagnostics
# ==============================================================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

header "Jeme OS System Diagnostics & Health Check"

ERRORS=0
WARNINGS=0

check_binary() {
    local name="$1"
    local desc="$2"
    if has_cmd "$name"; then
        echo -e "  ${CLR_GREEN}[✓]${CLR_RESET} ${desc}: \033[1m${name}\033[0m ($(which "$name"))"
    else
        echo -e "  ${CLR_RED}[✗]${CLR_RESET} ${desc} missing: \033[1m${name}\033[0m"
        ((ERRORS++))
    fi
}

check_file() {
    local path="$1"
    local desc="$2"
    if [[ -f "$path" ]]; then
        echo -e "  ${CLR_GREEN}[✓]${CLR_RESET} ${desc}: ${path}"
    else
        echo -e "  ${CLR_YELLOW}[!]${CLR_RESET} ${desc} missing: ${path}"
        ((WARNINGS++))
    fi
}

check_service() {
    local unit="$1"
    if systemctl --user is-active "$unit" >/dev/null 2>&1; then
        echo -e "  ${CLR_GREEN}[✓]${CLR_RESET} User Service: \033[1m${unit}\033[0m (active)"
    else
        echo -e "  ${CLR_YELLOW}[!]${CLR_RESET} User Service: \033[1m${unit}\033[0m (inactive/disabled)"
        ((WARNINGS++))
    fi
}

echo -e "${CLR_BOLD}1. Core Binaries & Compositor:${CLR_RESET}"
check_binary "Hyprland" "Hyprland Compositor"
check_binary "hyprctl" "Hyprland Controller"
check_binary "qs" "Quickshell Wrapper"
check_binary "quickshell" "Quickshell Binary"
check_binary "matugen" "Material 3 Palette Generator"
check_binary "awww" "Wallpaper Daemon"
check_binary "swaync" "Notification Center"
check_binary "rofi" "Application Launcher"
check_binary "kitty" "Terminal Emulator"
check_binary "waybar" "Status Bar"
check_binary "cliphist" "Clipboard Manager"
check_binary "hypridle" "Idle Daemon"
check_binary "hyprlock" "Screen Locker"

echo
echo -e "${CLR_BOLD}2. Portals & Audio Stack:${CLR_RESET}"
check_binary "pipewire" "PipeWire Core"
check_binary "wireplumber" "WirePlumber Session Manager"
check_file "/usr/share/xdg-desktop-portal/hyprland-portals.conf" "Hyprland Portal Configuration"
check_file "/usr/libexec/xdg-desktop-portal-hyprland" "Hyprland Portal Backend"
check_file "/usr/libexec/xdg-desktop-portal-gtk" "GTK Portal Backend"

echo
echo -e "${CLR_BOLD}3. Key Configuration Files:${CLR_RESET}"
check_file "${HOME}/.config/hypr/hyprland.lua" "Hyprland Master Config"
check_file "${HOME}/.config/hypr/monitors.lua" "Monitor Configuration"
check_file "${HOME}/.config/quickshell/shell.qml" "Quickshell Master Root"
check_file "${HOME}/.config/matugen/config.toml" "Matugen Config"
check_file "${HOME}/.config/ml4w/colors/colors.json" "Active Theme Palette (colors.json)"
check_file "${HOME}/.config/waybar/colors.css" "Waybar Color Variables"
check_file "${HOME}/.config/swaync/config.json" "SwayNC Config"

echo
echo -e "${CLR_BOLD}4. User Systemd Services (if running in session):${CLR_RESET}"
check_service "pipewire.service"
check_service "wireplumber.service"
check_service "swaync.service"
check_service "hyprpolkitagent.service"

echo
echo -e "${CLR_BOLD}5. Typography & Fonts:${CLR_RESET}"
if fc-list : family | grep -iq 'FiraCode Nerd Font'; then
    echo -e "  ${CLR_GREEN}[✓]${CLR_RESET} FiraCode Nerd Font: Installed"
else
    echo -e "  ${CLR_YELLOW}[!]${CLR_RESET} FiraCode Nerd Font: Missing"
    ((WARNINGS++))
fi

echo
header "Diagnostics Summary"
echo -e "  Errors:   ${ERRORS}"
echo -e "  Warnings: ${WARNINGS}"

if [[ $ERRORS -eq 0 ]]; then
    success "Jeme OS is healthy and operational!"
else
    error "Some required components are missing. Run ./install.sh or jeme install."
fi
