#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Master Installer
# Self-contained Hyprland Desktop Environment on Fedora
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${REPO_DIR}/scripts/lib/common.sh"

NON_INTERACTIVE=false
if [[ "${1:-}" == "-y" || "${1:-}" == "--yes" || "${1:-}" == "--non-interactive" ]]; then
    NON_INTERACTIVE=true
fi

header "Jeme OS Rice — Automated Installer"

echo -e "Welcome to the ${CLR_CYAN}${CLR_BOLD}Jeme OS${CLR_RESET} Rice bootstrap for Fedora Linux."
echo -e "This installer provisions a self-contained Hyprland desktop environment with Quickshell,"
echo -e "Matugen dynamic theming, Nautilus file management, PipeWire audio, and complete desktop services."
echo -e "${CLR_GRAY}Note: GNOME is NOT required. Existing desktop environments will remain intact.${CLR_RESET}\n"

# 1. System Verifications
info "Verifying system environment..."

if is_fedora; then
    success "Fedora Linux detected ($(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '\"'))"
else
    warn "Non-Fedora operating system detected. Jeme OS is tailored for Fedora."
    if [[ "$NON_INTERACTIVE" == false ]]; then
        read -rp "Do you wish to proceed anyway? [y/N]: " proceed_non_fedora
        [[ "$proceed_non_fedora" =~ ^[Yy]$ ]] || exit 1
    fi
fi

info "Current User: ${USER} (UID: ${EUID})"

# 2. Package Installation
echo
if [[ "$NON_INTERACTIVE" == true ]]; then
    "${REPO_DIR}/scripts/install-packages.sh"
else
    read -rp "Install / update required RPM & Copr packages? [Y/n]: " install_pkgs_choice
    if [[ ! "$install_pkgs_choice" =~ ^[Nn]$ ]]; then
        "${REPO_DIR}/scripts/install-packages.sh"
    fi
fi

# 3. Deploy Configurations
echo
if [[ "$NON_INTERACTIVE" == true ]]; then
    "${REPO_DIR}/scripts/install-configs.sh" --copy
else
    read -rp "Deploy Jeme OS desktop configurations to ~/.config? [Y/n]: " deploy_configs_choice
    if [[ ! "$deploy_configs_choice" =~ ^[Nn]$ ]]; then
        "${REPO_DIR}/scripts/install-configs.sh" --copy
    fi
fi

# 4. Hardware & Display Detection
echo
info "Detecting hardware (GPU, Monitors, Chassis) and generating machine-specific settings..."
"${REPO_DIR}/machine/detect.sh" "${HOME}/.config/hypr"

# 5. Fonts & Themes Setup
echo
if [[ "$NON_INTERACTIVE" == true ]]; then
    "${REPO_DIR}/scripts/install-fonts.sh"
    "${REPO_DIR}/scripts/install-themes.sh"
else
    read -rp "Install fonts (FiraCode Nerd Font) and icon/cursor themes? [Y/n]: " setup_themes_choice
    if [[ ! "$setup_themes_choice" =~ ^[Nn]$ ]]; then
        "${REPO_DIR}/scripts/install-fonts.sh"
        "${REPO_DIR}/scripts/install-themes.sh"
    fi
fi

# 6. Matugen Palette Initialization
echo
"${REPO_DIR}/scripts/setup-matugen.sh"

# 7. Display Manager / Session Configuration
echo
CURRENT_DM="$(systemctl is-active display-manager.service 2>/dev/null || echo "none")"
if [[ "$CURRENT_DM" == "active" ]]; then
    info "Active display manager detected. Preserving existing display manager."
    info "Hyprland session has been registered in /usr/share/wayland-sessions/hyprland.desktop."
else
    if [[ "$NON_INTERACTIVE" == false ]]; then
        read -rp "Configure and enable SDDM with Jeme/ML4W theme? [y/N]: " sddm_choice
        if [[ "$sddm_choice" =~ ^[Yy]$ ]]; then
            "${REPO_DIR}/scripts/install-sddm.sh"
        fi
    fi
fi

# 8. Run Doctor / System Diagnostics
echo
"${REPO_DIR}/scripts/doctor.sh" || true

echo
header "Installation Complete!"
echo -e "You can manage and customize your desktop anytime using: \033[1mjeme <command>\033[0m"
echo -e "To launch your session:"
echo -e "  • Select \033[1mHyprland\033[0m at your login screen (GDM, SDDM, or greetd)"
echo -e "  • Or type \033[1mHyprland\033[0m from any TTY"
