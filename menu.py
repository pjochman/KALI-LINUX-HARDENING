#!/usr/bin/env python3

import os
import subprocess
import sys
from datetime import datetime

OUTDIR = "./scan-results"

TOOLS = {
    "Rootkit & Integrity": [
        ("rkhunter",     "rkhunter --check --skip-keypress --report-warnings-only"),
        ("chkrootkit",   "chkrootkit"),
        ("unhide",       "unhide sys"),
        ("debcheckroot", "debcheckroot"),
        ("debsums",      "debsums -c"),
        ("tripwire",     "tripwire --check"),
        ("aide",         "aide --check"),
    ],
    "System Audit & Maintenance": [
        ("lynis",          "lynis audit system --no-colors"),
        ("aureport",       "aureport --summary"),
        ("needrestart",    "needrestart -b"),
        ("logwatch",       "logwatch --output stdout --format text --range today"),
    ],
    "Firewall & Access Control": [
        ("ufw",            "ufw status verbose"),
        ("fail2ban-client","fail2ban-client status"),
        ("aa-status",      "aa-status"),
        ("sestatus",       "sestatus"),
    ],
    "Antivirus": [
        ("clamscan",       "clamscan -r / --exclude-dir=/sys --exclude-dir=/proc --exclude-dir=/dev"),
    ],
    "Web & Vulnerability Scanning": [
        ("nikto",          "nikto -h localhost"),
        ("nmap",           "nmap --script vulners -sV localhost"),
        ("nuclei",         "nuclei -u localhost -silent"),
        ("grype",          "grype /"),
        ("trivy",          "trivy fs /"),
    ],
    "Network & Process Inspection": [
        ("lsof",           "lsof -i"),
        ("pslist",         "pslist"),
    ],
    "Hardening": [
        ("harden-all",     "bash ./harden.sh"),
    ],
}

# Flatten to indexed list for menu display
def build_menu():
    items = []
    for category, tools in TOOLS.items():
        for tool, cmd in tools:
            items.append((category, tool, cmd))
    return items


def check_installed(binary):
    return subprocess.run(
        ["which", binary.split()[0]],
        capture_output=True
    ).returncode == 0


def run_tool(tool, cmd):
    os.makedirs(OUTDIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    outfile = f"{OUTDIR}/{tool}_{timestamp}.log"

    print(f"\n[*] Running {tool}...")
    print(f"[*] Command: {cmd}")
    print(f"[*] Output: {outfile}\n")
    print("-" * 60)

    with open(outfile, "w") as f:
        f.write(f"=== {tool} - {timestamp} ===\n\n")
        f.flush()
        try:
            proc = subprocess.Popen(
                cmd, shell=True,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True
            )
            for line in proc.stdout:
                print(line, end="")
                f.write(line)
            proc.wait()
        except KeyboardInterrupt:
            print("\n[!] Interrupted.")

    print("-" * 60)
    print(f"[+] Output saved to {outfile}")


def print_menu(items, current_category=None):
    os.system("clear")
    print("=" * 60)
    print("       Kali Linux Hardening — Security Tool Menu")
    print("=" * 60)

    prev_cat = None
    for i, (cat, tool, _) in enumerate(items, 1):
        if cat != prev_cat:
            print(f"\n  {cat}")
            print(f"  {'─' * len(cat)}")
            prev_cat = cat
        installed = check_installed(tool)
        status = "✓" if installed else "✗"
        print(f"  [{i:2d}] {status}  {tool}")

    print("\n" + "=" * 60)
    print("  [A]  Run ALL available tools")
    print("  [H]  Apply full hardening (harden.sh)")
    print("  [Q]  Quit")
    print("=" * 60)


def run_all(items):
    print("\n[*] Running all available tools...\n")
    for _, tool, cmd in items:
        if tool == "harden-all":
            continue
        if check_installed(tool.split()[0]):
            run_tool(tool, cmd)
        else:
            print(f"[!] {tool} not found, skipping.")
    print("\n[+] All tools complete.")


def main():
    if os.geteuid() != 0:
        print("[!] This script should be run as root for full functionality.")
        print("    Some tools may not work correctly without root privileges.\n")

    items = build_menu()

    while True:
        print_menu(items)
        choice = input("\nSelect an option: ").strip().lower()

        if choice == "q":
            print("\nGoodbye.\n")
            sys.exit(0)

        elif choice == "a":
            run_all(items)
            input("\nPress Enter to return to menu...")

        elif choice == "h":
            if os.path.exists("./harden.sh"):
                run_tool("harden", "bash ./harden.sh")
            else:
                print("[!] harden.sh not found.")
            input("\nPress Enter to return to menu...")

        elif choice.isdigit():
            idx = int(choice) - 1
            if 0 <= idx < len(items):
                _, tool, cmd = items[idx]
                if not check_installed(tool.split()[0]) and tool != "harden-all":
                    print(f"\n[!] {tool} is not installed. Run ./install.sh first.")
                    input("\nPress Enter to return to menu...")
                else:
                    run_tool(tool, cmd)
                    input("\nPress Enter to return to menu...")
            else:
                print("[!] Invalid selection.")
                input("Press Enter to continue...")
        else:
            print("[!] Invalid selection.")
            input("Press Enter to continue...")


if __name__ == "__main__":
    main()
