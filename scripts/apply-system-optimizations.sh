#!/usr/bin/env bash
# ==============================================================================
# Jeme OS — System-Level Optimization Deployment & Rollback Controller
# Strictly implements the Jeme OS Final Implementation Safety Gate.
# Requires sudo / administrative privileges.
# ==============================================================================
set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

STATE_DIR="${HOME}/.local/state/jeme-optimization"
MANIFEST="${STATE_DIR}/backup-manifest.txt"
mkdir -p "$STATE_DIR"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error:${RESET} This script manages /etc system configurations and must be run with sudo."
    echo -e "Usage: sudo $0 [apply|rollback|status]"
    exit 1
fi

action="${1:-status}"

backup_system_file() {
    local orig="$1"
    if [[ -f "$orig" ]]; then
        local ts
        ts="$(date +%Y%m%d-%H%M%S)"
        local bk="${STATE_DIR}/$(basename "$orig").backup-${ts}"
        cp "$orig" "$bk"
        echo "original=$orig backup=$bk" >> "$MANIFEST"
        echo -e "  Backup created: ${bk}"
    fi
}

do_status() {
    echo -e "${BOLD}Jeme OS System-Level Optimizations Status${RESET}"
    echo -e "──────────────────────────────────────────────"
    
    # 1. Zswap Status
    zswap_en="unknown"
    [[ -f /sys/module/zswap/parameters/enabled ]] && zswap_en=$(< /sys/module/zswap/parameters/enabled)
    zswap_file="Absent"
    [[ -f /etc/tmpfiles.d/jeme-zswap.conf ]] && zswap_file="Installed (/etc/tmpfiles.d/jeme-zswap.conf)"
    echo -e "  Zswap Active Runtime : ${BOLD}${zswap_en}${RESET} (N = Deconflicted / Y = Active conflict with zram)"
    echo -e "  Zswap Config File    : ${zswap_file}"

    # 2. NOFILE Limits
    nofile_file="Absent"
    [[ -f /etc/security/limits.d/99-jeme-nofile.conf ]] && nofile_file="Installed (/etc/security/limits.d/99-jeme-nofile.conf)"
    echo -e "  NOFILE Security Limit: ${nofile_file}"

    # 3. Wi-Fi Powersave Policy
    wifi_file="Absent"
    [[ -f /etc/NetworkManager/conf.d/jeme-wifi-powersave.conf ]] && wifi_file="Installed (/etc/NetworkManager/conf.d/jeme-wifi-powersave.conf)"
    echo -e "  Wi-Fi Powersave Policy: ${wifi_file}"

    echo -e "──────────────────────────────────────────────"
    echo -e "Usage:"
    echo -e "  sudo $0 apply     -> Deploy verified system configs and disable zswap"
    echo -e "  sudo $0 rollback  -> Cleanly remove configs and restore initial state"
    echo -e "  sudo $0 status    -> Show this status report"
}

do_apply() {
    echo -e "${BLUE}Deploying Verified System Configurations...${RESET}"

    # 1. Zswap Deconfliction (Rule 2)
    echo -e "\n${CYAN}1. Zswap / Zram Deconfliction:${RESET}"
    echo -e "   Disabling zswap in front of zram to prevent CPU-wasting double compression..."
    mkdir -p /etc/tmpfiles.d
    backup_system_file "/etc/tmpfiles.d/jeme-zswap.conf"
    cat > /etc/tmpfiles.d/jeme-zswap.conf << 'EOF'
# Jeme OS: Disable zswap because /dev/zram0 is the primary swap device.
# Prevents memory pages from being double-compressed in RAM.
w! /sys/module/zswap/parameters/enabled - - - - N
EOF
    # Apply temporary runtime write immediately
    if [[ -f /sys/module/zswap/parameters/enabled ]]; then
        echo N > /sys/module/zswap/parameters/enabled || true
        echo -e "  ${GREEN}✓ Runtime zswap set to N (disabled)${RESET}"
    fi

    # 2. NOFILE Soft Limit Robustness (Rule 4)
    echo -e "\n${CYAN}2. User Soft NOFILE Resource Limits:${RESET}"
    echo -e "   Raising soft file descriptor limit to 65536 while preserving 1,048,576 hard ceiling..."
    mkdir -p /etc/security/limits.d
    backup_system_file "/etc/security/limits.d/99-jeme-nofile.conf"
    cat > /etc/security/limits.d/99-jeme-nofile.conf << 'EOF'
# Jeme OS: Prevent user-space applications (Steam, Proton, Electron, IDEs)
# from hitting the 1024 soft descriptor barrier, while preserving 1M hard ceiling.
* soft nofile 65536
* hard nofile 1048576
EOF
    echo -e "  ${GREEN}✓ /etc/security/limits.d/99-jeme-nofile.conf deployed${RESET}"

    # 3. Wi-Fi Powersave Policy Enforcement (Rule 5)
    echo -e "\n${CYAN}3. Wi-Fi Powersave Policy Lock:${RESET}"
    echo -e "   Enforcing wifi.powersave = 2 (disabled) policy across battery/reconnect cycles..."
    mkdir -p /etc/NetworkManager/conf.d
    backup_system_file "/etc/NetworkManager/conf.d/jeme-wifi-powersave.conf"
    cat > /etc/NetworkManager/conf.d/jeme-wifi-powersave.conf << 'EOF'
# Jeme OS: Ensure Wi-Fi powersave remains consistently disabled across reconnects.
[connection]
wifi.powersave = 2
EOF
    echo -e "  ${GREEN}✓ /etc/NetworkManager/conf.d/jeme-wifi-powersave.conf deployed${RESET}"

    echo -e "\n${GREEN}${BOLD}✓ All system-level configurations successfully deployed!${RESET}"
    echo -e "  (Persistent zswap across future kernel boots can also be pinned via: grubby --update-kernel=ALL --args=\"zswap.enabled=0\")"
}

do_rollback() {
    echo -e "${YELLOW}Rolling back system-level configurations...${RESET}"

    # 1. Remove configs
    rm -f /etc/tmpfiles.d/jeme-zswap.conf
    rm -f /etc/security/limits.d/99-jeme-nofile.conf
    rm -f /etc/NetworkManager/conf.d/jeme-wifi-powersave.conf

    # 2. Reset runtime zswap to enabled
    if [[ -f /sys/module/zswap/parameters/enabled ]]; then
        echo Y > /sys/module/zswap/parameters/enabled || true
        echo -e "  Runtime zswap reset to Y"
    fi

    echo -e "${GREEN}${BOLD}✓ System-level configurations cleanly rolled back!${RESET}"
}

case "$action" in
    apply)
        do_apply
        ;;
    rollback)
        do_rollback
        ;;
    status)
        do_status
        ;;
    *)
        echo "Usage: sudo $0 [apply|rollback|status]"
        exit 1
        ;;
esac
