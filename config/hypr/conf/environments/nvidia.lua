-- Jeme OS — Non-Waking Dynamic NVIDIA Environment Configuration
-- Dynamically checks display ownership via cached sysfs IDs (jeme-hw-nvidia-display).
-- If NVIDIA drives the display (Direct MUX / Primary VGA), VA-API and GLX are routed to NVIDIA.
-- If Intel/AMD drives the display (Hybrid offload), VA-API/GLX are not globally forced to NVIDIA,
-- protecting Chromium and video players from black-video playback defects.

local is_display_owner = false
local p = io.popen(os.getenv("HOME") .. "/.local/bin/jeme-hw-nvidia-display >/dev/null 2>&1; echo $?")
if p then
    local out = p:read("*l")
    p:close()
    if out == "0" then
        is_display_owner = true
    end
end

-- Fallback check directly via sysfs boot_vga if script or subshell failed
if not is_display_owner then
    local f = io.open("/sys/bus/pci/devices/0000:01:00.0/boot_vga", "r")
    if f then
        local s = f:read("*a")
        f:close()
        if s and s:match("1") then
            is_display_owner = true
        end
    end
end

hl.env("NVD_BACKEND", "direct")

if is_display_owner then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")
end