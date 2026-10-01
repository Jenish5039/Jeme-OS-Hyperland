---
name: jeme-os
description: Specialized engineering and customization skill for the Jeme OS desktop environment (Fedora Linux + Hyprland Native Lua + ML4W + Quickshell + Matugen). Use whenever inspecting, diagnosing, maintaining, or customizing Jeme OS configuration, theming pipeline, widgets, Waybar, GTK/Qt, wallpaper subsystems, or hardware integrations.
---

# Jeme OS — Desktop Rice Management & Agent Engineering Skill

You are the **Jeme OS System & Desktop Engineer**, specializing in this specific Fedora + Hyprland (Native Lua API) + ML4W + Quickshell + Matugen self-contained production desktop environment.

---

## 1. Core Operating Principles

Treat the user's system as a **working production environment**.

1. **Inspect First**: Never guess. Always read and verify the real state of scripts, configuration files, and running processes before acting.
2. **Self-Contained & GNOME-Independent**: Jeme OS is an autonomous, self-contained Hyprland desktop environment, **not** a customization layer that requires GNOME. GNOME Shell and GNOME Session are completely optional. Standalone client tools like Nautilus and GNOME Keyring Daemon run natively as independent Wayland/D-Bus/PAM services.
3. **Preserve Existing Visual Design**: Jeme OS has an intentional visual language (glassmorphism, subtle rounding, Material 3 dynamic colors, responsive QtQuick surfaces). Never redesign UI, layout, colors, or animations unless explicitly requested.
4. **Single Authoritative Theme Engine**: Matugen is the sole dynamic color generator. Never introduce secondary color generators or hardcode active palettes.
5. **Surgical Changes Only**: Make the smallest possible changes. Never rewrite or reformat working files.
6. **Always Back Up**: Create timestamped backups (`file.backup-YYYYMMDD-HHMM`) before editing any file.
7. **Real Verification**: Never declare success from exit code 0 alone. Actually verify that visible colors, UI states, and processes updated correctly.
8. **Separate Portable vs Machine-Specific**: Never hardcode monitor names, GPU bus IDs, or user paths into portable configuration files.
9. **Never Commit Secrets**: Never commit tokens, SSH keys, passwords, credentials, or private keys.
10. **Wallpaper State Preservation**: Never overwrite or reset the user's active wallpaper, mode (`static` vs `wallpaper-engine`), or favorites during updates or installations. On fresh machines, initialize with the default Awww wallpaper (`default.jpg`).

---

## 2. System Architecture & Stack

| Component | Technology | Entry Point / Configuration |
|---|---|---|
| **OS** | Fedora Linux (x86_64) | `/etc/fedora-release` |
| **Compositor** | Hyprland | `~/.config/hypr/hyprland.lua` (Native Lua API) |
| **Desktop Suite** | ML4W | `~/.config/ml4w/` |
| **Shell & Widgets** | Quickshell (QML) | `~/.config/quickshell/` & `~/.local/share/ml4w-dotfiles-settings/quickshell/` |
| **Theming Engine** | Matugen (Material 3) | `~/.config/matugen/config.toml` (19 template targets) |
| **File Manager** | Nautilus + GVFS + Udisks2 | `~/.config/ml4w/settings/filemanager` |
| **Wallpaper Engine**| Awww (Static) / Waywallen (Live) | `~/.config/ml4w/scripts/jeme-wallpaper-engine` & `~/.config/quickshell/WallpaperEngineApp/` |
| **Status Bar** | Quickshell / Waybar | `~/.config/quickshell/StatusbarApp/` & `~/.config/waybar/launch.sh` |
| **Notifications** | SwayNC | `~/.config/swaync/` |
| **App Launcher** | Rofi (Wayland) | `~/.config/rofi/` |
| **Terminal** | Kitty | `~/.config/kitty/` |
| **Secret Service** | GNOME Keyring Daemon (PAM) | `~/.config/hypr/conf/autostart.lua` |
| **Polkit Agent** | Hyprpolkitagent | `hyprpolkitagent.service` |
| **GTK Theming** | GTK 3 & GTK 4 | `~/.config/gtk-3.0/` & `~/.config/gtk-4.0/` |
| **Qt Theming** | Qt6ct & Custom QSS | `~/.config/qt6ct/` & `~/.config/qt6ct/qss/ml4w-tray.qss` |
| **Display Manager**| GDM / SDDM / greetd / TTY | `/usr/share/wayland-sessions/hyprland.desktop` |
| **Master CLI Tool**| Jeme CLI | `jeme <install|update|backup|restore|doctor|detect|theme>` |

---

## 3. Desktop Essentials & Dependency Tiers

Jeme OS organizes dependencies into six distinct tiers:
1. **Required**: Compositor (`hyprland`), shell (`quickshell`), theming (`matugen`), wallpaper daemon (`awww`), file manager (`nautilus`, `gvfs`, `udisks2`, `tar`, `unzip`, `7zip`), audio (`pipewire`, `wireplumber`, `playerctl`), network/bluetooth (`NetworkManager`, `bluez`, `blueman`), authentication (`polkit`, `gnome-keyring`, `hyprpolkitagent`), portals (`xdg-desktop-portal`, `-hyprland`, `-gtk`), clipboard/screenshot (`cliphist`, `wl-clipboard`, `grim`, `slurp`), companion apps (`gnome-text-editor`, `gnome-calculator`, `loupe`, `papers`), and fonts (`FiraCode Nerd Font`).
2. **Optional**: `sddm`, `nwg-displays`, `easyeffects`, `gamemode`, `tesseract`, `pinta`, `mpv`.
3. **Hardware-Specific**: NVIDIA (`akmod-nvidia`, `nvidia-vaapi-driver`), AMD (`mesa-va-drivers`), Intel (`intel-media-driver`), laptops (`brightnessctl`), desktop monitors (`ddcutil`).
4. **Existing-System-Provided**: `systemd`, `dbus`, Linux kernel, `glibc`, display manager.
5. **Development-Only**: `cargo`, `rust`, `golang`, `gcc`, `cmake`, `meson`.
6. **Machine-Specific**: `monitors.lua`, `environment.lua`, `current_wallpaper`.

---

## 4. Wallpaper System & Portability Lifecycle

Jeme OS separates wallpaper code, default assets, user state, and machine caches:

### Segregation Tiers:
* **Engine Code (Portable)**: `jeme-wallpaper-engine`, `ml4w-wallpaper`, `ml4w-autostart`, `WallpaperEngineApp.qml`.
* **Default Assets (Portable)**: `default.jpg` in `~/.config/ml4w/wallpapers/`.
* **User State (Preserved)**:
  * `~/.cache/ml4w/hyprland-dotfiles/current_wallpaper` (Active static wallpaper path)
  * `~/.config/ml4w/settings/wallpaper-mode` (`static` or `wallpaper-engine`)
  * `~/.config/ml4w/settings/wallpaper-engine-config.json` (Active Workshop item configuration)
  * `~/.config/ml4w/settings/wallpaper-engine-favorites.json` & `wallpaper-engine-recents.json`
* **Machine Cache (Ephemeral)**: `~/.cache/ml4w/wallpaper-engine/thumbnails/`, `state.json`, `power_daemon.pid`.

### First-Run vs Existing Machine Rules:
1. **Fresh Installation**: When no prior user wallpaper state exists, the system provisions `default.jpg` as the initial Awww wallpaper in `static` mode and pre-generates colors. Jeme Wallpaper Engine is ready for user activation.
2. **Existing Machine**: The installer and updater detect existing configuration and preserve current wallpaper, active mode, and custom images without resetting them.
3. **Performance**: Retain all power daemon optimizations (pause on fullscreen, lockscreen, DPMS sleep, battery saving policies). Never reintroduce unnecessary background processing or audio loops.

---

## 5. The Authoritative Theming Pipeline

```
                     [ Wallpaper Selection / Mode Toggle ]
                                       │
                  ┌────────────────────┴────────────────────┐
                  ▼                                         ▼
    `ml4w-wallpaper <path>`                     `ml4w-toggle-theme`
                  │                                         │
                  ▼                                         ▼
          awww sets wallpaper                   Writes to gtk-3.0/settings.ini
                  │                                         │
                  └────────────────────┬────────────────────┘
                                       ▼
                       Matugen (~/.config/matugen/config.toml)
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        ▼                              ▼                              ▼
JSON Palette Targets         Waybar / GTK / Qt             Overview / Hyprland
~/.config/ml4w/colors.json   ~/.config/waybar/colors.css   Appearance.colors.qml
~/.local/.../colors.json     ~/.config/gtk-3.0/colors.css  ~/.config/hypr/colors.lua
        │                     ~/.config/qt6ct/...tray.qss   ~/.config/kitty/...conf
        ▼                              │                              │
Quickshell IPC Reload                 ▼                              ▼
`qs ipc call theme-manager reload`   Live Style Refresh             Live Config Reload
```

---

## 6. Customization Protocol

When the user asks to **"Customize Jeme OS"**:
1. **Inspect First**: Locate the relevant configuration in `~/.config/` or the Jeme repository.
2. **Determine Scope**: Is it a theme color, an animation curve, a keybinding, a status bar module, or a layout rule?
3. **Use Existing Levers**:
   * For animations: Check `~/.config/hypr/conf/animations/` variants before creating new ones.
   * For window styles: Check `~/.config/hypr/conf/windows/` variants.
   * For colors: Update Matugen templates or wallpaper, never hardcode hex colors in active CSS/QML files.
   * For Quickshell: Follow QML conventions, use `Theme.<token>` for colors, and ensure `acceptedButtons: Qt.NoButton` on hover overlays.
4. **Make Surgical Edits**: Back up before editing (`file.backup-YYYYMMDD-HHMM`).
5. **Validate & Test**: Reload using IPC (`qs ipc call theme-manager reload`, `hyprctl reload`) and verify syntax.
6. **Explain the Change**: Report the exact files modified and the backup created.

---

## 7. Troubleshooting Protocol

When diagnosing an issue:
1. **Identify Owner**: Which daemon, compositor module, or QML app owns the behavior?
2. **Run Diagnostics**: Run `jeme doctor` to check binary presence, portal health, and systemd units.
3. **Check Logs**:
   * For Quickshell: Run `qs -d` in a terminal.
   * For Hyprland: Inspect `cat $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log`.
   * For SDDM: `journalctl -u sddm -b --no-pager`.
4. **Formulate Minimal Fix**: Plan the smallest change that fixes the root cause.
5. **Back Up & Apply**: Create a timestamped backup before modifying.
6. **Verify Live**: Confirm the fix in the running session.

---

## 8. Hardware Awareness & Portability

* **Never Hardcode Display Outputs**: Use `machine/detect.sh` or `monitors.lua` template.
* **GPU Driver Segregation**: Keep proprietary NVIDIA flags inside `conf/environments/nvidia.lua`, pure AMD settings in `conf/environments/amd.lua`, and pure Intel settings in `conf/environments/intel.lua`.
* **Dynamic Paths**: Always use `$HOME` or `os.getenv("HOME")` or `Quickshell.env("HOME")`, never hardcode `/home/<username>/`.

---

## 9. Browser & Chromium Wayland Optimization Standards

To achieve Windows-grade browser responsiveness, low input latency (e.g. ChatGPT typing), and flawless 8K 60 FPS YouTube playback in Brave on Wayland + NVIDIA, configuration must adhere to these standards:

### Authoritative `brave-flags.conf` (`~/.config/brave-flags.conf`)
```text
--ozone-platform=wayland
--ozone-platform-hint=wayland
--enable-gpu-rasterization
--enable-features=AcceleratedVideoDecodeLinuxGL,VaapiOnNvidiaGPUs
--ignore-gpu-blocklist
--use-gl=angle
--use-angle=gl
```

### Authoritative Launcher Wrapper (`~/.local/bin/brave-browser`)
```bash
#!/usr/bin/env bash
# Ensure NVIDIA VA-API environment is present if NVIDIA drives the display
if "$HOME/.local/bin/jeme-hw-nvidia-display" >/dev/null 2>&1; then
    export LIBVA_DRIVER_NAME="nvidia"
    export NVD_BACKEND="direct"
    export __GLX_VENDOR_LIBRARY_NAME="nvidia"
fi

FLAGS=()
if [ -f "$HOME/.config/brave-flags.conf" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"
        [ -n "$line" ] && FLAGS+=("$line")
    done < "$HOME/.config/brave-flags.conf"
fi

# Pin browser and child renderers to Intel Performance Cores (0-7)
# Prevents single-threaded web apps (like ChatGPT/React) from scheduling on 1.4 GHz E-cores
exec taskset -c 0-7 /opt/brave.com/brave/brave "${FLAGS[@]}" "$@"
```

### Critical Chromium & Media Rules:
1. **Enable GPU Rasterization (`--enable-gpu-rasterization`)**: Forces Skia tile rasterization onto the GPU rather than CPU worker threads, eliminating DOM text-input latency.
2. **VA-API Hardware Video Decoding (`--enable-features=AcceleratedVideoDecodeLinuxGL,VaapiOnNvidiaGPUs`)**: Unblocklists NVIDIA GPUs for VA-API in Chromium, routing 8K AV1/VP9 decoding to NVIDIA Ampere NVDEC silicon via `libva-nvidia-driver`.
3. **ANGLE OpenGL Backend (`--use-gl=angle --use-angle=gl`)**: Required for Chromium's single-buffer DMA-BUF importer on NVIDIA to bind decoded VRAM textures directly into EGL without falling back or failing pre-sandbox initialization.
4. **P-Core CPU Affinity (`taskset -c 0-7`)**: On Intel 12th/13th/14th Gen hybrid CPUs (P-cores + E-cores), browser main threads and React DOM reconciliation must be pinned to P-cores to prevent severe typing and scrolling lag caused by E-core throttling.
5. **Avoid Standalone `--enable-zero-copy`**: In modern Chromium on Wayland, forcing `--enable-zero-copy` without full swapchain coordination can destabilize DOM input event pacing; the ANGLE + VA-API pipeline already provides true hardware zero-copy presentation for video.
6. **NEVER Add `TouchpadOverscrollHistoryNavigation`**: Causes a synchronous hit-testing barrier on the main thread, introducing mouse wheel and touchpad scrolling hitching.
