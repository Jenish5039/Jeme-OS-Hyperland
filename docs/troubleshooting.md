# Jeme OS — Troubleshooting & Diagnostics

Comprehensive diagnostic procedures and solutions for common desktop issues.

---

## 1. Quick Diagnostics (`jeme doctor`)

Run the automated health checker at any time:
```bash
jeme doctor
```

This verifies:
* Compositor and widget binaries
* Portals (`xdg-desktop-portal`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`)
* User systemd units (`pipewire`, `wireplumber`, `swaync`, `hyprpolkitagent`)
* Critical configuration paths and active theme palettes

---

## 2. Common Issues & Solutions

### A. Quickshell Did Not Start or Crashed
* **Symptom**: No status bar, sidebar, or popup windows.
* **Fix**:
  1. Inspect logs:
     ```bash
     qs -d
     ```
  2. If running on Fedora with Qt symbol mismatch, ensure `libquickshell-qt-compat.so` is active in `~/.local/bin/qs`.
  3. Force restart Quickshell:
     ```bash
     killall qs 2>/dev/null || true
     qs -d &
     ```

---

### B. Screen Sharing or File Chooser Portals Not Working
* **Symptom**: Web browsers (Chrome, Firefox, Brave) or Discord cannot share screen or open file dialogues.
* **Fix**:
  1. Check portal configuration in `/usr/share/xdg-desktop-portal/hyprland-portals.conf`:
     ```ini
     [preferred]
     default=hyprland;gtk
     ```
  2. Ensure environment variables are imported into systemd:
     ```bash
     dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
     systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal
     ```

---

### C. Theme Colors Out of Sync After Wallpaper Change
* **Symptom**: Bar, terminal, or GTK apps did not update colors.
* **Fix**:
  1. Re-run Matugen manually:
     ```bash
     matugen image ~/.config/ml4w/wallpapers/default.jpg -c ~/.config/matugen/config.toml
     ```
  2. Reload Quickshell theme:
     ```bash
     qs ipc call theme-manager reload
     ```
  3. Reload Hyprland and Waybar:
     ```bash
     hyprctl reload
     pkill -SIGUSR2 waybar
     ```

---

### D. Audio Device or Microphone Not Responding
* **Symptom**: No audio output or microphone input.
* **Fix**:
  1. Restart the PipeWire user stack:
     ```bash
     systemctl --user restart pipewire pipewire-pulse wireplumber
     ```
  2. Open audio mixer:
     ```bash
     pavucontrol
     ```

---

### E. NVIDIA Wayland Stuttering or Screen Tearing
* **Symptom**: Frame drops or flicker on NVIDIA GPUs.
* **Fix**:
  1. Ensure `nvidia.lua` environment is loaded in `~/.config/hypr/conf/environment.lua`:
     ```lua
     local name = "nvidia.lua"
     load_variant(name, "environments")
     ```
  2. Verify kernel parameters in `/etc/default/grub`:
     `nvidia_drm.modeset=1 nvidia_drm.fbdev=1`
  3. Check VRR settings in `~/.config/hypr/conf/misc.lua` (`vrr = 2`).
