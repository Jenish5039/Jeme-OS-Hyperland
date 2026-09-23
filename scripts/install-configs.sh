#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Configuration Deployer & Linker
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

MODE="${1:---copy}" # --copy or --symlink

header "Jeme OS Configuration Deployment (${MODE})"

BACKUP_ROOT="${HOME}/.config/jeme-backups/$(timestamp)"
mkdir -p "$BACKUP_ROOT"
mkdir -p "${HOME}/.config" "${HOME}/.local/bin" "${HOME}/.local/share" "${HOME}/.cache/ml4w/hyprland-dotfiles"

# ------------------------------------------------------------------------------
# 1. Preserve User Wallpaper & Hardware State Before Any Deployment
# ------------------------------------------------------------------------------
PRESERVE_DIR=$(mktemp -d)

# Detect if user already has an active wallpaper state or configuration
HAS_EXISTING_WALLPAPER=false
if [[ -f "${HOME}/.cache/ml4w/hyprland-dotfiles/current_wallpaper" ]]; then
    HAS_EXISTING_WALLPAPER=true
    cp -p "${HOME}/.cache/ml4w/hyprland-dotfiles/current_wallpaper" "${PRESERVE_DIR}/current_wallpaper"
fi

WALLPAPER_SETTINGS=(
    "wallpaper-mode"
    "wallpaper-engine-config.json"
    "wallpaper-engine-favorites.json"
    "wallpaper-engine-recents.json"
    "wallpaper-engine-battery-policy"
    "wallpaper-theming"
    "wallpaper-folder"
    "wallpaper-effect"
    "wallpaper-transition-effect"
    "wallpaper-automation"
    "blur.sh"
    "dock.json"
    "statusbar.json"
)

for wset in "${WALLPAPER_SETTINGS[@]}"; do
    if [[ -f "${HOME}/.config/ml4w/settings/${wset}" ]]; then
        cp -p "${HOME}/.config/ml4w/settings/${wset}" "${PRESERVE_DIR}/${wset}"
    fi
done

# Preserve machine-specific Hyprland configuration if present
if [[ -f "${HOME}/.config/hypr/monitors.lua" ]]; then
    cp -p "${HOME}/.config/hypr/monitors.lua" "${PRESERVE_DIR}/monitors.lua"
fi
if [[ -f "${HOME}/.config/hypr/conf/environment.lua" ]]; then
    cp -p "${HOME}/.config/hypr/conf/environment.lua" "${PRESERVE_DIR}/environment.lua"
fi

# ------------------------------------------------------------------------------
# 2. Deploy Configuration Modules
# ------------------------------------------------------------------------------
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
    src="${REPO_DIR}/config/${mod}"
    dst="${HOME}/.config/${mod}"

    if [[ ! -d "$src" ]]; then
        continue
    fi

    # Backup existing destination if it exists
    if [[ -e "$dst" || -L "$dst" ]]; then
        info "Backing up ~/.config/${mod} -> ${BACKUP_ROOT}/${mod}"
        cp -a "$dst" "${BACKUP_ROOT}/${mod}"
        rm -rf "$dst"
    fi

    if [[ "$MODE" == "--symlink" ]]; then
        info "Symlinking ${src} -> ${dst}"
        ln -sf "$src" "$dst"
    else
        info "Copying ${src} -> ${dst}"
        cp -a "$src" "$dst"
    fi
done

# ------------------------------------------------------------------------------
# 3. Restore Preserved User Wallpaper State (or Provision First-Run Defaults)
# ------------------------------------------------------------------------------
if [[ "$HAS_EXISTING_WALLPAPER" == true ]]; then
    info "Preserving existing user wallpaper configuration..."
    if [[ -f "${PRESERVE_DIR}/current_wallpaper" ]]; then
        cp -p "${PRESERVE_DIR}/current_wallpaper" "${HOME}/.cache/ml4w/hyprland-dotfiles/current_wallpaper"
    fi
    for wset in "${WALLPAPER_SETTINGS[@]}"; do
        if [[ -f "${PRESERVE_DIR}/${wset}" ]]; then
            cp -p "${PRESERVE_DIR}/${wset}" "${HOME}/.config/ml4w/settings/${wset}"
        fi
    done
else
    info "First-run detected: Initializing default Awww wallpaper state..."
    echo "${HOME}/.config/ml4w/wallpapers/default.jpg" > "${HOME}/.cache/ml4w/hyprland-dotfiles/current_wallpaper"
    echo "static" > "${HOME}/.config/ml4w/settings/wallpaper-mode"
    echo "{}" > "${HOME}/.config/ml4w/settings/wallpaper-engine-config.json"
    echo "[]" > "${HOME}/.config/ml4w/settings/wallpaper-engine-favorites.json"
    echo "[]" > "${HOME}/.config/ml4w/settings/wallpaper-engine-recents.json"
fi

# Restore machine-specific configs if preserved
if [[ -f "${PRESERVE_DIR}/monitors.lua" ]]; then
    cp -p "${PRESERVE_DIR}/monitors.lua" "${HOME}/.config/hypr/monitors.lua"
fi
if [[ -f "${PRESERVE_DIR}/environment.lua" ]]; then
    cp -p "${PRESERVE_DIR}/environment.lua" "${HOME}/.config/hypr/conf/environment.lua"
fi

rm -rf "$PRESERVE_DIR"

# ------------------------------------------------------------------------------
# 4. Deploy Wallpapers (Non-destructive)
# ------------------------------------------------------------------------------
info "Deploying default wallpapers to ~/.config/ml4w/wallpapers/..."
mkdir -p "${HOME}/.config/ml4w/wallpapers"
if [[ -d "${REPO_DIR}/wallpapers" ]]; then
    cp -np "${REPO_DIR}/wallpapers/"* "${HOME}/.config/ml4w/wallpapers/" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 5. Deploy Local Binaries & Runtime Apps
# ------------------------------------------------------------------------------
info "Deploying CLI and helper utilities to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
for b in "${REPO_DIR}/bin/"*; do
    if [[ -f "$b" ]]; then
        bname=$(basename "$b")
        cp -p "$b" "${HOME}/.local/bin/${bname}"
        chmod +x "${HOME}/.local/bin/${bname}"
    fi
done
if [[ -d "${REPO_DIR}/config/ml4w-dotfiles-settings" ]]; then
    info "Deploying Quickshell Settings App runtime to ~/.local/share/ml4w-dotfiles-settings/..."
    mkdir -p "${HOME}/.local/share/ml4w-dotfiles-settings"
    cp -a "${REPO_DIR}/config/ml4w-dotfiles-settings/"* "${HOME}/.local/share/ml4w-dotfiles-settings/"
fi

# ------------------------------------------------------------------------------
# 5b. Deploy Systemd User Units
# ------------------------------------------------------------------------------
if [[ -d "${REPO_DIR}/systemd/user" ]]; then
    info "Deploying systemd user services to ~/.config/systemd/user/..."
    mkdir -p "${HOME}/.config/systemd/user"
    for s in "${REPO_DIR}/systemd/user/"*; do
        if [[ -f "$s" ]]; then
            sname=$(basename "$s")
            cp -p "$s" "${HOME}/.config/systemd/user/${sname}"
        fi
    done
    if [[ -f "${HOME}/.local/bin/jeme-power-switcher" ]]; then
        mkdir -p "${HOME}/.config/ml4w/scripts"
        ln -sf "${HOME}/.local/bin/jeme-power-switcher" "${HOME}/.config/ml4w/scripts/jeme-power-switcher"
    fi
    if command -v systemctl &>/dev/null; then
        systemctl --user daemon-reload 2>/dev/null || true
        systemctl --user enable jeme-power-switcher.service 2>/dev/null || true
    fi
fi


# ------------------------------------------------------------------------------
# 6. Deploy Shell Dotfiles
# ------------------------------------------------------------------------------
info "Deploying shell dotfiles (~/.bashrc, ~/.zshrc)..."
if [[ -d "${REPO_DIR}/config/shell" ]]; then
    for sf in "${REPO_DIR}/config/shell/".*; do
        if [[ -f "$sf" ]]; then
            sf_name=$(basename "$sf")
            [[ "$sf_name" == "." || "$sf_name" == ".." ]] && continue
            if [[ -f "${HOME}/${sf_name}" && ! -L "${HOME}/${sf_name}" ]]; then
                cp -p "${HOME}/${sf_name}" "${BACKUP_ROOT}/${sf_name}"
            fi
            cp -p "$sf" "${HOME}/${sf_name}"
        fi
    done
fi

# ------------------------------------------------------------------------------
# 7. Ensure Executable Permissions
# ------------------------------------------------------------------------------
info "Ensuring executable permissions across scripts..."
find "${HOME}/.config/ml4w/scripts" -type f -exec chmod +x {} + 2>/dev/null || true
find "${HOME}/.config/ml4w/listeners" -type f -exec chmod +x {} + 2>/dev/null || true
find "${HOME}/.config/hypr/scripts" -type f -exec chmod +x {} + 2>/dev/null || true
find "${HOME}/.config/waybar" -name "*.sh" -type f -exec chmod +x {} + 2>/dev/null || true
find "${HOME}/.config/matugen/post-hook-scripts" -type f -exec chmod +x {} + 2>/dev/null || true
chmod +x "${HOME}/.config/ml4w/listeners.sh" 2>/dev/null || true
chmod +x "${HOME}/.config/ml4w/library.sh" 2>/dev/null || true

success "Configuration deployed successfully. (Backups saved in ${BACKUP_ROOT})"
