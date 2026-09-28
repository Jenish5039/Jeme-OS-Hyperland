-- Jeme OS — Non-Waking Dynamic NVIDIA Environment Configuration
-- Dynamically checks display ownership via cached sysfs IDs (jeme-hw-nvidia-display).
-- If NVIDIA drives the display (Direct MUX / Primary VGA), VA-API and GLX are routed to NVIDIA.
-- If Intel/AMD drives the display (Hybrid offload), VA-API/GLX are not globally forced to NVIDIA,
-- protecting Chromium and video players from black-video playback defects.

local is_display_owner = false
local res = os.execute(os.getenv("HOME") .. "/.local/bin/jeme-hw-nvidia-display >/dev/null 2>&1")
if res == true or res == 0 then
    is_display_owner = true
end

hl.env("NVD_BACKEND", "direct")

if is_display_owner then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
end