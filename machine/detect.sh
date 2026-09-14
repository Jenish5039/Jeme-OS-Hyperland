#!/usr/bin/env bash
# ==============================================================================
# Jeme OS — Hardware Detector & Machine Config Generator
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-${HOME}/.config/hypr}"
mkdir -p "${TARGET_DIR}/conf/environments"

echo -e "\033[1;34m[Jeme OS]\033[0m Detecting hardware configuration..."

# ------------------------------------------------------------------------------
# 1. GPU Detection
# ------------------------------------------------------------------------------
DETECTED_GPU="default"
if lspci -nn | grep -iE 'vga|3d|display' | grep -iq 'nvidia'; then
    DETECTED_GPU="nvidia"
    echo -e "  \033[1;32m[✓]\033[0m Detected GPU: \033[1mNVIDIA\033[0m"
elif lspci -nn | grep -iE 'vga|3d|display' | grep -iq 'amd|radeon|advanced micro devices'; then
    DETECTED_GPU="amd"
    echo -e "  \033[1;32m[✓]\033[0m Detected GPU: \033[1mAMD Radeon\033[0m"
elif lspci -nn | grep -iE 'vga|3d|display' | grep -iq 'intel'; then
    DETECTED_GPU="intel"
    echo -e "  \033[1;32m[✓]\033[0m Detected GPU: \033[1mIntel Graphics\033[0m"
else
    echo -e "  \033[1;33m[!]\033[0m Generic / Unknown GPU detected. Using default profile."
fi

# Ensure environment variant files exist
cat << 'EOF' > "${TARGET_DIR}/conf/environments/nvidia.lua"
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
EOF

cat << 'EOF' > "${TARGET_DIR}/conf/environments/amd.lua"
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("VDPAU_DRIVER", "radeonsi")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
EOF

cat << 'EOF' > "${TARGET_DIR}/conf/environments/intel.lua"
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
EOF

cat << 'EOF' > "${TARGET_DIR}/conf/environments/default.lua"
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
EOF

# Update environment.lua loader if present
if [[ -f "${TARGET_DIR}/conf/environment.lua" ]]; then
    sed -i -E "s/local name = \"[^\"]+\"/local name = \"${DETECTED_GPU}.lua\"/" "${TARGET_DIR}/conf/environment.lua"
fi

# ------------------------------------------------------------------------------
# 2. Monitor Detection
# ------------------------------------------------------------------------------
MONITORS_LUA="${TARGET_DIR}/monitors.lua"
MONITORS_CONF="${TARGET_DIR}/monitors.conf"

FOUND_MONITORS=()

# Try hyprctl monitors first
if command -v hyprctl >/dev/null 2>&1 && hyprctl monitors -j >/dev/null 2>&1; then
    while read -r name width height refresh; do
        if [[ -n "$name" ]]; then
            FOUND_MONITORS+=("${name}:${width}x${height}@${refresh}")
        fi
    done < <(hyprctl monitors -j | jq -r '.[] | "\(.name) \(.width) \(.height) \(.refreshRate)"')
fi

# Fallback to sysfs drm if hyprctl not running
if [[ ${#FOUND_MONITORS[@]} -eq 0 ]]; then
    for connector in /sys/class/drm/card*-*/status; do
        if [[ -f "$connector" ]] && grep -q '^connected' "$connector"; then
            cname=$(basename "$(dirname "$connector")" | sed -E 's/card[0-9]+-//')
            # Check for modes
            mode_file="$(dirname "$connector")/modes"
            if [[ -f "$mode_file" ]] && [[ -s "$mode_file" ]]; then
                top_mode=$(head -n1 "$mode_file")
                FOUND_MONITORS+=("${cname}:${top_mode}@preferred")
            else
                FOUND_MONITORS+=("${cname}:preferred@preferred")
            fi
        fi
    done
fi

echo -e "\033[1;34m[Jeme OS]\033[0m Generating monitor configuration..."

if [[ ${#FOUND_MONITORS[@]} -gt 0 ]]; then
    echo "-- Auto-detected display configuration by Jeme OS on $(date +'%Y-%m-%d %H:%M:%S')" > "$MONITORS_LUA"
    echo "# Auto-detected display configuration" > "$MONITORS_CONF"
    
    pos_x=0
    for mon in "${FOUND_MONITORS[@]}"; do
        m_name="${mon%%:*}"
        m_mode="${mon#*:}"
        
        # Parse resolution and rate
        m_res="${m_mode%@*}"
        m_rate="${m_mode#*@}"
        [[ "$m_rate" == "preferred" ]] && m_rate="auto"
        
        echo -e "  \033[1;32m[✓]\033[0m Configured monitor: \033[1m${m_name}\033[0m (${m_res} at position ${pos_x}x0)"
        
        cat << EOF >> "$MONITORS_LUA"
hl.monitor({
    output = "${m_name}",
    mode = "${m_res}@${m_rate}",
    position = "${pos_x}x0",
    scale = 1.0
})
EOF

        echo "monitor = ${m_name}, ${m_res}@${m_rate}, ${pos_x}x0, 1" >> "$MONITORS_CONF"
        
        # Increment horizontal position for multi-monitor setups
        w_px=$(echo "$m_res" | cut -d'x' -f1 2>/dev/null || echo 1920)
        [[ "$w_px" =~ ^[0-9]+$ ]] || w_px=1920
        pos_x=$((pos_x + w_px))
    done
else
    echo -e "  \033[1;33m[!]\033[0m No active monitors probed. Writing generic preferred fallback."
    cat << 'EOF' > "$MONITORS_LUA"
-- Generic Fallback Monitor
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1.0
})
EOF
    echo "monitor = , preferred, auto, 1" > "$MONITORS_CONF"
fi

echo -e "\033[1;32m[✓]\033[0m Machine hardware configuration generated successfully."
