hl.on("hyprland.start", function ()
    local HOME = os.getenv("HOME")
    -- IBus disabled to prevent virtual-keyboard input drops on layer surfaces
    -- hl.exec_cmd("/usr/libexec/ibus-ui-gtk3 --enable-wayland-im --exec-daemon --daemon-args \"--xim --panel disable\"")

    -- Read wallpaper app setting
    local wallpaper_app = "quickshell"
    local f = io.open(HOME .. "/.config/ml4w/settings/wallpaper-app", "r")
    if f then
        wallpaper_app = f:read("*l"):match("^%s*(.-)%s*$")
        f:close()
    end

    -- Initialize GNOME Keyring daemon (connects to PAM-unlocked daemon and claims D-Bus Secret Service)
    hl.exec_cmd("/usr/bin/gnome-keyring-daemon --start --components=secrets")

    -- Synchronously export variables to systemd and D-Bus before restarting portals
    hl.exec_cmd("bash -c \"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GNOME_KEYRING_CONTROL SSH_AUTH_SOCK DISPLAY XDG_SESSION_TYPE XDG_SESSION_DESKTOP && systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GNOME_KEYRING_CONTROL SSH_AUTH_SOCK DISPLAY XDG_SESSION_TYPE XDG_SESSION_DESKTOP && systemctl --user reset-failed xdg-desktop-portal-hyprland xdg-desktop-portal 2>/dev/null || true && systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal\"")

    -- Start Sunshine streaming daemon (guarded if service exists)
    hl.exec_cmd("bash -c 'systemctl --user is-enabled sunshine.service >/dev/null 2>&1 && systemctl --user start sunshine.service 2>/dev/null || true'")

    -- Start Easy Effects in background service mode (guarded if flatpak exists)
    hl.exec_cmd("bash -c 'flatpak info com.github.wwmm.easyeffects >/dev/null 2>&1 && flatpak run com.github.wwmm.easyeffects --hide-window --service-mode >/dev/null 2>&1 || true'")

    -- Wallpaper daemon (managed authoritatively by ml4w-autostart based on persisted mode)
    -- hl.exec_cmd("awww-daemon")

    -- Load cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")

    -- Start listeners
    hl.exec_cmd("~/.config/ml4w/listeners.sh --startall")

    -- Waybar disabled: using native Quickshell statusbar
    -- hl.exec_cmd(HOME .. "/.config/waybar/launch.sh")

    -- Start Hyprland Polkit authentication agent
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service 2>/dev/null || /usr/libexec/hyprpolkitagent &")

    -- Restore wallpaper (skip for quickshell — handled inside ml4w-autostart)
    if wallpaper_app ~= "quickshell" then
        hl.exec_cmd("~/.config/ml4w/scripts/ml4w-wallpaper-app --restore")
    end

    -- Autostart scripts (standard ~/.cache/ml4w/ logging directory)
    hl.exec_cmd("bash -c 'mkdir -p ~/.cache/ml4w && ~/.config/ml4w/scripts/ml4w-autostart > ~/.cache/ml4w/ml4w-autostart.log 2>&1'")

    -- Load GTK settings
    hl.exec_cmd("~/.config/hypr/scripts/gtk.sh")

    -- SwayNC is started by systemd

    -- Start hypridle
    hl.exec_cmd("hypridle")

    -- Load cliphist history
    hl.exec_cmd("wl-paste --watch cliphist store")

    -- Start autostart cleanup
    hl.exec_cmd("~/.config/hypr/scripts/cleanup.sh")
end)
