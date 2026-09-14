#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Backup Utility
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib/common.sh"

header "Jeme OS Configuration Backup"

BACKUP_ROOT="${HOME}/.config/jeme-backups"
BACKUP_NAME="jeme-backup-$(timestamp)"
TARGET_DIR="${BACKUP_ROOT}/${BACKUP_NAME}"

mkdir -p "$TARGET_DIR"

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

info "Backing up active Jeme OS configurations to: ${TARGET_DIR}"

for mod in "${CONFIG_MODULES[@]}"; do
    src="${HOME}/.config/${mod}"
    if [[ -e "$src" ]]; then
        info "  -> Backing up ~/.config/${mod}"
        cp -a "$src" "${TARGET_DIR}/${mod}"
    fi
done

# Backup shell dotfiles
mkdir -p "${TARGET_DIR}/shell"
for f in ".bashrc" ".zshrc" ".gtkrc-2.0" ".Xresources"; do
    if [[ -f "${HOME}/${f}" ]]; then
        cp -p "${HOME}/${f}" "${TARGET_DIR}/shell/${f}"
    fi
done

# Clean out any cache or bytecode files inside the backup
find "$TARGET_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$TARGET_DIR" -type f -name "*.pyc" -delete 2>/dev/null || true

# Create tarball archive alongside directory
TARBALL="${BACKUP_ROOT}/${BACKUP_NAME}.tar.gz"
tar -czf "$TARBALL" -C "$BACKUP_ROOT" "$BACKUP_NAME"

success "Backup completed successfully!"
echo -e "  Directory: \033[1m${TARGET_DIR}\033[0m"
echo -e "  Archive:   \033[1m${TARBALL}\033[0m"
