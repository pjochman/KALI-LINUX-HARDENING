# Kali Linux Hardening

A collection of scripts to install and run common Linux security auditing tools.

## Tools

### Rootkit & Integrity
- **rkhunter** — scans for rootkits, backdoors, and local exploits
- **chkrootkit** — checks for signs of rootkits on the local system
- **debcheckroot** — checks Debian packages against known rootkit signatures
- **debsums** — verifies MD5 checksums of installed Debian packages
- **unhide** — detects hidden processes and ports
- **tripwire** — file integrity monitoring
- **aide** — advanced intrusion detection environment; file integrity checker

### Firewall & Intrusion Prevention
- **ufw** — uncomplicated firewall; manages iptables rules
- **fail2ban** — bans IPs with too many failed authentication attempts

### USB Control
- **usbguard** — enforces USB device authorisation policies

### Mandatory Access Control
- **apparmor** — confines programs to a limited set of resources via profiles
- **selinux** — label-based mandatory access control (mutually exclusive with AppArmor)

### System Auditing & Maintenance
- **lynis** — in-depth security auditing and hardening tool for Unix-based systems
- **auditd** — Linux audit daemon; records security-relevant system events
- **needrestart** — identifies daemons that need restarting after library upgrades
- **logwatch** — log analysis and reporting

### Antivirus
- **clamav** — open-source antivirus; scans the filesystem for malware

### Web & Vulnerability Scanning
- **nikto** — web server scanner; detects misconfigurations and vulnerabilities
- **nmap + vulners** — network/vulnerability scanning using the vulners NSE script
- **nuclei** — fast template-based vulnerability scanner
- **grype** — filesystem and container vulnerability scanner
- **trivy** — comprehensive vulnerability scanner for filesystems and containers
- **openvas/gvm** — full-featured vulnerability management and scanning platform

### Network IDS/IPS
- **snort** — network intrusion detection and prevention system
- **suricata** — high-performance network IDS/IPS/NSM engine
- **zeek** — network analysis framework for security monitoring

### Host-based IDS
- **ossec** — host-based intrusion detection with log analysis and alerting

### Memory Forensics
- **volatility3** — memory forensics framework for analyzing RAM dumps

### Network & Process Inspection
- **lsof** — lists open files and network connections
- **pslist** — lists running processes for anomaly detection

### Process Tracing & Reverse Engineering
- **strace** — traces system calls of a process
- **ltrace** — traces library calls of a process
- **radare2** — reverse engineering framework for binary analysis

## Usage

### 1. Install the tools

```sh
sudo ./install.sh
```

Installs all tools. apt packages are installed via apt; nuclei, grype, and trivy are fetched from their official release scripts. Skips any tool already installed. Also:
- Runs `freshclam` to update ClamAV virus definitions
- Installs the vulners NSE script for nmap

> **Notes:**
> - OpenVAS/GVM requires additional setup: run `gvm-setup` after installation.
> - Snort and Suricata run as daemons; configure rules before enabling.
> - Tripwire requires initialisation: run `tripwire --init` after installation.
> - AIDE requires initialisation: run `aide --init` and move the generated database before first check.
> - auditd runs as a daemon; configure rules in `/etc/audit/rules.d/`.
> - fail2ban runs as a daemon; configure jails in `/etc/fail2ban/jail.local`.
> - AppArmor and SELinux are mutually exclusive — choose one.

### 2. Apply system hardening

```sh
sudo ./harden.sh
```

Applies the following hardening:
- **sysctl** — writes hardened kernel parameters to `/etc/sysctl.d/99-hardening.conf` covering network stack, ASLR, ptrace restrictions, BPF hardening, and filesystem protections
- **AppArmor** — sets all installed profiles to enforce mode
- **SELinux** — activates SELinux (requires reboot; mutually exclusive with AppArmor)
- **Password policy** — enforces 14-char minimum, complexity requirements, 90-day expiry, and account lockout after 5 failed attempts via PAM + pwquality
- **SSH hardening** — disables root login and password auth, restricts ciphers/MACs/KEX to modern algorithms, sets idle timeout, and writes a login banner
- **Kernel module hardening** — blacklists uncommon filesystems, network protocols, Bluetooth, FireWire, and Thunderbolt via `/etc/modprobe.d/99-hardening.conf`
- **USB restrictions** — disables USB storage via modprobe blacklist; configures USBGuard to whitelist only currently connected devices

### 3. Run a full security scan

```sh
sudo ./scan.sh
```

Runs all automated scanner tools and saves output to `scan-results/`:

```
scan-results/
  rkhunter_<timestamp>.log
  chkrootkit_<timestamp>.log
  unhide_<timestamp>.log
  debcheckroot_<timestamp>.log
  debsums_<timestamp>.log
  tripwire_<timestamp>.log
  aide_<timestamp>.log
  lynis_<timestamp>.log
  aureport_<timestamp>.log
  ufw_<timestamp>.log
  fail2ban-client_<timestamp>.log
  needrestart_<timestamp>.log
  logwatch_<timestamp>.log
  clamscan_<timestamp>.log
  nikto_<timestamp>.log
  nmap_<timestamp>.log
  nuclei_<timestamp>.log
  grype_<timestamp>.log
  trivy_<timestamp>.log
  lsof_<timestamp>.log
  pslist_<timestamp>.log
  summary_<timestamp>.log
```

Any tool not found on the system is skipped automatically.

> **Note:** `strace`, `ltrace`, `radare2`, `volatility3`, `snort`, `suricata`, `zeek`, and `ossec` are not included in the automated scan — they require manual invocation or daemon configuration.
