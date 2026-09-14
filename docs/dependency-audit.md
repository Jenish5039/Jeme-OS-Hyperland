# Jeme OS — Desktop Dependency Audit & Architecture Report

This document presents a comprehensive, component-level audit of all packages, services, and libraries required to run **Jeme OS** as a **self-contained, standalone Hyprland desktop environment** on Fedora Linux.

---

## 1. Executive Summary & GNOME Independence

### Architecture Target
```
┌─────────────────────────────────────────────────────────────┐
│                       Jeme OS Desktop                       │
├──────────────────────────────┬──────────────────────────────┤
│ Desktop Shell (Quickshell)   │ Dynamic Theming (Matugen)    │
│ Tiling Compositor (Hyprland) │ Wallpaper Engine (Awww/Live) │
│ Status Bar (QS / Waybar)     │ Notifications (SwayNC)       │
│ File Manager (Nautilus+GVFS) │ Terminal Emulator (Kitty)    │
├──────────────────────────────┴──────────────────────────────┤
│             Core Desktop Infrastructure & Daemons            │
│   • PipeWire / WirePlumber (Audio & Media)                  │
│   • NetworkManager & Blueman (Connectivity)                 │
│   • GNOME Keyring Daemon (Secret Service PAM provider)      │
│   • Hyprpolkitagent (Polkit Authentication)                 │
│   • XDG Desktop Portals (Hyprland + GTK backends)           │
│   • Udisks2 & GVFS (Disks, Trash, MTP, SMB)                 │
└─────────────────────────────────────────────────────────────┘
```

### The "GNOME Independence" Reality
* **GNOME Desktop / Session is OPTIONAL**: Jeme OS does **not** depend on `gnome-shell`, `gnome-session`, `mutter`, `gnome-control-center`, `gdm`, or UWSM.
* **Standalone Client Utilities**: Certain components contain "gnome" in their package name (`nautilus`, `gnome-keyring`, `gnome-text-editor`, `gnome-calculator`, `gsettings-desktop-schemas`, `xdg-desktop-portal-gtk`). These are **independent FreeDesktop/GTK applications and libraries** that communicate purely over standard Wayland, D-Bus, and PAM interfaces. They run natively under Hyprland without GNOME Shell installed.
* **Preservation of Existing Systems**: If installed alongside GNOME, KDE, or another desktop environment, Jeme OS does not remove or conflict with existing sessions. It registers `/usr/share/wayland-sessions/hyprland.desktop` cleanly.

---

## 2. Dependency Taxonomy & Classification

Dependencies are classified into six explicit tiers:

1. **Required**: Essential for compositor, shell, theming, file management, audio, networking, and session controls. Installed automatically.
2. **Optional**: Non-critical productivity, gaming, and alternative utilities. Installed on-demand.
3. **Hardware-Specific**: GPU acceleration, laptop backlight, and DDC monitor controls. Detected dynamically.
4. **Existing-System-Provided**: Base system daemons (`systemd`, `dbus-broker`, `glibc`, Linux kernel).
5. **Development-Only**: Toolchains needed only when building components from source (`cargo`, `go`, `gcc`).
6. **Machine-Specific**: Host hardware configs (`monitors.lua`, `environment.lua`) generated per-machine.

---

## 3. Comprehensive Dependency Audit Matrix

| Package | Purpose & Usage in Jeme OS | Component / Consumer | Tier | Installer Handling |
| :--- | :--- | :--- | :--- | :--- |
| **`hyprland`** | Core dynamic tiling Wayland compositor | Window Manager | Required | DNF / COPR (`lionheartp/Hyprland`) |
| **`hypridle`** | Idle detection, DPMS screen sleep, backlight dimming | Session Lifecycle | Required | DNF / COPR |
| **`hyprlock`** | Screen locker invoked by power menu & idle | Security / Lockscreen | Required | DNF / COPR |
| **`hyprsunset`** | Blue-light / gamma temperature adjustment | Display Management | Required | DNF / COPR |
| **`hyprpolkitagent`** | Graphical privilege escalation agent | System Authentication | Required | DNF / COPR (Systemd User Unit) |
| **`quickshell`** | QtQuick desktop shell, sidebar, volume, power, dock | Core User Interface | Required | COPR (`lionheartp/Hyprland`) / Local |
| **`matugen`** | Material 3 palette generator from wallpaper colors | Dynamic Theming Engine | Required | Cargo / Copr / `setup-matugen.sh` |
| **`awww`** | High-performance animated/static wallpaper daemon | Background Rendering | Required | COPR (`lionheartp/Hyprland`) |
| **`nautilus`** | Primary graphical file manager (`SUPER + E`) | File Management | Required | DNF (`nautilus`) |
| **`gvfs`** | Virtual filesystem backend (Trash `trash:///`, mounts) | Nautilus / Desktop IO | Required | DNF (`gvfs`, `gvfs-fuse`) |
| **`gvfs-archive`** | Transparent archive mounting as folders | Nautilus / Compression | Required | DNF (`gvfs-archive`) |
| **`gvfs-mtp`** | Android phone & MTP device integration | Mobile Storage | Required | DNF (`gvfs-mtp`) |
| **`gvfs-smb`** | Windows / Samba network shares mounting | Network Storage | Required | DNF (`gvfs-smb`) |
| **`udisks2`** | Automatic disk detection and USB mounting | Storage Subsystem | Required | DNF (`udisks2`) |
| **`file-roller`** | Graphical archive extraction & creation GUI | Compression | Optional | DNF (`file-roller`) |
| **`7zip` / `tar` / `unzip`** | Command-line compression & extraction utilities | Archive Handling | Required | DNF (`7zip`, `tar`, `unzip`, `zip`) |
| **`pipewire`** | Core real-time multimedia graph server | Audio Architecture | Required | DNF (User Systemd Service) |
| **`pipewire-pulse`** | PulseAudio compatibility replacement | App Audio / Mixers | Required | DNF (`pipewire-pulse`) |
| **`wireplumber`** | PipeWire session & policy manager | Audio Routing | Required | DNF (User Systemd Service) |
| **`pavucontrol`** | Detailed audio device mixer GUI | Audio Settings | Required | DNF (`pavucontrol`) |
| **`playerctl`** | MPRIS media player controls (Play/Pause/Next/Prev) | Keybindings & Widgets | Required | DNF (`playerctl`) |
| **`NetworkManager`** | Network connectivity daemon | Network Stack | Required | Systemd Service (`NetworkManager`) |
| **`network-manager-applet`** | Network indicator tray & connection editor | Quickshell / Statusbar | Required | DNF (`network-manager-applet`) |
| **`bluez` / `blueman`** | Bluetooth stack and tray manager applet | Bluetooth Subsystem | Required | DNF (`bluez`, `blueman`) |
| **`gnome-keyring`** | Secret Service API provider (PAM-unlocked) | Secret & Token Storage | Required | DNF (`gnome-keyring`, `-pam`) |
| **`xdg-desktop-portal`** | Desktop integration portal broker | Sandbox & Flatpaks | Required | DNF (`xdg-desktop-portal`) |
| **`xdg-desktop-portal-hyprland`** | Hyprland screen sharing & window capture portal | Screencasting | Required | DNF (`xdg-desktop-portal-hyprland`) |
| **`xdg-desktop-portal-gtk`** | GTK file chooser & settings portal backend | File Dialogs | Required | DNF (`xdg-desktop-portal-gtk`) |
| **`xdg-utils`** | FreeDesktop CLI utilities (`xdg-open`, `xdg-mime`) | MIME Associations | Required | DNF (`xdg-utils`) |
| **`xdg-user-dirs`** | Standard folder provisioning (`Downloads`, `Pictures`) | Directory Structure | Required | DNF (`xdg-user-dirs-update`) |
| **`gsettings-desktop-schemas`** | Standard GLib desktop preference schemas | GTK Theme Sync | Required | DNF (`gsettings-desktop-schemas`) |
| **`cliphist` / `wl-clipboard`** | Wayland clipboard history and copy/paste utilities | Clipboard Subsystem | Required | DNF (`cliphist`, `wl-clipboard`) |
| **`grim` / `slurp`** | Wayland screenshot capture and area selection | Screenshots | Required | DNF (`grim`, `slurp`, `grimblast`) |
| **`swappy`** | Screenshot annotation tool | Screenshots | Required | DNF (`swappy`) |
| **`SwayNotificationCenter`** | Modern notification center and control center | Notifications | Required | COPR (`erikreider/...`) |
| **`brightnessctl`** | Backlight control for laptop displays and keyboards | Hardware Controls | Required / Hardware | DNF (`brightnessctl`) |
| **`rofi`** | Application launcher and menu selector | App Launcher | Required | DNF (`rofi`) |
| **`kitty`** | GPU-accelerated terminal emulator | Default Terminal | Required | DNF (`kitty`) |
| **`waybar`** | Standalone status bar alternative | Optional Statusbar | Required | DNF (`waybar`) |
| **`wlogout`** | Wayland session logout menu | Power Menu | Optional | DNF (`wlogout`) |
| **`gtk3` / `gtk4` / `adw-gtk3-theme`** | GTK application runtimes and unified themes | UI Consistency | Required | DNF |
| **`qt6ct` / `qt6-qtwayland`** | Qt6 Wayland platform integration and styling | Qt Application UI | Required | DNF |
| **`fira-code-fonts`** | Base monospace font | Typography | Required | DNF / `install-fonts.sh` |
| **FiraCode Nerd Font** | Glyphs and developer symbols for shell and bars | UI Icons & CLI | Required | `install-fonts.sh` / COPR |
| **`Bibata-Modern-Ice`** | Consistent Wayland/X11 cursor theme | Cursor Styling | Required | `install-themes.sh` |
| **`kora` / `Papirus`** | Modern SVG application icon theme | Desktop Icons | Required | `install-themes.sh` / DNF |
| **`gnome-text-editor`** | Minimalist modern GTK4 text editor | Default Editor | Required | DNF (`gnome-text-editor`) |
| **`gnome-calculator`** | Simple desktop calculator (`SUPER + C`) | Utilities | Required | DNF (`gnome-calculator`) |
| **`loupe`** | High-performance image viewer | Default Image Viewer | Required | DNF (`loupe`) |
| **`papers`** | Minimal PDF and document viewer | Document Viewer | Required | DNF (`papers` / `evince`) |
| **`sddm`** | Display manager with ML4W theme | Login Manager | Optional | `scripts/install-sddm.sh` |
| **`nwg-displays`** | Multi-monitor arrangement GUI | Display Config | Optional | COPR (`tofik/nwg-shell`) |
| **`easyeffects`** | PipeWire audio effects & microphone noise reduction | Audio Enhancement | Optional | DNF / Flatpak |
| **`akmod-nvidia`** | Proprietary NVIDIA GPU kernel modules | GPU Acceleration | Hardware (NVIDIA) | RPM Fusion Non-Free |
| **`mesa-va-drivers`** | Hardware video acceleration for AMD GPUs | Video Decoding | Hardware (AMD) | DNF (`mesa-va-drivers`) |
| **`intel-media-driver`** | Hardware video acceleration for Intel GPUs | Video Decoding | Hardware (Intel) | DNF (`intel-media-driver`) |
| **`ddcutil`** | External monitor brightness control over I2C | Desktop Displays | Hardware (Desktop) | DNF (`ddcutil`) |

---

## 4. Fresh Machine Bootstrap Flow

On a bare Fedora Minimal or Workstation installation, running `./install.sh` executes the following sequence:

```
[1. Verify Fedora Environment]
       ↓
[2. Enable Coprs] ───> lionheartp/Hyprland, SwayNC, nerd-fonts, tofik/nwg-shell
       ↓
[3. Install Required RPMs] ───> Hyprland, Quickshell, Nautilus, GVFS, PipeWire, Bluez, etc.
       ↓
[4. Hardware Probing] ───> Probes GPU (NVIDIA/AMD/Intel), Monitors, and Chassis (Laptop/Desktop)
       ↓
[5. Initialize State] ───> xdg-user-dirs, registers /usr/share/wayland-sessions/hyprland.desktop
       ↓
[6. Fonts & Themes] ───> Downloads FiraCode Nerd Font, Bibata Cursor, Kora Icons, GTK/Qt config
       ↓
[7. Dynamic Theming] ───> Provisions default.jpg wallpaper, executes Matugen palette compilation
       ↓
[8. Health Diagnostics] ───> Runs scripts/doctor.sh (0 errors verification)
```

---

## 5. Security, Secrets & Session Portability

1. **Secret Service Daemon**:
   - `gnome-keyring-daemon` is unlocked automatically at login via PAM (`gnome-keyring-pam`) and started in `conf/autostart.lua`.
   - Web browsers (Brave, Chrome, Firefox), Git, and IDEs find the standard FreeDesktop `org.freedesktop.secrets` D-Bus interface without requiring GNOME Shell.

2. **Privilege Escalation**:
   - `hyprpolkitagent` handles graphical authentication popups for `sudo` / `polkit` requests natively in Wayland.

3. **Display Server Registration**:
   - `/usr/share/wayland-sessions/hyprland.desktop` is registered so any display manager (GDM, SDDM, greetd, LightDM) or direct TTY launch functions reliably out of the box.
