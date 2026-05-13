#!/bin/bash
# helper-logging.sh

set -euo pipefail

SUMMARY_LOG="${SUMMARY_LOG:-}"

# =========================
# Terminal logging (stderr ONLY)
# =========================

log_info()  { echo "[*] $*" >&2; }
log_ok()    { echo "[✓] $*" >&2; }
log_warn()  { echo "[!] $*" >&2; }
log_error() { echo "[✗] $*" >&2; }

log_section() {
    echo >&2
    echo "=== $* ===" >&2
}

fatal() {
    log_error "$*"
    exit 1
}

# =========================
# File logging (safe)
# =========================

summary_log() {
    [[ -n "${SUMMARY_LOG:-}" ]] || return 0
    echo "$*" >> "$SUMMARY_LOG"
}

summary_info()  { summary_log "[*] $*"; }
summary_ok()    { summary_log "[✓] $*"; }
summary_warn()  { summary_log "[!] $*"; }
summary_error() { summary_log "[✗] $*"; }
