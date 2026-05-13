#!/bin/bash
# helper-logging.sh

set -euo pipefail

# Optional summary log path
SUMMARY_LOG="${SUMMARY_LOG:-}"

# =========================
# Basic logging
# =========================

log_info() {
    echo "[*] $*"
}

log_ok() {
    echo "[✓] $*"
}

log_warn() {
    echo "[!] $*"
}

log_error() {
    echo "[✗] $*" >&2
}

log_section() {
    echo
    echo "=== $* ==="
}

fatal() {
    log_error "$*"
    exit 1
}

# =========================
# Summary logging
# =========================

summary_log() {

    [[ -n "${SUMMARY_LOG:-}" ]] || return 0

    echo "$*" >> "$SUMMARY_LOG"
}

summary_info() {
    summary_log "[*] $*"
}

summary_ok() {
    summary_log "[✓] $*"
}

summary_warn() {
    summary_log "[!] $*"
}

summary_error() {
    summary_log "[✗] $*"
}

summary_exclude() {
    summary_log "[SKIP] $*"
}

summary_include() {
    summary_log "[ADD ] $*"
}

summary_section() {
    summary_log ""
    summary_log "=== $* ==="
}

# =========================
# Combined logging
# =========================

both_info() {
    log_info "$*"
    summary_info "$*"
}

both_ok() {
    log_ok "$*"
    summary_ok "$*"
}

both_warn() {
    log_warn "$*"
    summary_warn "$*"
}

both_error() {
    log_error "$*"
    summary_error "$*"
}
