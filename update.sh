#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Safe Updater
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

# 3. Deploy updated configurations (with automatic user wallpaper & hardware state preservation)
info "Deploying updated portable configurations..."
"${REPO_DIR}/scripts/install-configs.sh" --copy

# 4. Re-run Matugen theme sync
if has_cmd matugen; then
    info "Refreshing active Material 3 themes..."
    "${REPO_DIR}/scripts/setup-matugen.sh"
fi

# 5. Reload active desktop services if running in session
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

success "Jeme OS updated successfully! (Pre-update backup preserved in ${BKP_DIR})"
