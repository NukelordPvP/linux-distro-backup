#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/helper-logging.sh"
source "$SCRIPT_DIR/helper-backup.sh"

LOCK="/tmp/backup-fedora.lock"
exec 200>"$LOCK"
flock -n 200 || {
    log_warn "Fedora backup already running"
    exit 1
}

BACKUP_BACKGROUND="${BACKUP_BACKGROUND:-0}"

DATESTAMP="$(get_timestamp)"
BACKUP_DIR="$(get_backup_dir "$SCRIPT_DIR")"
ensure_dir "$BACKUP_DIR"

FILENAME="$(build_filename "ps4fedora" "$DATESTAMP" "${1:-}")"

BACKUP_FILE="$BACKUP_DIR/$FILENAME"
LOG_FILE="${BACKUP_FILE}.log"
SUMMARY_LOG="${BACKUP_FILE}_summary.log"

mapfile -t EXCLUDES < <(
    load_excludes "$SCRIPT_DIR" \
        "$SCRIPT_DIR/global-exclusions.txt" \
        "$SCRIPT_DIR/backup-fedora-exclusions.txt"
)

run_job() {
    log_info "Starting Fedora backup at $(date)"

    summary_info "Backup: $BACKUP_FILE"
    summary_info "Compression: $BACKUP_COMPRESSION -${BACKUP_COMPRESSION_LEVEL}"

    log_section "Loaded exclusions"

    for EX in "${EXCLUDES[@]}"; do
        CLEAN="${EX#--exclude=}"
        summary_info "Exclude: $CLEAN"
    done

    run_backup_tar "$BACKUP_FILE" "${EXCLUDES[@]}"
}

if [[ "$BACKUP_BACKGROUND" == "1" ]]; then

    run_job >"$LOG_FILE" 2>&1 &
    BACKUP_PID=$!

    log_ok "Fedora backup running in BACKGROUND (PID: $BACKUP_PID)"

    echo "File: $BACKUP_FILE"
    echo "Log:  $LOG_FILE"
    echo "Summary: $SUMMARY_LOG"
    echo "PID: $BACKUP_PID"

else

    run_job >"$LOG_FILE" 2>&1

    log_ok "Fedora backup finished"

    echo "File: $BACKUP_FILE"
    echo "Log:  $LOG_FILE"
    echo "Summary: $SUMMARY_LOG"
fi
