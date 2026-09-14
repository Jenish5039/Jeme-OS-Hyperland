#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Master Installer
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${REPO_DIR}/scripts/lib/common.sh"

header "Jeme OS Rice — Automated Installer"

echo -e "Welcome to the ${CLR_CYAN}${CLR_BOLD}Jeme OS${CLR_RESET} Rice installation on Fedora Linux."
echo -e "This installer will set up Hyprland, Quickshell, Matugen theming, Waybar, Rofi, and required system configurations.\n"

# 1. System Verifications
info "Verifying system environment..."

if is_fedora; then
    success "Fedora Linux detected ($(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '\"'))"
else
    warn "Non-Fedora operating system detected. Jeme OS is tailored for Fedora."
    read -rp "Do you wish to proceed anyway? [y/N]: " proceed_non_fedora
    [[ "$proceed_non_fedora" =~ ^[Yy]$ ]] || exit 1
fi

info "Current User: ${USER} (UID: ${EUID})"

# 2. Package Installation Option
echo
read -rp "Install / update required RPM & Copr packages? [Y/n]: " install_pkgs_choice
if [[ ! "$install_pkgs_choice" =~ ^[Nn]$ ]]; then
    "${REPO_DIR}/scripts/install-packages.sh"
fi

# 3. Deploy Configurations
echo
read -rp "Deploy Jeme OS desktop configurations to ~/.config? [Y/n]: " deploy_configs_choice
if [[ ! "$deploy_configs_choice" =~ ^[Nn]$ ]]; then
    "${REPO_DIR}/scripts/install-configs.sh" --copy
fi

# 4. Hardware & Display Detection
echo
info "Detecting hardware (Monitors, GPU) and generating machine-specific settings..."
"${REPO_DIR}/machine/detect.sh" "${HOME}/.config/hypr"

# 5. Fonts & Themes Setup
echo
read -rp "Install fonts (FiraCode Nerd Font) and icon/cursor themes? [Y/n]: " setup_themes_choice
if [[ ! "$setup_themes_choice" =~ ^[Nn]$ ]]; then
    "${REPO_DIR}/scripts/install-fonts.sh"
    "${REPO_DIR}/scripts/install-themes.sh"
fi

# 6. Matugen Palette Initialization
echo
"${REPO_DIR}/scripts/setup-matugen.sh"

# 7. SDDM Display Manager Setup (Optional)
echo
read -rp "Configure SDDM display manager with Jeme/ML4W theme? [y/N]: " sddm_choice
if [[ "$sddm_choice" =~ ^[Yy]$ ]]; then
    "${REPO_DIR}/scripts/install-sddm.sh"
fi

# 8. Run Doctor / Verification
echo
"${REPO_DIR}/scripts/doctor.sh" || true

echo
header "Installation Complete!"
echo -e "You can manage and customize your rice anytime using: \033[1mjeme <command>\033[0m"
echo -e "To start your desktop, log in through SDDM or launch \033[1mHyprland\033[0m from TTY."
