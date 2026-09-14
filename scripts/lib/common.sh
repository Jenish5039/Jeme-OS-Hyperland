#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Shared Shell Utility Library
# ==============================================================================

# ANSI Color Codes
CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_RED="\033[1;31m"
CLR_GREEN="\033[1;32m"
CLR_YELLOW="\033[1;33m"
CLR_BLUE="\033[1;34m"
CLR_MAGENTA="\033[1;35m"
CLR_CYAN="\033[1;36m"
CLR_GRAY="\033[0;90m"

# Logging Functions
info() {
    echo -e "${CLR_BLUE}[INFO]${CLR_RESET} $*"
}

success() {
    echo -e "${CLR_GREEN}[✓]${CLR_RESET} $*"
}

warn() {
    echo -e "${CLR_YELLOW}[WARN]${CLR_RESET} $*" >&2
}

error() {
    echo -e "${CLR_RED}[ERROR]${CLR_RESET} $*" >&2
}

header() {
    echo -e "\n${CLR_CYAN}${CLR_BOLD}=== $* ===${CLR_RESET}\n"
}

# Timestamp for backups
timestamp() {
    date +%Y%m%d-%H%M%S
}

# Safe File / Directory Backup
# Usage: backup_target "/path/to/file_or_dir" [backup_dir]
backup_target() {
    local target="$1"
    local bkp_dir="${2:-}"

    if [[ ! -e "$target" && ! -L "$target" ]]; then
        return 0
    fi

    local ts
    ts="$(timestamp)"

    if [[ -n "$bkp_dir" ]]; then
        mkdir -p "$bkp_dir"
        local base_name
        base_name="$(basename "$target")"
        local backup_path="${bkp_dir}/${base_name}.${ts}"
        info "Backing up ${target} -> ${backup_path}"
        cp -a "$target" "$backup_path"
    else
        local backup_path="${target}.backup-${ts}"
        info "Backing up ${target} -> ${backup_path}"
        cp -a "$target" "$backup_path"
    fi
}

# OS & Environment Probing
is_fedora() {
    if [[ -f /etc/os-release ]]; then
        grep -iq 'ID=fedora' /etc/os-release || grep -iq 'ID_LIKE=.*fedora' /etc/os-release
        return $?
    fi
    return 1
}

is_hyprland() {
    [[ "${XDG_CURRENT_DESKTOP:-}" =~ [Hh]yprland ]] || command -v Hyprland >/dev/null 2>&1
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Require Root/Sudo Check
require_sudo() {
    if [[ $EUID -ne 0 ]]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo -v || { error "Sudo authentication failed"; exit 1; }
        else
            error "Root privileges or sudo required to run this step."
            exit 1
        fi
    fi
}
