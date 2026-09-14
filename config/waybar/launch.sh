#!/usr/bin/env bash
#                    __
#  _    _____ ___ __/ /  ___ _____
# | |/|/ / _ `/ // / _ \/ _ `/ __/
# |__,__/\_,_/\_, /_.__/\_,_/_/
#            /___/
#

# -----------------------------------------------------
# Prevent duplicate launches: wait up to 5 seconds to
# serialize parallel invocations safely.
# -----------------------------------------------------

lock_file="${XDG_RUNTIME_DIR:-/tmp}/waybar-launch.lock"
exec 200>"$lock_file"
flock -w 5 200 || exit 0

# Clean any inherited Quickshell LD_PRELOAD
unset LD_PRELOAD

# -----------------------------------------------------
# Robust process discovery and termination
# -----------------------------------------------------

_get_waybar_pids() {
    local pids=()
    local self_pid=$$

    # 1. Inspect /proc for processes executing waybar binary
    for p in /proc/[0-9]*; do
        [ -d "$p" ] || continue
        local pid="${p##*/}"
        [ "$pid" -eq "$self_pid" ] && continue
        local exe
        exe=$(readlink -f "$p/exe" 2>/dev/null)
        if [[ "$exe" == */waybar ]]; then
            pids+=("$pid")
        fi
    done

    # 2. Match pgrep cmdline as well
    while IFS= read -r pid; do
        [[ -n "$pid" && "$pid" -ne "$self_pid" ]] || continue
        if [[ ! " ${pids[*]} " =~ " ${pid} " ]]; then
            pids+=("$pid")
        fi
    done < <(pgrep -f '(^|/)waybar([[:space:]]|$)' 2>/dev/null || true)

    echo "${pids[@]}"
}

_stop_waybar() {
    local pids
    pids=($(_get_waybar_pids))
    if [ ${#pids[@]} -eq 0 ]; then
        return 0
    fi

    # Step 1: Graceful SIGTERM
    for pid in "${pids[@]}"; do
        kill -15 "$pid" 2>/dev/null || true
    done

    # Step 2: Poll for exit (up to 2.0s)
    local waited=0
    while [ $waited -lt 20 ]; do
        local remaining=()
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                remaining+=("$pid")
            fi
        done
        if [ ${#remaining[@]} -eq 0 ]; then
            break
        fi
        sleep 0.1
        ((waited++))
    done

    # Step 3: Hard SIGKILL if still alive
    local lingering
    lingering=($(_get_waybar_pids))
    if [ ${#lingering[@]} -gt 0 ]; then
        for pid in "${lingering[@]}"; do
            kill -9 "$pid" 2>/dev/null || true
        done
        sleep 0.1
    fi
}

# -----------------------------------------------------
# Check if waybar-disabled file exists or statusbar is quickshell
# -----------------------------------------------------

if [ -f "$HOME/.config/ml4w/settings/waybar-disabled" ]; then
    _stop_waybar
    echo ":: Waybar disabled"
    flock -u 200
    exec 200>&-
    exit 0
fi

# -----------------------------------------------------
# Stop existing instances before starting fresh
# -----------------------------------------------------

_stop_waybar

# -----------------------------------------------------
# Default theme: /THEMEFOLDER;/VARIATION
# -----------------------------------------------------

default_theme="/ml4w-glass-center;/ml4w-glass-center/default"

# -----------------------------------------------------
# Remove incompatible themes
# -----------------------------------------------------

if [ -f "$HOME/.config/ml4w/settings/waybar-theme.sh" ]; then
    themestyle=$(cat "$HOME/.config/ml4w/settings/waybar-theme.sh")
    case "$themestyle" in
    "/ml4w-modern;/ml4w-modern/light")
        echo "$default_theme" >"$HOME/.config/ml4w/settings/waybar-theme.sh"
        ;;
    "/ml4w-modern;/ml4w-modern/dark")
        echo "$default_theme" >"$HOME/.config/ml4w/settings/waybar-theme.sh"
        ;;
    "/ml4w;/ml4w/light")
        echo "$default_theme" >"$HOME/.config/ml4w/settings/waybar-theme.sh"
        ;;
    "/ml4w;/ml4w/dark")
        echo "$default_theme" >"$HOME/.config/ml4w/settings/waybar-theme.sh"
        ;;
    *)
        ;;
    esac
    [ -d "$HOME/.config/waybar/themes/ml4w-modern/light" ] && rm -rf "$HOME/.config/waybar/themes/ml4w-modern/light"
    [ -d "$HOME/.config/waybar/themes/ml4w-modern/dark" ] && rm -rf "$HOME/.config/waybar/themes/ml4w-modern/dark"
    [ -d "$HOME/.config/waybar/themes/ml4w/light" ] && rm -rf "$HOME/.config/waybar/themes/ml4w/light"
    [ -d "$HOME/.config/waybar/themes/ml4w/dark" ] && rm -rf "$HOME/.config/waybar/themes/ml4w/dark"
fi

# -----------------------------------------------------
# Get current theme information from ~/.config/ml4w/settings/waybar-theme.sh
# -----------------------------------------------------

if [ -f "$HOME/.config/ml4w/settings/waybar-theme.sh" ]; then
    themestyle=$(cat "$HOME/.config/ml4w/settings/waybar-theme.sh")
else
    mkdir -p "$HOME/.config/ml4w/settings"
    touch "$HOME/.config/ml4w/settings/waybar-theme.sh"
    echo "$default_theme" >"$HOME/.config/ml4w/settings/waybar-theme.sh"
    themestyle=$default_theme
fi

IFS=';' read -ra arrThemes <<<"$themestyle"
echo ":: Theme: ${arrThemes[0]}"

if [ ! -f "$HOME/.config/waybar/themes${arrThemes[1]}/style.css" ]; then
    themestyle=$default_theme
    IFS=';' read -ra arrThemes <<<"$themestyle"
fi

# -----------------------------------------------------
# Toggle Waybar modules
# -----------------------------------------------------

_toggle_module() {
    local module_name=$1
    local settings_file=$2
    [ -f "$settings_file" ] || return 0
    local value
    value=$(cat "$settings_file")
    local file="$HOME/.config/waybar/themes${arrThemes[0]}/config"
    [ -f "$file" ] || return 0
    if [ "$value" == "True" ]; then
        search_string=" \"$module_name\""
        if ! grep -qF "$search_string" "$file"; then
            sed -i "s| //\"$module_name\"| \"$module_name\"|g" "$file"
        fi
    else
        search_string=" //\"$module_name\""
        if ! grep -qF "$search_string" "$file"; then
            sed -i "s| \"$module_name\"| //\"$module_name\"|g" "$file"
        fi
    fi
}

_toggle_module "custom/appmenu" "$HOME/.config/ml4w/settings/waybar_appmenu.sh"
_toggle_module "wlr/taskbar" "$HOME/.config/ml4w/settings/waybar_taskbar.sh"
_toggle_module "group/quicklinks" "$HOME/.config/ml4w/settings/waybar_quicklinks.sh"
_toggle_module "hyprland/window" "$HOME/.config/ml4w/settings/waybar_window.sh"
_toggle_module "network" "$HOME/.config/ml4w/settings/waybar_network.sh"
_toggle_module "tray" "$HOME/.config/ml4w/settings/waybar_systray.sh"

# -----------------------------------------------------
# Loading the configuration
# -----------------------------------------------------

config_file="config"
style_file="style.css"

# Standard files can be overwritten with an existing config-custom or style-custom.css
if [ -f "$HOME/.config/waybar/themes${arrThemes[0]}/config-custom" ]; then
    config_file="config-custom"
fi
if [ -f "$HOME/.config/waybar/themes${arrThemes[1]}/style-custom.css" ]; then
    style_file="style-custom.css"
fi

HYPRLAND_SIGNATURE=$(hyprctl instances -j 2>/dev/null | jq -r '.[0].instance' 2>/dev/null || true)
if [ -z "$HYPRLAND_SIGNATURE" ] || [ "$HYPRLAND_SIGNATURE" = "null" ]; then
    HYPRLAND_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-}"
fi

setsid env -u LD_PRELOAD HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_SIGNATURE" waybar \
    -c "$HOME/.config/waybar/themes${arrThemes[0]}/$config_file" \
    -s "$HOME/.config/waybar/themes${arrThemes[1]}/$style_file" >/dev/null 2>&1 &
WAYBAR_PID=$!

# Verify startup
waited=0
while [ $waited -lt 15 ]; do
    if kill -0 "$WAYBAR_PID" 2>/dev/null; then
        echo ":: Waybar started successfully (PID $WAYBAR_PID)"
        break
    fi
    sleep 0.1
    ((waited++))
done

flock -u 200
exec 200>&-
