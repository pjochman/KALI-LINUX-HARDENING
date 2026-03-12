# Kali Linux Hardening

A collection of scripts to install and run common Linux security auditing tools.

## Tools

### Rootkit & Integrity
- **rkhunter** — scans for rootkits, backdoors, and local exploits
- **chkrootkit** — checks for signs of rootkits on the local system
- **debsums** — verifies MD5 checksums of installed Debian packages
- **unhide** — detects hidden processes and ports

### System Auditing
- **lynis** — in-depth security auditing and hardening tool for Unix-based systems

### Antivirus
- **clamav** — open-source antivirus; scans the filesystem for malware

### Web & Vulnerability Scanning
- **nikto** — web server scanner; detects misconfigurations and vulnerabilities
- **nmap + vulners** — network/vulnerability scanning using the vulners NSE script
- **openvas/gvm** — full-featured vulnerability management and scanning platform

### Process Analysis & Tracing
- **pslist** — lists running processes for anomaly detection
- **strace** — traces system calls of a process
- **ltrace** — traces library calls of a process

### Reverse Engineering
- **radare2** — reverse engineering framework for binary analysis

## Usage

### 1. Install the tools

```sh
sudo ./install.sh
```

Installs all tools via apt. Skips any tool already installed. Also:
- Runs `freshclam` to update ClamAV virus definitions
- Installs the vulners NSE script for nmap

> **Note:** OpenVAS/GVM requires additional setup after installation. Run `gvm-setup` to initialise the scanner.

### 2. Run a full security scan

```sh
sudo ./scan.sh
```

Runs all automated scanner tools and saves output to `scan-results/`:

```
scan-results/
  rkhunter_<timestamp>.log
  chkrootkit_<timestamp>.log
  unhide_<timestamp>.log
  debsums_<timestamp>.log
  lynis_<timestamp>.log
  clamscan_<timestamp>.log
  nikto_<timestamp>.log
  nmap_<timestamp>.log
  pslist_<timestamp>.log
  summary_<timestamp>.log      # lists paths to all output files
```

Any tool not found on the system is skipped automatically.

> **Note:** `strace`, `ltrace`, and `radare2` are interactive analysis tools and are not included in the automated scan. Use them manually on specific binaries of interest.
