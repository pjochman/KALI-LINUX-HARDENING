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

install_binary() {
    NAME=$1
    URL=$2
    DEST=$3
    if command -v "$NAME" >/dev/null 2>&1; then
        ok "$NAME already installed, skipping."
        return
    fi
    log "Installing $NAME from $URL..."
    curl -sL "$URL" -o "$DEST" && chmod +x "$DEST" \
        && ok "$NAME installed to $DEST." \
        || err "Failed to install $NAME."
}

log "Updating package lists..."
apt-get update -qq

# Rootkit & integrity
install_pkg rkhunter
install_pkg chkrootkit
install_pkg debsums
install_pkg debcheckroot
install_pkg unhide

# File integrity monitoring
install_pkg tripwire

# System auditing & maintenance
install_pkg lynis
install_pkg needrestart
install_pkg logwatch

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

# Network IDS/IPS
install_pkg snort
install_pkg suricata
install_pkg zeek

# Host-based IDS
install_pkg ossec-hids-server ossec

# Network & process inspection
install_pkg nmap
install_pkg lsof

# Memory forensics
install_pkg volatility3

# Process / tracing tools
install_pkg strace
install_pkg ltrace
install_pkg pslist

# Reverse engineering
install_pkg radare2

# Container/filesystem vulnerability scanners (not in apt — install via releases)
ARCH=$(uname -m)
install_binary "nuclei" \
    "https://github.com/projectdiscovery/nuclei/releases/latest/download/nuclei_linux_amd64.zip" \
    "/tmp/nuclei.zip"
if [ ! -f /tmp/nuclei.zip.done ] && command -v unzip >/dev/null 2>&1; then
    unzip -o /tmp/nuclei.zip nuclei -d /usr/local/bin >/dev/null 2>&1 \
        && touch /tmp/nuclei.zip.done && ok "nuclei extracted." \
        || err "Failed to extract nuclei."
fi

install_binary "grype" \
    "https://raw.githubusercontent.com/anchore/grype/main/install.sh" \
    "/tmp/install-grype.sh"
if [ -f /tmp/install-grype.sh ] && ! command -v grype >/dev/null 2>&1; then
    sh /tmp/install-grype.sh -b /usr/local/bin >/dev/null 2>&1 \
        && ok "grype installed." || err "Failed to install grype."
fi

install_binary "trivy" \
    "https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh" \
    "/tmp/install-trivy.sh"
if [ -f /tmp/install-trivy.sh ] && ! command -v trivy >/dev/null 2>&1; then
    sh /tmp/install-trivy.sh -b /usr/local/bin >/dev/null 2>&1 \
        && ok "trivy installed." || err "Failed to install trivy."
fi

# Nmap vulners NSE script
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
