#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Package & Dependency Installer (Fedora)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

header "Jeme OS Package Installation"

if ! is_fedora; then
    warn "Non-Fedora distribution detected. Package installation via DNF may fail."
    read -rp "Continue anyway? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
fi

require_sudo

# 1. Enable Required & Recommended Copr Repositories
info "Enabling required Copr repositories..."
if [[ -f "${REPO_DIR}/packages/copr-repos.txt" ]]; then
    while IFS= read -r repo || [[ -n "$repo" ]]; do
        [[ "$repo" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${repo// }" ]] && continue
        
        info "Enabling Copr repo: $repo"
        sudo dnf copr enable -y "$repo" || warn "Failed to enable Copr repo: $repo (ignoring)"
    done < "${REPO_DIR}/packages/copr-repos.txt"
fi

# 2. Install Required RPM Packages
info "Installing required RPM packages for self-contained desktop environment..."
if [[ -f "${REPO_DIR}/packages/fedora-required.txt" ]]; then
    PACKAGES=()
    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
        [[ "$pkg" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${pkg// }" ]] && continue
        PACKAGES+=("$pkg")
    done < "${REPO_DIR}/packages/fedora-required.txt"

    if [[ ${#PACKAGES[@]} -gt 0 ]]; then
        sudo dnf install -y "${PACKAGES[@]}" || warn "Some packages encountered issues during installation."
    fi
fi

# 3. Ensure User Directories are Initialized
if has_cmd xdg-user-dirs-update; then
    info "Initializing standard user directories (Downloads, Documents, Pictures, etc.)..."
    xdg-user-dirs-update || true
fi

# 4. Ensure Matugen is available
if ! has_cmd matugen; then
    info "Installing Matugen color generator..."
    if has_cmd cargo; then
        cargo install matugen || warn "Failed to install matugen via cargo"
    elif has_cmd dnf; then
        sudo dnf copr enable -y errornointernet/ripgrep || true
        sudo dnf install -y matugen || warn "Matugen package not found in repos. You can install via 'cargo install matugen'."
    fi
fi

# 5. Ensure Hyprland Wayland Session Entry is registered for Display Managers
if [[ ! -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
    info "Registering Hyprland session entry in /usr/share/wayland-sessions/hyprland.desktop..."
    sudo mkdir -p /usr/share/wayland-sessions
    cat << 'EOF' | sudo tee /usr/share/wayland-sessions/hyprland.desktop >/dev/null
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
Keywords=tiling;wayland;compositor;
EOF
fi

# 6. Enable Essential User Services
info "Enabling essential desktop user systemd services..."
systemctl --user enable pipewire.service wireplumber.service 2>/dev/null || true
if systemctl --user list-unit-files hyprpolkitagent.service >/dev/null 2>&1; then
    systemctl --user enable hyprpolkitagent.service 2>/dev/null || true
fi

success "Package installation completed."
