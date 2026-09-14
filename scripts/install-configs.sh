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
mkdir -p "${HOME}/.config" "${HOME}/.local/bin" "${HOME}/.local/share"

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

# 1. Backup and Deploy Configuration Directories
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

# 2. Deploy Wallpapers
info "Deploying default wallpapers to ~/.config/ml4w/wallpapers/..."
mkdir -p "${HOME}/.config/ml4w/wallpapers"
if [[ -d "${REPO_DIR}/wallpapers" ]]; then
    cp -np "${REPO_DIR}/wallpapers/"* "${HOME}/.config/ml4w/wallpapers/" 2>/dev/null || true
fi

# 3. Deploy Local Binaries
info "Deploying CLI and helper utilities to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
for b in "${REPO_DIR}/bin/"*; do
    if [[ -f "$b" ]]; then
        bname=$(basename "$b")
        cp -p "$b" "${HOME}/.local/bin/${bname}"
        chmod +x "${HOME}/.local/bin/${bname}"
    fi
done

# 4. Deploy Settings App Runtime
if [[ -d "${REPO_DIR}/config/ml4w-dotfiles-settings" ]]; then
    info "Deploying Quickshell Settings App runtime to ~/.local/share/ml4w-dotfiles-settings/..."
    mkdir -p "${HOME}/.local/share/ml4w-dotfiles-settings"
    cp -a "${REPO_DIR}/config/ml4w-dotfiles-settings/"* "${HOME}/.local/share/ml4w-dotfiles-settings/"
fi

# 5. Deploy Shell Dotfiles
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

# 6. Ensure Executable Permissions
info "Ensuring executable permissions across scripts..."
find "${HOME}/.config/ml4w/scripts" -type f -exec chmod +x {} + 2>/dev/null || true
find "${HOME}/.config/ml4w/listeners" -type f -exec chmod +x {} + 2>/dev/null || true
find "${HOME}/.config/hypr/scripts" -type f -exec chmod +x {} + 2>/dev/null || true
find "${HOME}/.config/waybar" -name "*.sh" -type f -exec chmod +x {} + 2>/dev/null || true
find "${HOME}/.config/matugen/post-hook-scripts" -type f -exec chmod +x {} + 2>/dev/null || true
chmod +x "${HOME}/.config/ml4w/listeners.sh" 2>/dev/null || true
chmod +x "${HOME}/.config/ml4w/library.sh" 2>/dev/null || true

success "Configuration deployed successfully. (Backups saved in ${BACKUP_ROOT})"
