# Jeme OS Rice 🌌

> **A self-contained, portable, reproducible Hyprland + Quickshell + Matugen desktop rice for Fedora Linux.**

---

## 🌟 Highlights

* **Self-Contained & GNOME-Independent**: Jeme OS provides a complete desktop environment with its own shell, compositor, audio, networking, storage, and authentication daemons. **GNOME is NOT required.**
* **Hyprland Native Lua API**: Fast, declarative, modular compositor configuration without rigid monolithic `.conf` files.
* **Quickshell Desktop Suite**: High-performance QtQuick/QML widgets including Statusbar, Sidebar, Wi-Fi & Bluetooth Popups, Audio Mixer, Power Overlay, Wallpaper Browser, and Multi-workspace Overview.
* **Dynamic Material 3 Theming (Matugen)**: Live extraction of Material 3 color palettes from wallpapers synchronized across **19 template targets** (Quickshell, Waybar, SwayNC, GTK 3/4, Qt6ct, Kitty, Rofi, Btop, and OhMyPosh).
* **Nautilus & Complete Storage Integration**: Seamless file management with GVFS (trash `trash:///`, Samba, MTP phone mounts), Udisks2 disk mounting, and multi-format archive utilities (`7zip`, `tar`, `unzip`).
* **Multi-GPU & Hardware Portable**: Strict separation between portable desktop logic and machine-specific monitor/GPU profiles (`machine/detect.sh`).
* **Automated & Idempotent**: Complete `jeme` CLI utility for installation, safe non-destructive updates, backups, hardware detection, and health diagnostics.

---

## 📸 Desktop Stack Overview

| Component | Technology | Configuration / Implementation |
|---|---|---|
| **Compositor** | Hyprland (Native Lua API) | `~/.config/hypr/` |
| **Desktop Shell & Widgets** | Quickshell (QtQuick/QML) | `~/.config/quickshell/` |
| **Theming Engine** | Matugen (Material 3) | `~/.config/matugen/` |
| **Status Bar** | Quickshell Statusbar / Waybar | `~/.config/quickshell/StatusbarApp/` |
| **File Manager** | Nautilus + GVFS + Udisks2 | `~/.config/ml4w/settings/filemanager` |
| **Notifications** | SwayNC | `~/.config/swaync/` |
| **App Launcher** | Rofi (Wayland) | `~/.config/rofi/` |
| **Terminal** | Kitty | `~/.config/kitty/` |
| **Audio Server** | PipeWire + WirePlumber | `~/.config/pipewire/` |
| **Secret Service** | GNOME Keyring Daemon (PAM) | `~/.config/hypr/conf/autostart.lua` |
| **Idle & Lock** | Hypridle & Hyprlock | `~/.config/hypr/hypridle.conf` & `hyprlock.conf` |

---

## 🚀 Installation (Fresh Fedora Bootstrap)

```
Fresh Fedora (Minimal, Server, or Workstation)
    ↓
Clone Jeme OS Rice repository
    ↓
Run ./install.sh
    ↓
Automated Dependency & Hardware Setup
    ↓
Log into Jeme / Hyprland
```

### Quickstart:
```bash
git clone https://github.com/Jenish5039/Jeme-OS-Hyperland.git ~/jeme-os
cd ~/jeme-os
./install.sh
```

### Installation Lifecycle:
1. **Verification**: Verifies Fedora OS and user permissions.
2. **Package Installation**: Enables required Copr repositories (`lionheartp/Hyprland`, `SwayNC`, `nerd-fonts`, `nwg-shell`) and installs all desktop essentials.
3. **Hardware Probing**: Automatically detects connected monitors, GPU (NVIDIA, AMD, Intel), and form factor (Laptop vs Desktop).
4. **Configuration & Defaults**: Deploys modular configs to `~/.config/` and initializes default wallpaper and Material 3 palettes.
5. **Session Registration**: Registers `/usr/share/wayland-sessions/hyprland.desktop` for GDM, SDDM, greetd, or TTY login.
6. **Diagnostics**: Runs `scripts/doctor.sh` to ensure a 0-error healthy installation.

> Detailed package and dependency analysis is documented in [`docs/dependency-audit.md`](file:///home/zane/Jeme%20OS%20Rice/docs/dependency-audit.md).

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
| `SUPER + T` | Launch Kitty Terminal |
| `ALT + SPACE` | Open Application Launcher |
| `SUPER + E` | Open Nautilus File Manager |
| `SUPER + B` | Open Web Browser |
| `SUPER + C` | Open Calculator |
| `SUPER + Q` | Close Focused Window |
| `SUPER + F` | Toggle Fullscreen |
| `SUPER + Z` | Toggle Floating Window |
| `SUPER + W` | Toggle Jeme Wallpaper Engine |
| `SUPER + CTRL + W` | Open Wallpaper Selector |
| `SUPER + CTRL + S` | Toggle Quickshell Control Sidebar Drawer |
| `SUPER + CTRL + P` | Open Power / Lock / Exit Menu |
| `SUPER + Tab` | Open Window Switcher Overview |
| `SUPER + V` | Open Clipboard History (Cliphist) |
| `PRINT` | Take Interactive Screenshot (`screenshot.sh`) |
| `SUPER + ALT + F` | Take Instant Fullscreen Screenshot |
| `SUPER + SHIFT + S`| Take Instant Area Screenshot |
| `SUPER + ALT + A` | Extract Text from Screen (OCR) |

---

## 📂 Repository Structure

```
Jeme OS Rice/
├── install.sh                     # Master automated installer (non-interactive support: -y)
├── uninstall.sh                   # Clean uninstaller and restore tool
├── update.sh                      # Safe, non-destructive updater
├── backup.sh                      # Timestamped configuration snapshot tool
├── restore.sh                     # Interactive configuration restore tool
├── README.md                      # Project overview and quickstart
├── LICENSE                        # MIT License
│
├── bin/                           # Bundled user binaries (jeme, qs, quickshell, grimblast)
├── packages/                      # Tiered dependency lists (required, optional, hardware, coprs)
│   ├── copr-repos.txt             # Required COPR repositories
│   ├── fedora-required.txt        # Required desktop essentials
│   ├── fedora-optional.txt        # Optional companion utilities
│   ├── fedora-hardware.txt        # Hardware-specific packages (NVIDIA/AMD/Intel/Laptops)
│   └── fedora-devel.txt           # Build and development dependencies
│
├── config/                        # Modular desktop configuration modules
├── wallpapers/                    # Bundled default wallpapers
├── sddm/                          # Optional SDDM ML4W theme
├── machine/                       # Hardware detection engine and templates
├── scripts/                       # Modular installer scripts & doctor diagnostics
├── docs/                          # In-depth technical documentation & audit reports
│   ├── dependency-audit.md        # Comprehensive 6-tier dependency matrix & audit
│   ├── installation.md            # Detailed installation and session guide
│   ├── architecture.md            # Desktop stack architectural layout
│   └── customization.md           # Theming, statusbar, and wallpaper engine customization
│
└── skills/                        # AI Agent Engineering Skill (skills/jeme-os/SKILL.md)
```

---

## 📜 License

Distributed under the **MIT License**. See [`LICENSE`](file:///home/zane/Jeme%20OS%20Rice/LICENSE) for more information.
