#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Matugen Palette Initialization
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

header "Jeme OS Matugen Palette Generation"

if ! has_cmd matugen; then
    warn "Matugen binary not found in PATH. Skipping initial palette generation."
    exit 0
fi

# Ensure target directories exist
mkdir -p "${HOME}/.config/ml4w/colors" \
         "${HOME}/.config/hypr" \
         "${HOME}/.config/waybar" \
         "${HOME}/.config/rofi" \
         "${HOME}/.config/swaync" \
         "${HOME}/.config/kitty" \
         "${HOME}/.config/gtk-3.0" \
         "${HOME}/.config/gtk-4.0" \
         "${HOME}/.config/qt6ct/qss" \
         "${HOME}/.cache/wal" \
         "${HOME}/.local/share/ml4w-dotfiles-settings/colors" \
         "${HOME}/.config/quickshell/overview/common"

WALLPAPER="${HOME}/.config/ml4w/wallpapers/default.jpg"
if [[ ! -f "$WALLPAPER" ]]; then
    WALLPAPER="$(find "${HOME}/.config/ml4w/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" \) | head -n1 || true)"
fi

if [[ -f "$WALLPAPER" ]]; then
    info "Generating Material 3 color palettes from: ${WALLPAPER}"
    matugen image "$WALLPAPER" -c "${HOME}/.config/matugen/config.toml" || warn "Matugen generation returned non-zero code."
    
    # Verify critical color targets
    if [[ -f "${HOME}/.config/ml4w/colors/colors.json" ]]; then
        success "Colors generated: ~/.config/ml4w/colors/colors.json"
    fi
    if [[ -f "${HOME}/.config/waybar/colors.css" ]]; then
        success "Colors generated: ~/.config/waybar/colors.css"
    fi
    if [[ -f "${HOME}/.config/hypr/colors.lua" ]]; then
        success "Colors generated: ~/.config/hypr/colors.lua"
    fi
else
    warn "No wallpaper found to generate initial theme. Place a wallpaper in ~/.config/ml4w/wallpapers/ and run ml4w-wallpaper."
fi

success "Matugen initialization completed."
