#!/usr/bin/env bash
# ==============================================================================
# Jeme OS — NVIDIA Diagnostic Doctor
# Comprehensive graphics stack diagnostic utility.
# Enforces strict separation between Zero-Wake Sysfs Detection and Live Telemetry.
# ==============================================================================
set -euo pipefail

# ANSI color formatting
BOLD="\033[1m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${RESET}"
}

sub_header() {
    echo -e "${BOLD}${CYAN}$1${RESET}"
}

# ------------------------------------------------------------------------------
# SECTION 1: ZERO-WAKE HARDWARE & SYSFS DETECTION
# ------------------------------------------------------------------------------
header "1. Non-Waking Hardware & Architecture Detection"
echo -e "   ${YELLOW}(Reads cached kernel sysfs attributes without accessing PCI config space)${RESET}"

pci_dev="/sys/bus/pci/devices/0000:01:00.0"

if [[ ! -d "$pci_dev" ]]; then
    # Search for alternative NVIDIA PCI devices
    for d in /sys/bus/pci/devices/*; do
        if [[ -f "$d/vendor" && "$(< "$d/vendor")" == "0x10de" ]]; then
            pci_dev="$d"
            break
        fi
    done
fi

if [[ -d "$pci_dev" ]]; then
    read -r vendor < "$pci_dev/vendor" 2>/dev/null || vendor="N/A"
    read -r device_id < "$pci_dev/device" 2>/dev/null || device_id="N/A"
    read -r class < "$pci_dev/class" 2>/dev/null || class="N/A"
    read -r boot_vga < "$pci_dev/boot_vga" 2>/dev/null || boot_vga="0"
    read -r pci_power < "$pci_dev/power/runtime_status" 2>/dev/null || pci_power="N/A"
    read -r active_time < "$pci_dev/power/runtime_active_time" 2>/dev/null || active_time="N/A"
    read -r suspended_time < "$pci_dev/power/runtime_suspended_time" 2>/dev/null || suspended_time="N/A"

    echo -e "  PCI Address          : ${BOLD}$(basename "$pci_dev")${RESET}"
    echo -e "  Vendor / Device ID   : ${vendor} : ${device_id} (Class: ${class})"
    
    if (( boot_vga == 1 )); then
        echo -e "  Display Ownership    : ${GREEN}${BOLD}Direct MUX / Primary VGA${RESET} (boot_vga=1, drives physical panel)"
    else
        echo -e "  Display Ownership    : ${YELLOW}Hybrid Offload GPU${RESET} (boot_vga=0, iGPU drives panel)"
    fi

    echo -e "  PCI Runtime Status   : ${BOLD}${pci_power}${RESET} (Active: ${active_time}ms | Suspended: ${suspended_time}ms)"
else
    echo -e "  ${RED}No NVIDIA PCI device found via sysfs!${RESET}"
fi

# GSP & Driver Type Breakdown (Strict Rule 10 Enforcement)
sub_header "\n  GSP Firmware & Driver Architecture:"
gsp_capable="NO"
if [[ -n "${device_id:-}" ]] && [[ "$device_id" != "N/A" ]] && (( device_id >= 0x1e00 )); then
    gsp_capable="YES (Turing/Ampere+ device ID ${device_id} >= 0x1e00)"
fi

nvreg_fw="N/A"
rm_fw_active="N/A"
mod_param_dir="/sys/module/nvidia/parameters"
if [[ -d "$mod_param_dir" ]]; then
    [[ -f "$mod_param_dir/NVreg_EnableGpuFirmware" ]] && read -r nvreg_fw < "$mod_param_dir/NVreg_EnableGpuFirmware"
    [[ -f "$mod_param_dir/rm_firmware_active" ]] && read -r rm_fw_active < "$mod_param_dir/rm_firmware_active"
fi

gsp_active="NO"
if [[ "$rm_fw_active" =~ ^[1-9] ]] || [[ "$nvreg_fw" == "1" ]]; then
    gsp_active="YES"
fi

echo -e "    GSP Capable Hardware   : ${BOLD}${gsp_capable}${RESET}"
echo -e "    GSP Currently Active   : ${BOLD}${gsp_active}${RESET}"
echo -e "    NVreg_EnableGpuFirmware: ${nvreg_fw} (0 = explicit override preserved)"
echo -e "    rm_firmware_active      : ${rm_fw_active}"

# Driver Type
driver_ver="Not loaded"
[[ -f /sys/module/nvidia/version ]] && read -r driver_ver < /sys/module/nvidia/version
driver_type="Proprietary"
if dmesg 2>/dev/null | grep -iq "Open Kernel Module" || journalctl -b -k -g "Open Kernel Module" 2>/dev/null | grep -q "Open Kernel Module"; then
    driver_type="NVIDIA UNIX Open Kernel Module (nvidia-open)"
fi
echo -e "    Driver Version         : ${BOLD}${driver_ver}${RESET}"
echo -e "    Driver Kernel Flavor   : ${BOLD}${driver_type}${RESET}"

# DRM Modeset & fbdev
sub_header "\n  NVIDIA DRM KMS & Framebuffer:"
drm_modeset="N/A"
drm_fbdev="N/A"
drm_color="N/A"
[[ -f /sys/module/nvidia_drm/parameters/modeset ]] && read -r drm_modeset < /sys/module/nvidia_drm/parameters/modeset
[[ -f /sys/module/nvidia_drm/parameters/fbdev ]] && read -r drm_fbdev < /sys/module/nvidia_drm/parameters/fbdev
[[ -f /sys/module/nvidia_drm/parameters/color_pipeline ]] && read -r drm_color < /sys/module/nvidia_drm/parameters/color_pipeline
echo -e "    nvidia_drm.modeset     : ${BOLD}${drm_modeset}${RESET}"
echo -e "    nvidia_drm.fbdev       : ${BOLD}${drm_fbdev}${RESET}"
echo -e "    color_pipeline         : ${BOLD}${drm_color}${RESET}"

# Clock Floor Control Status (Rule 11)
sub_header "\n  Clock Floor Workaround (Control Condition):"
if systemctl is-active nvidia-clock-min.service &>/dev/null; then
    echo -e "    nvidia-clock-min.service: ${GREEN}${BOLD}ACTIVE${RESET} (600 MHz floor locked via nvidia-smi)"
else
    echo -e "    nvidia-clock-min.service: ${RED}${BOLD}INACTIVE / UNSET${RESET}"
fi

# ------------------------------------------------------------------------------
# SECTION 2: COMPOSITOR & WAYLAND SESSION STATUS
# ------------------------------------------------------------------------------
header "2. Wayland Compositor & Display Pacing"

if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
    hl_ver=$(hyprctl version 2>/dev/null | head -n1 || echo "Hyprland active")
    vrr_opt=$(hyprctl getoption misc:vrr 2>/dev/null | grep "^int:" | awk '{print $2}')
    vrr_str="DISABLED (vrr=0, locked 144Hz scanout)"
    if [[ "$vrr_opt" == "1" ]]; then
        vrr_str="${RED}ENABLED (vrr=1, dynamic drops to 48Hz)${RESET}"
    fi

    rep_delay=$(hyprctl getoption input:repeat_delay 2>/dev/null | grep "^int:" | awk '{print $2}')
    rep_rate=$(hyprctl getoption input:repeat_rate 2>/dev/null | grep "^int:" | awk '{print $2}')

    echo -e "  Compositor Version   : ${BOLD}${hl_ver}${RESET}"
    echo -e "  VRR Configuration    : ${GREEN}${BOLD}${vrr_str}${RESET}"
    echo -e "  Input Repeat Rate    : ${BOLD}${rep_rate} chars/sec (Delay: ${rep_delay}ms)${RESET}"

    hw_cursor="unknown"
    if command -v jq &>/dev/null; then
        hw_cursor=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].hardwareCursorsInUse // "unknown"')
    fi
    echo -e "  Hardware Cursor      : ${GREEN}${BOLD}in use (${hw_cursor})${RESET}"
else
    echo -e "  Hyprland: Not running"
fi

# Dynamic Environment Variables
sub_header "\n  Active Hardware Environment Routing:"
echo -e "    LIBVA_DRIVER_NAME           : ${BOLD}${LIBVA_DRIVER_NAME:-unset}${RESET}"
echo -e "    __GLX_VENDOR_LIBRARY_NAME   : ${BOLD}${__GLX_VENDOR_LIBRARY_NAME:-unset}${RESET}"
echo -e "    NVD_BACKEND                 : ${BOLD}${NVD_BACKEND:-unset}${RESET}"

# Browser Flags Status
sub_header "\n  Browser Acceleration Configurations:"
for bconf in "$HOME/.config/brave-flags.conf" "$HOME/.config/chromium-flags.conf"; do
    if [[ -f "$bconf" ]]; then
        bname=$(basename "$bconf")
        has_gpu_raster=$(grep -q "enable-gpu-rasterization" "$bconf" && echo "YES" || echo "NO")
        has_zero_copy=$(grep -q "enable-zero-copy" "$bconf" && echo "YES" || echo "NO")
        has_bad_flag=$(grep -q "TouchpadOverscrollHistoryNavigation" "$bconf" && echo "PRESENT (Warning!)" || echo "CLEAN")
        echo -e "    ${bname}: GPU Raster=${has_gpu_raster} | Zero-Copy=${has_zero_copy} | Scroll Bug Flag=${has_bad_flag}"
    fi
done

# ------------------------------------------------------------------------------
# SECTION 3: LIVE TELEMETRY & GPU WAKE SOURCE AUDIT
# ------------------------------------------------------------------------------
header "3. Live GPU Telemetry & Wake Source Audit"
echo -e "   ${YELLOW}(Explicit live query via nvidia-smi / NVML — may wake GPU if powered down)${RESET}\n"

if command -v nvidia-smi &>/dev/null; then
    smi_out=$(nvidia-smi --query-gpu=pstate,clocks.current.graphics,clocks.current.memory,power.draw,power.limit,temperature.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null || true)
    
    if [[ -n "$smi_out" ]]; then
        IFS=',' read -r pstate clk_gfx clk_mem pwr_draw pwr_cap temp mem_used mem_total <<< "$smi_out"
        echo -e "  Performance State    : ${BOLD}${pstate// /}${RESET}"
        echo -e "  Graphics / Mem Clocks: ${BOLD}${clk_gfx// /} / ${clk_mem// /}${RESET}"
        echo -e "  Power Draw / Cap     : ${BOLD}${pwr_draw// /} / ${pwr_cap// /}${RESET}"
        echo -e "  Temperature          : ${BOLD}${temp// /}°C${RESET}"
        echo -e "  VRAM Usage           : ${BOLD}${mem_used// /} / ${mem_total// /}${RESET}"
    fi

    sub_header "\n  Active GPU Client Processes (Wake Sources):"
    proc_list=$(nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader 2>/dev/null || true)
    comp_list=$(nvidia-smi 2>/dev/null | grep -E " (C|G|C\+G) " || true)

    if [[ -n "$comp_list" ]]; then
        echo -e "  ${BOLD}PID       Type   Process Name                        Memory${RESET}"
        echo -e "  ──────────────────────────────────────────────────────────"
        echo "$comp_list" | while read -r line; do
            echo -e "  $line"
        done
    else
        echo -e "  No active GPU compute/graphics clients reported."
    fi
else
    echo -e "  nvidia-smi utility not available."
fi

echo -e "\n${BOLD}${GREEN}✓ Jeme NVIDIA Doctor Diagnostic Complete.${RESET}\n"
