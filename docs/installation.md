# Jeme OS — Installation Guide (Fedora)

Step-by-step guide to installing and reproducing **Jeme OS** on a fresh Fedora installation or an existing system.

---

## 1. Prerequisites

* **Operating System**: Fedora Linux (Fedora Minimal, Everything, Server, or Workstation)
* **Architecture**: x86_64
* **User Privileges**: Sudo / wheel group access
* **GNOME Requirement**: **NONE**. Jeme OS provides a completely self-contained desktop environment. GNOME is optional.

---

## 2. Installation Workflow

```
Fresh Fedora (Minimal / Workstation / Server)
    ↓
Clone Jeme OS Rice repository
    ↓
Run ./install.sh
    ↓
1. Enables Copr repositories (Hyprland, Quickshell, SwayNC, Nerd Fonts)
2. Installs required desktop RPM packages (Nautilus, GVFS, PipeWire, Bluez, Portals)
3. Detects hardware (GPU, multi-monitors, laptop vs desktop)
4. Deploys configuration & provisions default wallpaper
5. Installs fonts (FiraCode Nerd Font) and cursor/icon themes
6. Initializes Material 3 color palettes via Matugen
7. Registers Wayland session (/usr/share/wayland-sessions/hyprland.desktop)
    ↓
Log in to Hyprland via GDM, SDDM, greetd, or TTY
    ↓
Usable, Self-Contained Jeme OS Desktop
```

---

## 3. Quick Installation

Clone the repository and run the master installer:

```bash
git clone https://github.com/your-username/jeme-rice.git ~/jeme-rice
cd ~/jeme-rice
./install.sh
```

For non-interactive automated provisioning, pass the `-y` flag:
```bash
./install.sh -y
```

---

## 4. What the Installer Does

1. **System & Distribution Verification**: Confirms Fedora compatibility and current user identity.
2. **Package & Repository Installation**:
   * Enables required Copr repositories (`lionheartp/Hyprland`, `erikreider/SwayNotificationCenter`, `che/nerd-fonts`, `tofik/nwg-shell`).
   * Installs Hyprland, Quickshell, Nautilus, GVFS storage backends, Waybar, Matugen, SwayNC, Rofi, Kitty, PipeWire, and all system tools from [`packages/fedora-required.txt`](file:///home/zane/Jeme%20OS%20Rice/packages/fedora-required.txt).
3. **Configuration Deployment**:
   * Creates timestamped backups of existing configurations in `~/.config/jeme-backups/`.
   * Safely deploys portable configuration modules to `~/.config/`.
   * Preserves user wallpaper state and favorites if updating an existing system.
4. **Hardware & Display Probing (`machine/detect.sh`)**:
   * Probes active GPU (NVIDIA / AMD / Intel) and generates driver environment profiles.
   * Auto-detects connected monitors, resolutions, and refresh rates into `~/.config/hypr/monitors.lua`.
   * Identifies laptop vs desktop form factor and configures backlight/battery policies.
5. **State & Session Integration**:
   * Initializes standard user directories via `xdg-user-dirs-update`.
   * Registers `/usr/share/wayland-sessions/hyprland.desktop` for display managers.
   * Enables user services for PipeWire, WirePlumber, and Hyprpolkitagent.
6. **Fonts & Theming Setup**:
   * Installs FiraCode Nerd Font, Cantarell, FontAwesome.
   * Configures Bibata-Modern-Ice cursor and Kora/Papirus icon themes.
7. **Matugen Theme Initialization**:
   * Generates initial Material 3 color palettes across all 19 template targets from `default.jpg`.
8. **Display Manager Handling**:
   * If an active display manager (GDM, LightDM, greetd) is present, it is preserved.
   * If no display manager is active, optionally configures SDDM with the ML4W theme.
9. **System Health Verification**:
   * Executes [`scripts/doctor.sh`](file:///home/zane/Jeme%20OS%20Rice/scripts/doctor.sh) to confirm all components are operational (0 errors).

---

## 5. Starting the Session

1. **Via Display Manager (GDM / SDDM / greetd)**:
   * Select **Hyprland** in the session selector and log in.
2. **Via TTY**:
   * Log into your user account and run:
     ```bash
     Hyprland
     ```

---

## 6. Managing the System

Use the unified `jeme` CLI utility:

```bash
jeme doctor      # Run full system diagnostics
jeme update      # Safely pull and apply updates
jeme theme       # Switch or refresh Material 3 palettes
jeme wallpaper   # Change wallpaper and rebuild themes
jeme backup      # Create a full snapshot of your configs
jeme restore     # Restore from a previous backup
```
