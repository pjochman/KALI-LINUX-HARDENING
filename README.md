# Kali Linux Hardening

A collection of scripts to install and run common Linux security auditing tools.

## Tools

- **rkhunter** — rootkit hunter; scans for rootkits, backdoors, and local exploits
- **chkrootkit** — checks for signs of rootkits on the local system
- **lynis** — in-depth security auditing and hardening tool for Unix-based systems

## Usage

### 1. Install the tools

```sh
sudo ./install.sh
```

Installs rkhunter, chkrootkit, and lynis via apt. Skips any tool already installed.

### 2. Run a full security scan

```sh
sudo ./scan.sh
```

Runs all three tools and saves output to `scan-results/`:

```
scan-results/
  rkhunter_<timestamp>.log
  chkrootkit_<timestamp>.log
  lynis_<timestamp>.log
  summary_<timestamp>.log      # lists paths to all output files
```

Any tool not found on the system is skipped automatically.
