#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Update System
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${REPO_DIR}/scripts/lib/common.sh"

header "Jeme OS Rice — Safe Updater"

# 1. Check for Git repository updates
if [[ -d "${REPO_DIR}/.git" ]]; then
    info "Checking for remote updates in Git repository..."
    git -C "$REPO_DIR" pull --ff-only || warn "Git pull failed or branch has diverged. Continuing with local update."
fi

# 2. Create timestamped backup of current user configuration
BKP_DIR="${HOME}/.config/jeme-backups/update-$(timestamp)"
mkdir -p "$BKP_DIR"
info "Creating pre-update backup at: ${BKP_DIR}"

CONFIG_MODULES=(
    "hypr"
    "quickshell"
    "ml4w"
    "matugen"
    "waybar"
    "swaync"
    "rofi"
    "kitty"
    "gtk-3.0"
    "gtk-4.0"
    "qt6ct"
    "fastfetch"
    "btop"
    "wlogout"
    "xsettingsd"
    "bashrc"
    "ohmyposh"
)

for mod in "${CONFIG_MODULES[@]}"; do
    if [[ -d "${HOME}/.config/${mod}" ]]; then
        cp -a "${HOME}/.config/${mod}" "${BKP_DIR}/${mod}"
    fi
done

# 3. Preserve machine-specific configurations
TEMP_MACHINE_DIR=$(mktemp -d)
if [[ -f "${HOME}/.config/hypr/monitors.lua" ]]; then
    cp -p "${HOME}/.config/hypr/monitors.lua" "${TEMP_MACHINE_DIR}/monitors.lua"
fi
if [[ -f "${HOME}/.config/hypr/conf/environment.lua" ]]; then
    cp -p "${HOME}/.config/hypr/conf/environment.lua" "${TEMP_MACHINE_DIR}/environment.lua"
fi

# 4. Deploy updated configurations
info "Deploying updated portable configurations..."
"${REPO_DIR}/scripts/install-configs.sh" --copy

# 5. Restore machine-specific configurations
if [[ -f "${TEMP_MACHINE_DIR}/monitors.lua" ]]; then
    info "Restoring preserved machine-specific monitor configuration..."
    cp -p "${TEMP_MACHINE_DIR}/monitors.lua" "${HOME}/.config/hypr/monitors.lua"
fi
if [[ -f "${TEMP_MACHINE_DIR}/environment.lua" ]]; then
    info "Restoring preserved machine-specific GPU environment configuration..."
    cp -p "${TEMP_MACHINE_DIR}/environment.lua" "${HOME}/.config/hypr/conf/environment.lua"
fi
rm -rf "$TEMP_MACHINE_DIR"

# 6. Re-run Matugen theme sync
if has_cmd matugen; then
    info "Refreshing active Material 3 themes..."
    "${REPO_DIR}/scripts/setup-matugen.sh"
fi

# 7. Reload active desktop services if running in session
if is_hyprland; then
    info "Reloading active desktop services..."
    hyprctl reload 2>/dev/null || true
    if has_cmd qs; then
        qs ipc call theme-manager reload 2>/dev/null || true
    fi
    if has_cmd waybar; then
        pkill -SIGUSR2 waybar 2>/dev/null || true
    fi
fi

success "Jeme OS updated successfully! (Pre-update backup in ${BKP_DIR})"
