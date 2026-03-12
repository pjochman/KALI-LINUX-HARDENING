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

run_tool "rkhunter"   "rkhunter --check --skip-keypress --report-warnings-only"
run_tool "chkrootkit" "chkrootkit"
run_tool "lynis"      "lynis audit system --no-colors"

log "Done. Results in $OUTDIR/"
