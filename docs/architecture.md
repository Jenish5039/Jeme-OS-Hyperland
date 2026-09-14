# Jeme OS — System Architecture & Design

Jeme OS is a production-grade, highly customizable **Fedora + Hyprland + Quickshell + Matugen** desktop environment designed for performance, aesthetic consistency, and hardware portability.

---

## 1. High-Level Architecture Diagram

```
                                  [ Linux Kernel / DRM / KMS ]
                                               │
                                  [ Display Manager (SDDM) ]
                                               │
                                 [ Hyprland (Native Lua API) ]
                                               │
               ┌───────────────────────────────┼───────────────────────────────┐
               ▼                               ▼                               ▼
      [ Quickshell Desktop ]          [ Theming Pipeline ]            [ System Daemons ]
     • StatusbarApp                  • Matugen Material 3            • PipeWire / WirePlumber
     • SidebarApp                    • Awww (Wallpapers)             • SwayNC (Notifications)
     • ConnectivityApp (WiFi/BT)     • 19 Template Targets           • Hypridle & Hyprlock
     • AudioApp & PowerApp           • GTK 3/4 & Qt6ct Styles        • Cliphist (Clipboard)
     • DockApp & Overview            • Live IPC Reload               • Hyprpolkitagent
```

---

## 2. Core Architectural Layers

### Layer 1: Display Server & Compositor (Hyprland Native Lua API)
* **Configuration Entry Point**: `~/.config/hypr/hyprland.lua`
* **Modular Lua Sub-configs**:
  * `conf/autostart.lua`: Starts secret services, exports Wayland/D-Bus environments, launches daemons.
  * `conf/environment.lua`: Dynamically detects and loads GPU driver profiles (`nvidia.lua`, `amd.lua`, `intel.lua`).
  * `conf/keybinding.lua`: Loads keybind variants.
  * `conf/decoration.lua`: Manages window rounding, blur, and opacity presets.
  * `conf/animation.lua`: Smooth cubic-bezier animation presets.
  * `conf/windowrule.lua`: Window placement, floating dialogs, and opacity rules.
  * `monitors.lua`: Hardware-specific monitor resolution, refresh rate, position, and VRR settings.

---

### Layer 2: Desktop Shell & Widgets (Quickshell QML)
Quickshell serves as the primary desktop widget and HUD engine:
* **Root Shell**: `~/.config/quickshell/shell.qml`
* **Applications**:
  * `StatusbarApp`: Native QtQuick status bar with modular indicators (workspaces, battery, clock, tray, updates, volume).
  * `SidebarApp`: Slide-in desktop control panel (`SUPER+CTRL+S`) with quick toggles, brightness, volume, and MPRIS media player.
  * `ConnectivityApp`: Wi-Fi network manager and Bluetooth device manager popup.
  * `AudioApp`: Per-app and master audio mixer popup.
  * `PowerApp`: Lock, suspend, restart, and shutdown overlay (`SUPER+CTRL+P`).
  * `WallpaperApp`: Graphical wallpaper browser and selector (`SUPER+CTRL+W`).
  * `WallpaperEngineApp`: Animated wallpaper manager.
  * `overview`: Multi-workspace window switcher and overview (`SUPER+Tab`).
  * `DockApp`: Minimalist floating application dock.

---

### Layer 3: Authoritative Theming Pipeline (Matugen Material 3)

Matugen dynamically extracts Material 3 color palettes from the active wallpaper and synchronizes them across **19 template targets**:

```
                             [ Active Wallpaper Image ]
                                         │
                                         ▼
                            Matugen (~/.config/matugen/)
                                         │
    ┌───────────────────────────┬────────┴───────────────────────────┬───────────────────────────┐
    ▼                           ▼                                    ▼                           ▼
[ JSON Palettes ]      [ Wayland & Bars ]                  [ Toolkit Styles ]            [ Terminal & App Styles ]
• colors.json (Desktop) • waybar/colors.css                 • gtk-3.0/colors.css          • kitty/colors-matugen.conf
• colors.json (Settings)• swaync/colors.css                 • gtk-4.0/colors.css          • rofi/colors.rasi
• colors.json (OhMyPosh)• hypr/colors.lua & colors.conf     • qt6ct/ml4w-tray.qss         • btop/themes/matugen.theme
                        • quickshell Appearance.colors.qml
                                         │
                                         ▼
                             [ Live IPC Notification ]
                        qs ipc call theme-manager reload
```

#### Theming Principles:
1. **Single Authoritative Source**: Matugen is the sole color generation engine. Never hardcode active palettes.
2. **Instant Hot-Reload**: Styles reload live without restarting the compositor or desktop sessions.
3. **Fail-Safe Fallbacks**: Components contain baseline fallback variables for graceful initialization before initial color generation.
