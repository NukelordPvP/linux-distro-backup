#!/bin/bash
# helper-logging.sh

set -euo pipefail

SUMMARY_LOG="${SUMMARY_LOG:-}"

# =========================
# Terminal logging
# =========================

log_info()  { echo "[*] $*"; }
log_ok()    { echo "[✓] $*"; }
log_warn()  { echo "[!] $*"; }
log_error() { echo "[✗] $*" >&2; }

log_section() {
    echo
    echo "=== $* ==="
}

fatal() {
    log_error "$*"
    exit 1
}

# =========================
# File logging (summary only)
# =========================

summary_log() {
    [[ -n "${SUMMARY_LOG:-}" ]] || return 0
    echo "$*" >> "$SUMMARY_LOG"
}

summary_info()  { summary_log "[*] $*"; }
summary_ok()    { summary_log "[✓] $*"; }
summary_warn()  { summary_log "[!] $*"; }
summary_error() { summary_log "[✗] $*"; }

summary_section() {
    summary_log ""
    summary_log "=== $* ==="
}
