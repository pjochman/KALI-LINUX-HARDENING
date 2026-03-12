#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "[!] This script must be run as root."
    exit 1
fi

log()  { echo "[*] $1"; }
ok()   { echo "[+] $1"; }
err()  { echo "[!] $1"; }

install_pkg() {
    PKG=$1
    BIN=${2:-$1}
    if command -v "$BIN" >/dev/null 2>&1; then
        ok "$PKG already installed, skipping."
        return
    fi
    log "Installing $PKG..."
    if apt-get install -y "$PKG" >/dev/null 2>&1; then
        ok "$PKG installed."
    else
        err "Failed to install $PKG."
    fi
}

log "Updating package lists..."
apt-get update -qq

# Rootkit / integrity
install_pkg rkhunter
install_pkg chkrootkit
install_pkg debsums
install_pkg unhide

# System auditing
install_pkg lynis

# Antivirus
install_pkg clamav

log "Updating ClamAV virus definitions..."
if command -v freshclam >/dev/null 2>&1; then
    freshclam
    ok "ClamAV definitions updated."
else
    err "freshclam not found, skipping definition update."
fi

# Web scanning
install_pkg nikto

# Vulnerability scanning
install_pkg gvm

# Process / tracing tools
install_pkg strace
install_pkg ltrace
install_pkg pslist
install_pkg unhide

# Reverse engineering
install_pkg radare2

# Nmap with vulners NSE script
install_pkg nmap
log "Ensuring vulners NSE script is available..."
if [ -f /usr/share/nmap/scripts/vulners.nse ]; then
    ok "vulners NSE script already present."
else
    curl -s https://raw.githubusercontent.com/vulnersCom/nmap-vulners/master/vulners.nse \
        -o /usr/share/nmap/scripts/vulners.nse 2>/dev/null \
        && nmap --script-updatedb >/dev/null 2>&1 \
        && ok "vulners NSE script installed." \
        || err "Could not install vulners NSE script."
fi

log "All done."
