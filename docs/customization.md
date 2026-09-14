# Jeme OS — Customization Guide & Levers

This guide details the standard customization levers and configuration points in Jeme OS.

---

## 1. Dynamic Wallpaper & Theming

### Changing Wallpaper
Set any image as the active wallpaper to instantly re-theme the entire desktop:
```bash
jeme theme ~/Pictures/wallpapers/nature.jpg
```
or via GUI:
* Press `SUPER + CTRL + W` to open the Quickshell Wallpaper Selector.
* Or use the Settings App (`SUPER + CTRL + S` -> Settings).

### Dark / Light Mode Toggle
Toggle between Material 3 dark and light modes:
```bash
~/.config/ml4w/scripts/ml4w-toggle-theme
```

---

## 2. Animation & Window Styling Presets

Hyprland appearance is organized into hot-swappable variant presets in `~/.config/hypr/conf/`:

| Customization Lever | Configuration File | Available Variants in `conf/` |
|---|---|---|
| **Animations** | `conf/animation.lua` | `animations/animations-end4.lua`, `animations-smooth.lua`, `animations-moving.lua`, `standard.lua`, `disabled.lua` |
| **Window Borders & Glass** | `conf/window.lua` | `windows/glass.lua`, `transparent.lua`, `no-border.lua`, `gamemode.lua` |
| **Rounding & Blur** | `conf/decoration.lua` | `decorations/rounding-all-blur.lua`, `rounding-more-blur.lua`, `rounding.lua`, `no-rounding.lua` |
| **Keybindings** | `conf/keybinding.lua` | `keybindings/default.lua` |
| **Layout Mode** | `conf/layout.lua` | `layouts/laptop.lua`, `layouts/default.lua` |

To switch an animation or window preset, edit the `local name = "..."` line in the corresponding file, or use the Settings App.

---

## 3. Status Bar Selection (Quickshell vs Waybar)

### Default: Native Quickshell Statusbar
Quickshell provides a high-performance QtQuick status bar loaded from `~/.config/quickshell/StatusbarApp/`. It is styled live by `colors.json` and supports modules configured in `~/.config/quickshell/StatusbarApp/statusbar.json`.

### Alternative: Waybar
To switch to Waybar:
1. In `~/.config/hypr/conf/autostart.lua`, uncomment:
   ```lua
   hl.exec_cmd(HOME .. "/.config/waybar/launch.sh")
   ```
2. Disable the Quickshell bar module or reload Waybar:
   ```bash
   ~/.config/waybar/launch.sh
   ```
3. Switch Waybar themes using:
   ```bash
   ~/.config/waybar/themeswitcher.sh
   ```

---

## 4. Keybinding Customization

Default keybindings are defined in `~/.config/hypr/conf/keybindings/default.lua`:

| Shortcut | Action |
|---|---|
| `SUPER + RETURN` | Launch Kitty Terminal |
| `SUPER + SPACE` | Launch Rofi App Launcher |
| `SUPER + E` | Open File Manager |
| `SUPER + B` | Open Web Browser (Brave/Firefox) |
| `SUPER + Q` | Close Active Window (`killactive.sh`) |
| `SUPER + F` | Toggle Fullscreen |
| `SUPER + T` | Toggle Floating Mode |
| `SUPER + CTRL + S` | Toggle Quickshell Control Sidebar |
| `SUPER + CTRL + P` | Open Power / Lock / Exit Menu |
| `SUPER + CTRL + W` | Open Wallpaper Browser |
| `SUPER + Tab` | Open Quickshell Window Overview |
| `SUPER + V` | Open Cliphist Clipboard History |
| `PRINT` | Take Region Screenshot (`screenshot.sh`) |
| `SHIFT + PRINT` | Take Fullscreen Screenshot |
| `SUPER + SHIFT + E` | Extract Text from Screen (OCR) |
