#!/usr/bin/env bash
# ==============================================================================
# Jeme OS Rice — Quick Bootstrap Script
# https://github.com/Jenish5039/Jeme-OS-Hyperland
# ==============================================================================
set -euo pipefail

REPO_URL="https://github.com/Jenish5039/Jeme-OS-Hyperland.git"
TARGET_DIR="${HOME}/jeme-os"

# Colors
CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_CYAN="\033[1;36m"
CLR_GREEN="\033[1;32m"
CLR_YELLOW="\033[1;33m"
CLR_RED="\033[1;31m"

echo -e "\n${CLR_CYAN}${CLR_BOLD}=== Jeme OS — Desktop Bootstrap ===${CLR_RESET}\n"

# 1. Verify Operating System (Fedora)
if [[ -f /etc/os-release ]]; then
    if ! grep -iqE 'ID=fedora|ID_LIKE=.*fedora' /etc/os-release; then
        echo -e "${CLR_YELLOW}[WARN]${CLR_RESET} Non-Fedora distribution detected. Jeme OS is tailored for Fedora Linux."
    fi
else
    echo -e "${CLR_RED}[ERROR]${CLR_RESET} Cannot determine operating system (/etc/os-release missing)."
    exit 1
fi

# 2. Verify / Install Minimal Prerequisites (git)
if ! command -v git >/dev/null 2>&1; then
    echo -e "${CLR_CYAN}[INFO]${CLR_RESET} Git is required to download Jeme OS. Installing git..."
    if command -v sudo >/dev/null 2>&1; then
        sudo dnf install -y git || {
            echo -e "${CLR_RED}[ERROR]${CLR_RESET} Failed to install git automatically. Please run 'sudo dnf install git' and retry."
            exit 1
        }
    else
        echo -e "${CLR_RED}[ERROR]${CLR_RESET} Sudo or git not found. Please install git and retry."
        exit 1
    fi
fi

# 3. Clone or Update Jeme OS Repository
if [[ -d "${TARGET_DIR}/.git" ]]; then
    echo -e "${CLR_CYAN}[INFO]${CLR_RESET} Existing Jeme OS repository found at ${TARGET_DIR}. Updating..."
    git -C "$TARGET_DIR" pull --ff-only 2>/dev/null || echo -e "${CLR_YELLOW}[WARN]${CLR_RESET} Could not fast-forward existing repository. Continuing with current files."
else
    echo -e "${CLR_CYAN}[INFO]${CLR_RESET} Cloning Jeme OS repository into ${TARGET_DIR}..."
    rm -rf "$TARGET_DIR" 2>/dev/null || true
    git clone "$REPO_URL" "$TARGET_DIR"
fi

# 4. Verify Installer Exists and is Executable
if [[ ! -f "${TARGET_DIR}/install.sh" ]]; then
    echo -e "${CLR_RED}[ERROR]${CLR_RESET} install.sh not found in cloned repository at ${TARGET_DIR}."
    exit 1
fi

chmod +x "${TARGET_DIR}/install.sh"

# 5. Hand over execution to the main installer
echo -e "${CLR_GREEN}[✓]${CLR_RESET} Jeme OS repository obtained successfully. Launching installer...\n"

if [[ -t 0 ]]; then
    exec "${TARGET_DIR}/install.sh" "$@"
elif [[ -c /dev/tty ]]; then
    exec "${TARGET_DIR}/install.sh" "$@" < /dev/tty
else
    exec "${TARGET_DIR}/install.sh" "$@"
fi
