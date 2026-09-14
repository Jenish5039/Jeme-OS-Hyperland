# Jeme OS — Component Inventory

Complete directory of all software components, configuration locations, and roles comprising Jeme OS.

---

## 1. Core Desktop Components

| Component | Package / Technology | Configuration Path | Purpose |
|---|---|---|---|
| **Compositor** | Hyprland (Lua Native) | `~/.config/hypr/` | Dynamic tiling Wayland compositor |
| **Desktop Shell** | Quickshell (QtQuick/QML) | `~/.config/quickshell/` | Main desktop statusbar, sidebar, popups, and dock |
| **Settings App** | Quickshell (QML) | `~/.local/share/ml4w-dotfiles-settings/` | Graphical dotfiles preference management GUI |
| **Theme Engine** | Matugen (Material 3) | `~/.config/matugen/` | Automated wallpaper-based palette generator |
| **Status Bar** | Waybar (Optional) | `~/.config/waybar/` | Alternative C++/GTK3 status bar |
| **Notifications** | SwayNC | `~/.config/swaync/` | Wayland notification daemon and control center |
| **App Launcher** | Rofi (Wayland) | `~/.config/rofi/` | Application runner, clipboard viewer, and script selector |
| **Terminal** | Kitty | `~/.config/kitty/` | GPU-accelerated terminal emulator |
| **Display Manager** | SDDM | `/etc/sddm.conf` & `sddm/themes/ml4w/` | Login greeter and user session manager |
| **Idle Management** | Hypridle | `~/.config/hypr/hypridle.conf` | Screen dimming, locking, and DPMS sleep manager |
| **Screen Locker** | Hyprlock | `~/.config/hypr/hyprlock.conf` | Fast, GPU-rendered Wayland screen lock |
| **Night Light** | Hyprsunset | `~/.config/hypr/hyprsunset.conf` | Color temperature adjustment |
| **Wallpaper Daemon**| Awww | `~/.config/ml4w/wallpapers/` | Smooth animated Wayland wallpaper renderer |
| **Clipboard** | Cliphist + wl-clipboard | `~/.config/rofi/config-cliphist.rasi` | Clipboard history daemon and search picker |
| **Audio Stack** | PipeWire + WirePlumber | `~/.config/pipewire/` | Low-latency audio server and session router |
| **GTK Theming** | Adwaita / adw-gtk3 | `~/.config/gtk-3.0/` & `gtk-4.0/` | GTK application styling and colors |
| **Qt Theming** | Qt6ct & Custom QSS | `~/.config/qt6ct/` | Qt6 application theme and tray menu styles |
| **Resource Monitor**| Btop | `~/.config/btop/` | Terminal system monitor with Matugen theme |
| **System Info** | Fastfetch | `~/.config/fastfetch/` | Modern system information display tool |

---

## 2. Key Automation & Utility Scripts

All core automation scripts reside in `~/.config/ml4w/scripts/` and `~/.config/hypr/scripts/`:

* `ml4w-wallpaper <path>`: Sets active wallpaper via awww and regenerates Matugen Material 3 color palettes.
* `ml4w-autostart`: Master autostart supervisor initializing daemons, pre-generating colors, and launching Quickshell.
* `ml4w-toggle-theme`: Toggles light and dark mode across all 19 template targets.
* `ml4w-sidebar`: Toggles the Quickshell sidebar control drawer (`SUPER+CTRL+S`).
* `ml4w-quicksettings`: Opens quick settings popup.
* `ml4w-power`: Triggers the power / shutdown menu (`SUPER+CTRL+P`).
* `gtk.sh`: Synchronizes GTK 3/4 settings and font configurations.
* `cleanup.sh`: Cleans up orphaned background processes upon session startup.
* `nvi <app>`: Launches applications using dedicated NVIDIA PRIME offloading and hardware acceleration flags.
* `jeme <command>`: Master CLI tool for installing, updating, backing up, and diagnosing Jeme OS.
