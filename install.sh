#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "[!] This script must be run as root."
    exit 1
fi

log()  { echo "[*] $1"; }
ok()   { echo "[+] $1"; }
err()  { echo "[!] $1"; }
warn() { echo "[~] $1"; }

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

install_pip() {
    PKG=$1
    BIN=${2:-$1}
    if command -v "$BIN" >/dev/null 2>&1; then
        ok "$PKG (pip) already installed, skipping."
        return
    fi
    log "Installing $PKG via pip..."
    if pip3 install "$PKG" --quiet --break-system-packages 2>/dev/null \
        || pip3 install "$PKG" --quiet 2>/dev/null; then
        ok "$PKG installed via pip."
    else
        err "Failed to install $PKG via pip."
    fi
}

install_nuclei() {
    if command -v nuclei >/dev/null 2>&1; then
        ok "nuclei already installed, skipping."
        return
    fi
    log "Installing nuclei..."
    install_pkg unzip
    # Resolve latest release URL via GitHub API
    NUCLEI_URL=$(curl -sL "https://api.github.com/repos/projectdiscovery/nuclei/releases/latest" \
        | grep "browser_download_url" | grep "linux_amd64.zip" | head -1 \
        | cut -d'"' -f4)
    if [ -z "$NUCLEI_URL" ]; then
        err "Could not resolve nuclei download URL."
        return
    fi
    TMPZIP=$(mktemp /tmp/nuclei-XXXX.zip)
    curl -sL "$NUCLEI_URL" -o "$TMPZIP" 2>/dev/null
    if unzip -o "$TMPZIP" nuclei -d /usr/local/bin >/dev/null 2>&1; then
        chmod +x /usr/local/bin/nuclei
        ok "nuclei installed."
    else
        err "Failed to extract nuclei."
    fi
    rm -f "$TMPZIP"
}

install_script() {
    NAME=$1
    URL=$2
    if command -v "$NAME" >/dev/null 2>&1; then
        ok "$NAME already installed, skipping."
        return
    fi
    log "Installing $NAME..."
    TMPSCRIPT=$(mktemp /tmp/install-XXXX.sh)
    curl -sL "$URL" -o "$TMPSCRIPT" 2>/dev/null
    if sh "$TMPSCRIPT" -b /usr/local/bin >/dev/null 2>&1; then
        ok "$NAME installed."
    else
        err "Failed to install $NAME."
    fi
    rm -f "$TMPSCRIPT"
}

install_zeek() {
    if command -v zeek >/dev/null 2>&1; then
        ok "zeek already installed, skipping."
        return
    fi
    log "Installing zeek..."
    # Add Zeek official repo
    if ! grep -r "download.opensuse.org/repositories/security:/zeek" /etc/apt/ >/dev/null 2>&1; then
        DISTRO=$(. /etc/os-release && echo "$ID")
        CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
        install_pkg curl
        install_pkg gnupg
        curl -sL "https://download.opensuse.org/repositories/security:/zeek/xUbuntu_22.04/Release.key" \
            | gpg --dearmor -o /etc/apt/trusted.gpg.d/zeek.gpg 2>/dev/null
        echo "deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_22.04/ /" \
            > /etc/apt/sources.list.d/zeek.list
        apt-get update -qq
    fi
    if apt-get install -y zeek >/dev/null 2>&1; then
        ok "zeek installed."
    else
        err "Failed to install zeek."
    fi
}

install_ossec() {
    if command -v ossec-control >/dev/null 2>&1 || [ -d /var/ossec ]; then
        ok "ossec already installed, skipping."
        return
    fi
    log "Installing OSSEC..."
    install_pkg wget
    install_pkg gnupg
    wget -qO- "https://updates.atomicorp.com/installers/atomic" | sh >/dev/null 2>&1
    apt-get update -qq
    if apt-get install -y ossec-hids-server >/dev/null 2>&1; then
        ok "ossec installed."
    else
        err "Failed to install ossec. Try manually: https://www.ossec.net/downloads/"
    fi
}

install_debcheckroot() {
    if command -v debcheckroot >/dev/null 2>&1; then
        ok "debcheckroot already installed, skipping."
        return
    fi
    log "Installing debcheckroot via pip..."
    if pip3 install debcheckroot --quiet --break-system-packages 2>/dev/null \
        || pip3 install debcheckroot --quiet 2>/dev/null; then
        ok "debcheckroot installed via pip."
    else
        warn "debcheckroot not available via pip or apt. Skipping."
    fi
}

#######################################################################

log "Updating package lists..."
apt-get update -qq

# Rootkit & integrity
install_pkg rkhunter
install_pkg chkrootkit
install_pkg debsums
install_debcheckroot
install_pkg unhide

# File integrity monitoring
install_pkg tripwire
install_pkg aide

# Firewall & intrusion prevention
install_pkg ufw
install_pkg fail2ban

# USB control
install_pkg usbguard

# Mandatory access control
install_pkg apparmor
install_pkg apparmor-utils
install_pkg apparmor-profiles
install_pkg apparmor-profiles-extra
install_pkg selinux-basics
install_pkg selinux-policy-default

# System auditing & maintenance
install_pkg lynis
install_pkg auditd
install_pkg needrestart
install_pkg logwatch

# Antivirus
install_pkg clamav
log "Updating ClamAV virus definitions..."
if command -v freshclam >/dev/null 2>&1; then
    freshclam 2>/dev/null; ok "ClamAV definitions updated."
else
    err "freshclam not found."
fi

# Web scanning
install_pkg nikto

# Vulnerability scanning
install_pkg gvm

# Network IDS/IPS
install_pkg snort
install_pkg suricata
install_zeek

# Host-based IDS
install_ossec

# Network & process inspection
install_pkg nmap
install_pkg lsof

# Memory forensics (pip)
install_pkg python3-pip pip3
install_pip volatility3 vol

# Process / tracing tools
install_pkg strace
install_pkg ltrace
install_pkg pslist

# Reverse engineering
install_pkg radare2

# Nuclei (zip release)
install_nuclei

# Grype & Trivy (install scripts)
install_script grype "https://raw.githubusercontent.com/anchore/grype/main/install.sh"
install_script trivy "https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh"

# Nmap vulners NSE script
log "Ensuring vulners NSE script is available..."
if [ -f /usr/share/nmap/scripts/vulners.nse ]; then
    ok "vulners NSE script already present."
else
    curl -s "https://raw.githubusercontent.com/vulnersCom/nmap-vulners/master/vulners.nse" \
        -o /usr/share/nmap/scripts/vulners.nse 2>/dev/null \
        && nmap --script-updatedb >/dev/null 2>&1 \
        && ok "vulners NSE script installed." \
        || err "Could not install vulners NSE script."
fi

log "All done."
