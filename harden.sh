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

#######################################################################
# Password policy
#######################################################################

log "Applying password policy..."

# Install required packages
for PKG in libpam-pwquality passwd; do
    dpkg -s "$PKG" >/dev/null 2>&1 || apt-get install -y "$PKG" >/dev/null 2>&1
done

# /etc/login.defs — password ageing
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/'  /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/'   /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/'  /etc/login.defs

# SHA-512 password hashing
sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/' /etc/login.defs

# /etc/security/pwquality.conf — password complexity
PWQUALITY_CONF="/etc/security/pwquality.conf"
cat > "$PWQUALITY_CONF" << 'EOF'
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
maxrepeat = 3
maxsequence = 3
gecoscheck = 1
dictcheck = 1
EOF

# PAM: enforce pwquality and account lockout
PAM_PASSWD="/etc/pam.d/common-password"
if [ -f "$PAM_PASSWD" ] && ! grep -q "pam_pwquality" "$PAM_PASSWD"; then
    sed -i '/pam_unix.so/i password requisite pam_pwquality.so retry=3 enforce_for_root' "$PAM_PASSWD"
fi

PAM_AUTH="/etc/pam.d/common-auth"
if [ -f "$PAM_AUTH" ] && ! grep -q "pam_faillock" "$PAM_AUTH"; then
    sed -i '1s/^/auth required pam_faillock.so preauth silent audit deny=5 unlock_time=900\n/' "$PAM_AUTH"
    echo "auth [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900" >> "$PAM_AUTH"
fi

ok "Password policy applied."

#######################################################################
# SSH hardening
#######################################################################

log "Hardening SSH..."

SSHD_CONF="/etc/ssh/sshd_config"
SSHD_HARDENING="/etc/ssh/sshd_config.d/99-hardening.conf"

if [ ! -f "$SSHD_CONF" ]; then
    warn "sshd_config not found, skipping SSH hardening."
else
    # Use drop-in file if supported (OpenSSH 8.2+), else patch sshd_config directly
    if grep -q "^Include /etc/ssh/sshd_config.d" "$SSHD_CONF" 2>/dev/null; then
        mkdir -p /etc/ssh/sshd_config.d
        cat > "$SSHD_HARDENING" << 'EOF'
# Disable root login
PermitRootLogin no

# Disable password authentication — use keys only
PasswordAuthentication no
PermitEmptyPasswords no

# Disable challenge-response (e.g. keyboard-interactive)
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no

# Disable unused authentication methods
UsePAM yes
GSSAPIAuthentication no
HostbasedAuthentication no

# Limit authentication attempts
MaxAuthTries 3
MaxSessions 4

# Idle session timeout (seconds)
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable X11 and agent forwarding
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no

# Restrict to strong ciphers, MACs, and key exchange algorithms
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512

# Use privilege separation
UsePrivilegeSeparation sandbox

# Log level for auditing
LogLevel VERBOSE

# Disable .rhosts and /etc/hosts.equiv
IgnoreRhosts yes

# Banner
Banner /etc/issue.net
EOF
        ok "SSH hardening written to $SSHD_HARDENING."
    else
        # Direct patching for older OpenSSH
        apply_sshd() {
            KEY=$1; VAL=$2
            if grep -q "^#*\s*${KEY}" "$SSHD_CONF"; then
                sed -i "s|^#*\s*${KEY}.*|${KEY} ${VAL}|" "$SSHD_CONF"
            else
                echo "${KEY} ${VAL}" >> "$SSHD_CONF"
            fi
        }
        apply_sshd PermitRootLogin no
        apply_sshd PasswordAuthentication no
        apply_sshd PermitEmptyPasswords no
        apply_sshd MaxAuthTries 3
        apply_sshd X11Forwarding no
        apply_sshd ClientAliveInterval 300
        apply_sshd ClientAliveCountMax 2
        apply_sshd AllowAgentForwarding no
        apply_sshd AllowTcpForwarding no
        apply_sshd LogLevel VERBOSE
        apply_sshd IgnoreRhosts yes
        ok "SSH hardening applied to $SSHD_CONF."
    fi

    # Set a login banner
    cat > /etc/issue.net << 'EOF'
Authorized access only. All activity is monitored and logged.
Unauthorized access is prohibited and may be prosecuted.
EOF

    # Validate and reload sshd
    if sshd -t >/dev/null 2>&1; then
        systemctl reload sshd 2>/dev/null || service ssh reload 2>/dev/null || true
        ok "sshd reloaded."
    else
        err "sshd config test failed — review $SSHD_CONF manually."
    fi
fi

log "Hardening complete."
