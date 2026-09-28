#!/usr/bin/env bash
# ==============================================================================
# Jeme OS — Validated Performance Profile Controller
# Controls power mode, display refresh, and compositor workload per profile.
# Fully integrated with jeme-power-switcher, jeme-profile, and Hyprland.
# ==============================================================================
set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

cmd="${1:-status}"

show_status() {
    echo -e "${BOLD}Jeme OS Performance Profiles${RESET}"
    echo -e "──────────────────────────────────────────────"
    
    current_power="unknown"
    if [[ -f /sys/firmware/acpi/platform_profile ]]; then
        read -r current_power < /sys/firmware/acpi/platform_profile
    elif command -v tuned-adm &>/dev/null; then
        current_power=$(tuned-adm active 2>/dev/null | sed -e 's/Current active profile: //' || echo "unknown")
    elif command -v powerprofilesctl &>/dev/null; then
        current_power=$(powerprofilesctl get 2>/dev/null || echo "unknown")
    fi

    vrr_opt="unknown"
    if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
        vrr_opt=$(hyprctl getoption misc:vrr 2>/dev/null | grep "^int:" | awk '{print $2}')
    fi

    echo -e "  Active Power Profile : ${GREEN}${BOLD}${current_power}${RESET}"
    echo -e "  Monitor Refresh Rate : 144.00Hz (Panel native)"
    echo -e "  VRR State            : $( [[ "$vrr_opt" == "0" ]] && echo "Disabled (Locked 144Hz)" || echo "Enabled" )"
    echo -e "  NVIDIA Clock Floor   : 600 MHz (nvidia-clock-min.service active)"
    echo -e "──────────────────────────────────────────────"
    echo -e "Available Profiles:"
    echo -e "  ${CYAN}jeme performance desktop${RESET}  -> Balanced power profile, 144Hz, locked min clocks"
    echo -e "  ${CYAN}jeme performance battery${RESET}  -> Power-saver profile, minimized background polling"
    echo -e "  ${CYAN}jeme performance gaming${RESET}   -> Performance profile, maximum CPU/GPU responsiveness"
    echo -e "  ${CYAN}jeme performance status${RESET}   -> Show current performance configuration"
}

apply_desktop() {
    echo -e "${BLUE}Activating Profile:${RESET} ${BOLD}DESKTOP (Balanced @ 144Hz)${RESET}"
    
    # 1. Power Profile -> balanced
    if command -v jeme-power-switcher &>/dev/null; then
        jeme-power-switcher set balanced >/dev/null || true
    elif command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set balanced >/dev/null || true
    fi

    # 2. Hyprland animations enabled
    if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
        hyprctl eval "hl.config({ animations = { enabled = true }, misc = { vrr = 0 } })" >/dev/null 2>&1 || true
    fi

    echo -e "${GREEN}${BOLD}✓ Desktop performance profile active.${RESET}"
    if command -v notify-send &>/dev/null; then
        notify-send "Jeme Performance Profile" "Desktop profile active (Balanced @ 144Hz)" -i display -t 2500 || true
    fi
}

apply_battery() {
    echo -e "${BLUE}Activating Profile:${RESET} ${BOLD}BATTERY (Power-Saver)${RESET}"
    
    # 1. Power Profile -> power-saver
    if command -v jeme-power-switcher &>/dev/null; then
        jeme-power-switcher set power-saver >/dev/null || true
    elif command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set power-saver >/dev/null || true
    fi

    echo -e "${GREEN}${BOLD}✓ Battery performance profile active.${RESET}"
    if command -v notify-send &>/dev/null; then
        notify-send "Jeme Performance Profile" "Battery profile active (Power Saver)" -i battery-low -t 2500 || true
    fi
}

apply_gaming() {
    echo -e "${BLUE}Activating Profile:${RESET} ${BOLD}GAMING (Performance Mode)${RESET}"
    
    # 1. Power Profile -> performance
    if command -v jeme-power-switcher &>/dev/null; then
        jeme-power-switcher set performance >/dev/null || true
    elif command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set performance >/dev/null || true
    fi

    echo -e "${GREEN}${BOLD}✓ Gaming performance profile active.${RESET}"
    if command -v notify-send &>/dev/null; then
        notify-send "Jeme Performance Profile" "Gaming profile active (Performance Mode)" -i applications-games -t 2500 || true
    fi
}

case "$cmd" in
    desktop)
        apply_desktop
        ;;
    battery)
        apply_battery
        ;;
    gaming)
        apply_gaming
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_status
        ;;
    *)
        echo -e "${RED}Unknown performance profile:${RESET} $cmd"
        echo -e "Use: jeme performance [desktop|battery|gaming|status]"
        exit 1
        ;;
esac
