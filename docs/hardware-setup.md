# Jeme OS — Hardware Setup & Multi-GPU Configuration

Jeme OS is engineered to adapt smoothly across diverse hardware topologies, including NVIDIA laptops, AMD Radeon desktops, Intel ultrabooks, and multi-monitor setups.

---

## 1. Monitor Configuration

Hyprland monitors are configured using the Native Lua API in `~/.config/hypr/monitors.lua`.

### Single High-Refresh Laptop Display
```lua
hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@144.0",
    position = "0x0",
    scale = 1.0
})
```

### Dual Monitor Setup (Desktop)
```lua
-- Primary Display (1440p 165Hz)
hl.monitor({
    output = "DP-1",
    mode = "2560x1440@165.0",
    position = "0x0",
    scale = 1.0
})

-- Secondary Display (1080p 60Hz Portrait)
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@60.0",
    position = "2560x0",
    scale = 1.0,
    transform = 1 -- 90 degrees rotation
})
```

### Automatic Re-detection
To re-probe connected monitors at any time:
```bash
jeme detect
```

---

## 2. GPU Configuration & Driver Environments

GPU environment settings are managed in `~/.config/hypr/conf/environments/`:

### 1. NVIDIA Proprietary Driver (`nvidia.lua`)
For systems using dedicated NVIDIA GPUs or dGPU-only laptop modes:
```lua
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
```

### 2. AMD Radeon Open-Source Mesa (`amd.lua`)
For pure AMD GPU systems:
```lua
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("VDPAU_DRIVER", "radeonsi")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
```

### 3. Intel Graphics (`intel.lua`)
For Intel integrated GPUs:
```lua
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
```

### 4. Hybrid GPU / PRIME Offloading (`nvi`)
On hybrid laptops (Intel/AMD iGPU + NVIDIA dGPU), the compositor runs efficiently on the iGPU, while demanding games or applications are launched on the dGPU using the `nvi` launcher:
```bash
nvi steam
nvi blender
```

---

## 3. Variable Refresh Rate (VRR) & Direct Scanout

In `~/.config/hypr/conf/misc.lua`:
* `vrr = 2`: Adaptive sync enabled in fullscreen applications.
* `vrr = 1`: Adaptive sync enabled globally on all VRR-capable monitors.
* `vrr = 0`: Adaptive sync disabled.
