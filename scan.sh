#!/bin/sh

OUTDIR="./scan-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$OUTDIR"

log() {
    echo "[*] $1"
}

run_tool() {
    TOOL=$1
    CMD=$2
    OUTFILE="$OUTDIR/${TOOL}_${TIMESTAMP}.log"

    if ! command -v "$TOOL" >/dev/null 2>&1; then
        echo "[!] $TOOL not found, skipping." | tee -a "$OUTDIR/summary_${TIMESTAMP}.log"
        return
    fi

    log "Running $TOOL..."
    echo "=== $TOOL - $TIMESTAMP ===" > "$OUTFILE"
    eval "$CMD" >> "$OUTFILE" 2>&1
    echo "[+] $TOOL output saved to $OUTFILE"
    echo "$TOOL: $OUTFILE" >> "$OUTDIR/summary_${TIMESTAMP}.log"
}

# Rootkit detection
run_tool "rkhunter"      "rkhunter --check --skip-keypress --report-warnings-only"
run_tool "chkrootkit"    "chkrootkit"
run_tool "unhide"        "unhide sys"
run_tool "debcheckroot"  "debcheckroot"

# Package & file integrity
run_tool "debsums"       "debsums -c"
run_tool "tripwire"      "tripwire --check"
run_tool "aide"          "aide --check"

# System audit & maintenance
run_tool "lynis"         "lynis audit system --no-colors"
run_tool "aureport"      "aureport --summary"
run_tool "ufw"           "ufw status verbose"
run_tool "fail2ban-client" "fail2ban-client status"
run_tool "aa-status"     "aa-status"
run_tool "sestatus"      "sestatus"
run_tool "needrestart"   "needrestart -b"
run_tool "logwatch"      "logwatch --output stdout --format text --range today"

# Antivirus
run_tool "clamscan"      "clamscan -r / --exclude-dir=^/sys --exclude-dir=^/proc --exclude-dir=^/dev"

# Web server scan (localhost)
run_tool "nikto"         "nikto -h localhost"

# Vulnerability scan (localhost)
run_tool "nmap"          "nmap --script vulners -sV localhost"
run_tool "nuclei"        "nuclei -u localhost -silent"

# Filesystem vulnerability scan
run_tool "grype"         "grype /"
run_tool "trivy"         "trivy fs /"

# Network & process inspection
run_tool "lsof"          "lsof -i"
run_tool "pslist"        "pslist"

log "Done. Results in $OUTDIR/"
