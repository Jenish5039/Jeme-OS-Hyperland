# Jeme OS Rice 🌌

> **A portable, reproducible, production-grade Hyprland + Quickshell + Matugen desktop rice for Fedora Linux.**

---

## 🌟 Highlights

* **Hyprland Native Lua API**: Fast, declarative, modular compositor configuration without rigid monolithic `.conf` files.
* **Quickshell Desktop Suite**: High-performance QtQuick/QML widgets including Statusbar, Sidebar, Wi-Fi & Bluetooth Popup, Audio Mixer, Power Overlay, Wallpaper Browser, and Multi-workspace Overview.
* **Dynamic Material 3 Theming (Matugen)**: Live extraction of Material 3 color palettes from wallpapers synchronized across **19 template targets** (Quickshell, Waybar, SwayNC, GTK 3/4, Qt6ct, Kitty, Rofi, Btop, and OhMyPosh).
* **Multi-GPU & Hardware Portable**: Strict separation between portable desktop logic and machine-specific monitor/GPU profiles (`machine/detect.sh`).
* **Automated & Idempotent**: Complete `jeme` CLI utility for installation, safe non-destructive updates, backups, hardware detection, and health diagnostics.

---

## 📸 Desktop Stack Overview

| Component | Technology | Configuration Path |
|---|---|---|
| **Compositor** | Hyprland (Native Lua API) | `~/.config/hypr/` |
| **Desktop Shell & Widgets** | Quickshell (QtQuick/QML) | `~/.config/quickshell/` |
| **Theming Engine** | Matugen (Material 3) | `~/.config/matugen/` |
| **Status Bar** | Quickshell Statusbar / Waybar | `~/.config/quickshell/StatusbarApp/` |
| **Notifications** | SwayNC | `~/.config/swaync/` |
| **App Launcher** | Rofi (Wayland) | `~/.config/rofi/` |
| **Terminal** | Kitty | `~/.config/kitty/` |
| **Display Manager** | SDDM (ML4W Theme) | `/etc/sddm.conf` & `/usr/share/sddm/themes/ml4w/` |
| **Audio Server** | PipeWire + WirePlumber | `~/.config/pipewire/` |
| **Idle & Lock** | Hypridle & Hyprlock | `~/.config/hypr/hypridle.conf` & `hyprlock.conf` |

---

## 🚀 Quickstart Installation (Fedora)

To install Jeme OS on a fresh Fedora installation:

```bash
git clone https://github.com/your-username/jeme-rice.git ~/jeme-rice
cd ~/jeme-rice
./install.sh
```

### What the installer does:
1. Detects Fedora and current user environment.
2. Enables necessary Copr repositories (`SwayNotificationCenter`, `nwg-shell`, `nerd-fonts`).
3. Installs required RPM packages and dependencies.
4. Backs up any existing configuration to `~/.config/jeme-backups/`.
5. Deploys clean Jeme OS configurations and helper binaries.
6. Probes connected monitors and GPU to generate tailored machine settings.
7. Installs FiraCode Nerd Font, Bibata-Modern-Ice cursor, and Kora icon theme.
8. Initializes Matugen dynamic color palettes from the default wallpaper.
9. Configures the SDDM login manager with the ML4W theme.

---

## 🛠️ The `jeme` CLI Tool

Jeme OS includes a dedicated CLI management utility:

```bash
jeme <command> [args]
```

| Command | Description |
|---|---|
| `jeme install` | Run the full Jeme OS rice installer |
| `jeme update` | Pull repository updates, back up, and safely update configs preserving machine settings |
| `jeme backup` | Create a timestamped backup directory and `.tar.gz` archive in `~/.config/jeme-backups/` |
| `jeme restore` | Interactively select and restore from a previous configuration backup |
| `jeme doctor` | Run comprehensive system diagnostics and health checks |
| `jeme detect` | Auto-detect monitors and active GPU, writing clean `monitors.lua` and `environment.lua` |
| `jeme theme <path>`| Set new wallpaper and trigger live Material 3 color generation across all apps |
| `jeme info` | Display active compositor, kernel, shell, and rice information |

---

## ⌨️ Keybindings Cheatsheet

| Keybinding | Action |
|---|---|
| `SUPER + RETURN` | Launch Kitty Terminal |
| `SUPER + SPACE` | Open Rofi Application Launcher |
| `SUPER + E` | Open File Manager |
| `SUPER + B` | Open Web Browser |
| `SUPER + Q` | Close Focused Window |
| `SUPER + F` | Toggle Fullscreen |
| `SUPER + T` | Toggle Floating Window |
| `SUPER + CTRL + S` | Toggle Quickshell Control Sidebar Drawer |
| `SUPER + CTRL + P` | Open Power / Lock / Exit Menu |
| `SUPER + CTRL + W` | Open Quickshell Wallpaper Browser |
| `SUPER + Tab` | Open Quickshell Window Overview |
| `SUPER + V` | Open Clipboard History (Cliphist) |
| `PRINT` | Take Region Screenshot (`screenshot.sh`) |
| `SHIFT + PRINT` | Take Fullscreen Screenshot |
| `SUPER + SHIFT + E` | Extract Text from Screen (OCR) |

---

## 📂 Repository Structure

```
Jeme OS Rice/
├── install.sh                     # Master automated installer
├── uninstall.sh                   # Uninstaller and cleanup tool
├── update.sh                      # Safe, non-destructive updater
├── backup.sh                      # Configuration backup tool
├── restore.sh                     # Configuration restore tool
├── README.md                      # Project documentation
├── LICENSE                        # MIT License
├── .gitignore                     # Git ignore rules
│
├── bin/                           # User binaries (jeme, qs, nvi, sddm-avatar)
├── packages/                      # Fedora package lists, Copr repos, Flatpaks
├── config/                        # Portable dotfiles (hypr, quickshell, ml4w, matugen, etc.)
├── wallpapers/                    # Default and curated wallpapers
├── sddm/                          # SDDM ML4W theme and sddm.conf template
├── machine/                       # Machine-specific detection, templates, and examples
├── scripts/                       # Modular installer scripts and diagnostics doctor
├── docs/                          # Comprehensive technical documentation
└── skills/                        # AI Agent Engineering Skill (skills/jeme-os/SKILL.md)
```

---

## 🎨 Customization & Theming

### Switching Colors & Wallpapers
* Press `SUPER + CTRL + W` to select a wallpaper visually.
* Or run:
  ```bash
  jeme theme ~/Pictures/wallpapers/sunset.jpg
  ```
* Toggle Light/Dark mode:
  ```bash
  ~/.config/ml4w/scripts/ml4w-toggle-theme
  ```

### Switching Window & Animation Presets
In `~/.config/hypr/conf/`:
* `animation.lua`: Switch between `animations-end4.lua`, `animations-smooth.lua`, `animations-moving.lua`, `standard.lua`.
* `window.lua`: Switch between `glass.lua`, `transparent.lua`, `no-border.lua`.
* `decoration.lua`: Switch between `rounding-all-blur.lua`, `rounding-more-blur.lua`, `rounding.lua`.

---

## 📜 License

Distributed under the **MIT License**. See [`LICENSE`](file:///home/zane/Jeme%20OS%20Rice/LICENSE) for more information.
