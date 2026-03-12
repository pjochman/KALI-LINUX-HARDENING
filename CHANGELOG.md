# Changelog

All notable changes to this project are documented here.

---

## [Unreleased]

## [2026-03-12]

### Added
- `CONTRIBUTING.md` — contributing guidelines for adding tools, hardening rules, and code style
- `LICENSE` — MIT license
- `menu.py` — interactive Python terminal menu to run tools individually or all at once, with install status indicators
- Kernel module hardening in `harden.sh` — blacklists uncommon filesystems, network protocols, Bluetooth, FireWire, and Thunderbolt via `/etc/modprobe.d/99-hardening.conf`
- USB restrictions in `harden.sh` — disables USB storage via modprobe; configures USBGuard to whitelist currently connected devices
- `usbguard` to `install.sh`
- Password policy in `harden.sh` — 14-char minimum, complexity via pwquality, 90-day expiry, account lockout via PAM
- SSH hardening in `harden.sh` — no root login, no password auth, modern ciphers/MACs/KEX, idle timeout, login banner
- AppArmor and SELinux support in `harden.sh` and `install.sh`
- `harden.sh` — sysctl kernel hardening covering network stack, ASLR, ptrace, BPF, and filesystem protections
- Tools: `aide`, `auditd`, `fail2ban`, `ufw`
- Tools: `tripwire`, `lsof`, `volatility3`, `nuclei`, `suricata`, `ossec`, `zeek`, `snort`, `grype`, `trivy`, `debcheckroot`, `needrestart`, `logwatch`
- Tools: `chkrootkit`, `debsums`, `strace`, `ltrace`, `nmap+vulners`, `gvm`, `nikto`, `radare2`, `pslist`, `unhide`
- Tools: `clamav` with automatic `freshclam` update
- `scan.sh` — automated scan script running all installed tools and saving timestamped output to `scan-results/`
- `install.sh` — installs all tools via apt; fetches nuclei, grype, and trivy from official release scripts
- `util/logging.py` — Python logging utility with `get_logger()` factory
- `util/__init__.py` — makes `util` a Python package
- `.gitignore` — ignores `scan-results/`, logs, and Python bytecode
- Initial project structure with `README.md`
