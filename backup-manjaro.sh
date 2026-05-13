#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/helper-logging.sh"
source "$SCRIPT_DIR/helper-backup.sh"

LOCK="/tmp/backup-manjaro.lock"
exec 200>"$LOCK"
flock -n 200 || {
    log_warn "Manjaro backup already running"
    exit 1
}

BACKUP_BACKGROUND="${BACKUP_BACKGROUND:-0}"

# =========================
# PATHS
# =========================

DATESTAMP="$(get_timestamp)"
BACKUP_DIR="$(get_backup_dir "$SCRIPT_DIR")"
ensure_dir "$BACKUP_DIR"

FILENAME="$(build_filename "ps4manjaro" "$DATESTAMP" "${1:-}")"

# HARD VALIDATION (critical fix)
if [[ -z "$FILENAME" ]]; then
    fatal "Generated filename is empty"
fi

BACKUP_FILE="$BACKUP_DIR/$FILENAME"
LOG_FILE="${BACKUP_FILE}.log"
SUMMARY_LOG="${BACKUP_FILE}_summary.log"

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
}

# =========================
# EXECUTION MODE
# =========================

if [[ "$BACKUP_BACKGROUND" == "1" ]]; then

    (
        run_job
    ) >"$LOG_FILE" 2>&1 &

    PID=$!

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
