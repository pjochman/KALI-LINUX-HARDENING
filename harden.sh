#!/bin/sh
#
# Applies system hardening: sysctl kernel parameters, AppArmor, and SELinux.
# Safe to run multiple times (idempotent).

if [ "$(id -u)" -ne 0 ]; then
    echo "[!] This script must be run as root."
    exit 1
fi

log()  { echo "[*] $1"; }
ok()   { echo "[+] $1"; }
warn() { echo "[~] $1"; }
err()  { echo "[!] $1"; }

#######################################################################
# Sysctl hardening
#######################################################################

SYSCTL_CONF="/etc/sysctl.d/99-hardening.conf"

log "Writing sysctl hardening rules to $SYSCTL_CONF..."

cat > "$SYSCTL_CONF" << 'EOF'
# ---------------------------------------------------------------
# Network hardening
# ---------------------------------------------------------------

# Disable IP forwarding (not a router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Do not send redirects
net.ipv4.conf.all.send_redirects = 0

# Enable reverse path filter (anti-spoofing)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore broadcast ICMP (Smurf attack protection)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Enable SYN cookies (SYN flood protection)
net.ipv4.tcp_syncookies = 1

# Log martian packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# ---------------------------------------------------------------
# Kernel hardening
# ---------------------------------------------------------------

# Restrict dmesg to root
kernel.dmesg_restrict = 1

# Restrict ptrace to root
kernel.yama.ptrace_scope = 2

# Restrict kernel pointers in /proc
kernel.kptr_restrict = 2

# Disable magic SysRq key
kernel.sysrq = 0

# Restrict unprivileged access to kernel logs
kernel.perf_event_paranoid = 3

# Randomise virtual address space (ASLR)
kernel.randomize_va_space = 2

# Restrict unprivileged BPF
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2

# ---------------------------------------------------------------
# Filesystem hardening
# ---------------------------------------------------------------

# Prevent hard links to files not owned by the user
fs.protected_hardlinks = 1

# Prevent symlink following in world-writable sticky dirs
fs.protected_symlinks = 1

# Restrict FIFO creation in world-writable sticky dirs
fs.protected_fifos = 2

# Restrict regular file creation in world-writable sticky dirs
fs.protected_regular = 2

# Restrict core dumps
fs.suid_dumpable = 0
EOF

sysctl -p "$SYSCTL_CONF" >/dev/null 2>&1 && ok "sysctl hardening applied." || err "Failed to apply some sysctl settings."

#######################################################################
# AppArmor
#######################################################################

log "Configuring AppArmor..."
if command -v aa-enforce >/dev/null 2>&1; then
    if ! aa-status --enabled >/dev/null 2>&1; then
        warn "AppArmor is not enabled in the kernel. Enable it by adding 'apparmor=1 security=apparmor' to GRUB_CMDLINE_LINUX in /etc/default/grub and running update-grub."
    else
        aa-enforce /etc/apparmor.d/* >/dev/null 2>&1
        ok "AppArmor profiles set to enforce mode."
    fi
else
    warn "AppArmor tools not found. Run ./install.sh first."
fi

#######################################################################
# SELinux
#######################################################################

log "Configuring SELinux..."
if command -v selinux-activate >/dev/null 2>&1; then
    if sestatus 2>/dev/null | grep -q "enabled"; then
        warn "SELinux is already active."
    else
        warn "SELinux requires a reboot to activate. Run 'selinux-activate' to enable, then reboot."
        warn "Note: AppArmor and SELinux are mutually exclusive — use one or the other."
    fi
else
    warn "SELinux tools not found. Run ./install.sh first."
fi

log "Hardening complete."
