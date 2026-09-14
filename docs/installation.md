# Jeme OS — Installation Guide (Fedora)

Step-by-step guide to installing and reproducing Jeme OS on a fresh Fedora installation.

---

## 1. Prerequisites

* **Operating System**: Fedora Linux (Fedora 40, 41, 42, 43, 44+ / Rawhide)
* **Architecture**: x86_64
* **User Privileges**: Sudo / wheel group access

---

## 2. Quick Installation (One Command)

Clone the repository and run the master installer:

```bash
git clone https://github.com/your-username/jeme-rice.git ~/jeme-rice
cd ~/jeme-rice
./install.sh
```

---

## 3. What the Installer Does

1. **System & Distribution Verification**: Confirms Fedora compatibility and current user identity.
2. **Package & Repository Installation**:
   * Enables required Copr repositories (`erikreider/SwayNotificationCenter`, `tofik/nwg-shell`, `che/nerd-fonts`).
   * Installs Hyprland, Quickshell, Waybar, Matugen, SwayNC, Rofi, Kitty, PipeWire, and all system tools.
3. **Configuration Deployment**:
   * Creates timestamped backups of any existing `~/.config/` configurations in `~/.config/jeme-backups/`.
   * Deploys clean, portable Jeme OS configuration files to `~/.config/`.
4. **Hardware & Display Probing (`machine/detect.sh`)**:
   * Auto-detects connected monitors and generates `~/.config/hypr/monitors.lua`.
   * Probes active GPU (NVIDIA / AMD / Intel) and configures driver environment variables.
5. **Fonts & Theming Setup**:
   * Installs FiraCode Nerd Font, Cantarell, FontAwesome.
   * Configures Bibata-Modern-Ice cursor and Kora icon theme.
6. **Matugen Theme Initialization**:
   * Generates initial Material 3 color palettes across all 19 template targets from default wallpaper.
7. **Optional SDDM Theme Setup**:
   * Installs ML4W SDDM theme to `/usr/share/sddm/themes/ml4w` and enables `sddm.service`.
8. **System Health Verification**:
   * Executes `scripts/doctor.sh` to confirm all components are operational.

---

## 4. Post-Installation & Starting the Session

1. Reboot your machine:
   ```bash
   sudo reboot
   ```
2. At the SDDM login screen, select **Hyprland** and enter your password.
3. Once logged in, Jeme OS will start with Quickshell, wallpaper daemon, and dynamic theming ready.
