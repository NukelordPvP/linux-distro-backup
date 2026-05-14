#!/bin/bash

set -euo pipefail

# Re-run script as root if needed
if [[ $EUID -ne 0 ]]; then
    exec sudo bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/helper-logging.sh"
source "$SCRIPT_DIR/helper-backup.sh"

# =========================
# REAL USER
# =========================

REAL_USER="${SUDO_USER:-$USER}"
REAL_GROUP="$(id -gn "$REAL_USER")"

# =========================
# LOCKING
# =========================

LOCK_DIR="$SCRIPT_DIR/.locks"

mkdir -p "$LOCK_DIR"

chown "$REAL_USER:$REAL_GROUP" "$LOCK_DIR" 2>/dev/null || true

LOCK="$LOCK_DIR/backup-manjaro.lock"

touch "$LOCK"

chown "$REAL_USER:$REAL_GROUP" "$LOCK" 2>/dev/null || true

exec 200>"$LOCK"

flock -n 200 || {
    log_warn "Manjaro backup already running"
    exit 1
}

cleanup_lock() {
    rm -f "$LOCK"
}

trap cleanup_lock EXIT

# =========================
# CONFIG
# =========================

BACKUP_BACKGROUND="${BACKUP_BACKGROUND:-0}"

# =========================
# PATHS
# =========================

DATESTAMP="$(get_timestamp)"
BACKUP_DIR="$(get_backup_dir "$SCRIPT_DIR")"

ensure_dir "$BACKUP_DIR"

FILENAME="$(build_filename "ps4manjaro" "$DATESTAMP" "${1:-}")"

# HARD VALIDATION
if [[ -z "$FILENAME" ]]; then
    fatal "Generated filename is empty"
fi

BACKUP_FILE="$BACKUP_DIR/$FILENAME"

LOG_FILE="${BACKUP_FILE%.tar.*}.log"
SUMMARY_LOG="${BACKUP_FILE%.tar.*}_summary.log"

# =========================
# JOB
# =========================

run_job() {

    log_info "Starting Manjaro backup at $(date)"
    log_info "Output file: $BACKUP_FILE"

    summary_info "Backup: $BACKUP_FILE"
    summary_info "Compression: $BACKUP_COMPRESSION -${BACKUP_COMPRESSION_LEVEL}"

    run_backup_tar \
        "$BACKUP_FILE" \
        "$SCRIPT_DIR/global-exclusions.txt" \
        "$SCRIPT_DIR/backup-manjaro-exclusions.txt"

    # =========================
    # FIX OWNERSHIP
    # =========================

    chown "$REAL_USER:$REAL_GROUP" \
        "$BACKUP_FILE" \
        "$LOG_FILE" \
        "$SUMMARY_LOG" 2>/dev/null || true
}

# =========================
# EXECUTION MODE
# =========================

if [[ "$BACKUP_BACKGROUND" == "1" ]]; then

    (
        run_job
    ) >"$LOG_FILE" 2>&1 &

    PID=$!

    chown "$REAL_USER:$REAL_GROUP" \
        "$LOG_FILE" \
        "$SUMMARY_LOG" 2>/dev/null || true

    log_ok "Backup running in background (PID: $PID)"

    echo "File: $BACKUP_FILE"
    echo "Log: $LOG_FILE"
    echo "Summary: $SUMMARY_LOG"
    echo "PID: $PID"

else

    run_job >"$LOG_FILE" 2>&1

    log_ok "Backup finished"

    echo "File: $BACKUP_FILE"
    echo "Log: $LOG_FILE"
    echo "Summary: $SUMMARY_LOG"

fi
