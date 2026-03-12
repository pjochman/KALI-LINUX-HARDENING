#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "[!] This script must be run as root."
    exit 1
fi

log()  { echo "[*] $1"; }
ok()   { echo "[+] $1"; }
err()  { echo "[!] $1"; }

install_pkg() {
    TOOL=$1
    if command -v "$TOOL" >/dev/null 2>&1; then
        ok "$TOOL already installed, skipping."
        return
    fi
    log "Installing $TOOL..."
    if apt-get install -y "$TOOL" >/dev/null 2>&1; then
        ok "$TOOL installed."
    else
        err "Failed to install $TOOL."
    fi
}

log "Updating package lists..."
apt-get update -qq

install_pkg rkhunter
install_pkg chkrootkit
install_pkg lynis

log "All done."
