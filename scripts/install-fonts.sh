#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Fonts Setup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

header "Jeme OS Font Setup"

FONT_DIR="${HOME}/.local/share/fonts"
mkdir -p "$FONT_DIR"

info "Checking system fonts..."

# 1. Check FiraCode Nerd Font
if ! fc-list : family | grep -iq 'FiraCode Nerd Font'; then
    info "Installing FiraCode Nerd Font..."
    TEMP_DIR=$(mktemp -d)
    curl -fLo "${TEMP_DIR}/FiraCode.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip || warn "Could not download FiraCode Nerd Font automatically"
    if [[ -f "${TEMP_DIR}/FiraCode.zip" ]]; then
        mkdir -p "${FONT_DIR}/FiraCode"
        unzip -qo "${TEMP_DIR}/FiraCode.zip" -d "${FONT_DIR}/FiraCode"
        rm -rf "$TEMP_DIR"
    fi
else
    success "FiraCode Nerd Font is already installed."
fi

# 2. Rebuild font cache
info "Rebuilding font cache (fc-cache -fv)..."
fc-cache -fv >/dev/null 2>&1 || true

success "Fonts setup completed."
