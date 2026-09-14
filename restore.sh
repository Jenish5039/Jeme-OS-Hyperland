#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Restore Utility
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib/common.sh"

header "Jeme OS Configuration Restore"

BACKUP_ROOT="${HOME}/.config/jeme-backups"

if [[ ! -d "$BACKUP_ROOT" ]]; then
    error "No backups found in ${BACKUP_ROOT}"
    exit 1
fi

BACKUP_PATH="${1:-}"

if [[ -z "$BACKUP_PATH" ]]; then
    echo -e "Available backups in ${BACKUP_ROOT}:\n"
    BACKUPS=()
    while IFS= read -r b; do
        [[ -n "$b" ]] && BACKUPS+=("$b")
    done < <(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -name "jeme-backup-*" | sort -r)

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        error "No valid backup directories found in ${BACKUP_ROOT}"
        exit 1
    fi

    for i in "${!BACKUPS[@]}"; do
        echo -e "  [${CLR_BOLD}${i}${CLR_RESET}] $(basename "${BACKUPS[$i]}")"
    done

    echo
    read -rp "Select backup index to restore [0-$(( ${#BACKUPS[@]} - 1 ))]: " idx
    if [[ ! "$idx" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= ${#BACKUPS[@]} )); then
        error "Invalid selection."
        exit 1
    fi
    BACKUP_PATH="${BACKUPS[$idx]}"
fi

if [[ ! -d "$BACKUP_PATH" ]]; then
    error "Specified backup path does not exist: ${BACKUP_PATH}"
    exit 1
fi

warn "Restoring configurations from: ${BACKUP_PATH}"
read -rp "Are you sure you want to overwrite current configurations? [y/N]: " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || exit 0

for item in "${BACKUP_PATH}"/*; do
    name=$(basename "$item")
    if [[ "$name" == "shell" ]]; then
        for sf in "${item}"/.*; do
            sf_name=$(basename "$sf")
            [[ "$sf_name" == "." || "$sf_name" == ".." ]] && continue
            info "Restoring shell file: ~/${sf_name}"
            cp -p "$sf" "${HOME}/${sf_name}"
        done
    elif [[ -d "$item" ]]; then
        info "Restoring configuration: ~/.config/${name}"
        rm -rf "${HOME}/.config/${name}"
        cp -a "$item" "${HOME}/.config/${name}"
    fi
done

success "Configurations restored successfully from ${BACKUP_PATH}!"
