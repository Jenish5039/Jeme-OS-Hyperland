#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Uninstaller / Cleanup Utility
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib/common.sh"

header "Jeme OS Rice — Uninstallation & Reversion"

echo -e "This will remove Jeme OS configurations from ~/.config/."
echo -e "Existing configurations will be backed up before removal.\n"

read -rp "Are you sure you want to proceed with uninstallation? [y/N]: " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || exit 0

BACKUP_ROOT="${HOME}/.config/jeme-backups/uninstall-$(timestamp)"
mkdir -p "$BACKUP_ROOT"

CONFIG_MODULES=(
    "hypr"
    "quickshell"
    "ml4w"
    "matugen"
    "waybar"
    "swaync"
    "rofi"
    "kitty"
    "fastfetch"
    "btop"
    "wlogout"
    "xsettingsd"
    "ohmyposh"
)

for mod in "${CONFIG_MODULES[@]}"; do
    target="${HOME}/.config/${mod}"
    if [[ -e "$target" || -L "$target" ]]; then
        info "Archiving ~/.config/${mod} -> ${BACKUP_ROOT}/${mod}"
        mv "$target" "${BACKUP_ROOT}/${mod}"
    fi
done

# Remove user local binaries installed by Jeme
for b in "jeme" "qs" "quickshell" "nvi" "sddm-avatar"; do
    if [[ -f "${HOME}/.local/bin/${b}" ]]; then
        rm -f "${HOME}/.local/bin/${b}"
    fi
done

success "Jeme OS configurations removed. Final backup preserved in: ${BACKUP_ROOT}"
