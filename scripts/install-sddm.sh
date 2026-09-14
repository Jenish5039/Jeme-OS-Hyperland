#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — SDDM Theme & Display Manager Setup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

header "Jeme OS SDDM Setup"

require_sudo

# 1. Copy SDDM Theme
if [[ -d "${REPO_DIR}/sddm/themes/ml4w" ]]; then
    info "Installing ML4W SDDM theme to /usr/share/sddm/themes/ml4w..."
    sudo mkdir -p /usr/share/sddm/themes
    sudo cp -a "${REPO_DIR}/sddm/themes/ml4w" /usr/share/sddm/themes/
fi

# 2. Configure /etc/sddm.conf
info "Configuring /etc/sddm.conf..."
sudo mkdir -p /etc/sddm.conf.d

cat << 'EOF' | sudo tee /etc/sddm.conf >/dev/null
[Theme]
Current=ml4w

[General]
InputMethod=qtvirtualkeyboard
GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/ml4w/components/,QT_IM_MODULE=qtvirtualkeyboard

[Wayland]
SessionDir=/usr/share/wayland-sessions
EOF

# 3. Setup AccountsService user avatar if lock image exists
USER_ICON="${HOME}/.config/ml4w/wallpapers/lock.png"
if [[ -f "$USER_ICON" ]]; then
    info "Configuring user login avatar via AccountsService..."
    sudo mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users
    sudo cp "$USER_ICON" "/var/lib/AccountsService/icons/${USER}"
    sudo chmod 644 "/var/lib/AccountsService/icons/${USER}"

    cat << EOF | sudo tee "/var/lib/AccountsService/users/${USER}" >/dev/null
[User]
Icon=/var/lib/AccountsService/icons/${USER}
Session=hyprland
SystemAccount=false
EOF
    sudo chmod 600 "/var/lib/AccountsService/users/${USER}"
fi

# 4. Enable SDDM service
info "Enabling sddm.service..."
sudo systemctl enable sddm.service || warn "Could not enable sddm.service"

success "SDDM configuration completed."
