#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — GTK, Qt & Icon Themes Setup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

header "Jeme OS Themes & Cursor Setup"

ICON_DIR="${HOME}/.local/share/icons"
THEME_DIR="${HOME}/.local/share/themes"
mkdir -p "$ICON_DIR" "$THEME_DIR"

# 1. Install Bibata-Modern-Ice cursor if not present
if [[ ! -d "${ICON_DIR}/Bibata-Modern-Ice" && ! -d "/usr/share/icons/Bibata-Modern-Ice" ]]; then
    info "Installing Bibata-Modern-Ice cursor theme..."
    TEMP_DIR=$(mktemp -d)
    curl -fLo "${TEMP_DIR}/Bibata-Modern-Ice.tar.xz" "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz" 2>/dev/null || true
    if [[ -f "${TEMP_DIR}/Bibata-Modern-Ice.tar.xz" ]]; then
        tar -xf "${TEMP_DIR}/Bibata-Modern-Ice.tar.xz" -C "$ICON_DIR"
    fi
    rm -rf "$TEMP_DIR"
fi

# 2. Install Kora icon theme if not present
if [[ ! -d "${ICON_DIR}/kora" && ! -d "/usr/share/icons/kora" ]]; then
    info "Installing Kora icon theme..."
    TEMP_DIR=$(mktemp -d)
    curl -fLo "${TEMP_DIR}/kora.tar.gz" "https://github.com/bikass/kora/releases/latest/download/kora.tar.gz" 2>/dev/null || true
    if [[ -f "${TEMP_DIR}/kora.tar.gz" ]]; then
        tar -xzf "${TEMP_DIR}/kora.tar.gz" -C "$ICON_DIR"
    fi
    rm -rf "$TEMP_DIR"
fi

# 3. Configure GTK & GSettings
info "Configuring GTK theme preferences..."
if has_cmd gsettings; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' || true
    gsettings set org.gnome.desktop.interface icon-theme 'kora' || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' || true
    gsettings set org.gnome.desktop.interface cursor-size 24 || true
    gsettings set org.gnome.desktop.interface font-name 'Fira Sans 11' || true
    gsettings set org.gnome.desktop.interface document-font-name 'Adwaita Sans 12' || true
    gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font 11' || true
fi

# 4. Synchronize GTK settings.ini
mkdir -p "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0"

cat << 'EOF' > "${HOME}/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name = Adwaita
gtk-icon-theme-name = kora
gtk-font-name = Fira Sans 11
gtk-cursor-theme-name = Bibata-Modern-Ice
gtk-cursor-theme-size = 24
gtk-application-prefer-dark-theme = 1
EOF

cat << 'EOF' > "${HOME}/.config/gtk-4.0/settings.ini"
[Settings]
gtk-theme-name = Adwaita
gtk-icon-theme-name = kora
gtk-font-name = Fira Sans 11
gtk-cursor-theme-name = Bibata-Modern-Ice
gtk-cursor-theme-size = 24
gtk-application-prefer-dark-theme = 1
EOF

success "Themes & cursor setup completed."
