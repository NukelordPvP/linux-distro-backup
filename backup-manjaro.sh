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

DATESTAMP="$(get_timestamp)"
BACKUP_DIR="$(get_backup_dir "$SCRIPT_DIR")"
ensure_dir "$BACKUP_DIR"

FILENAME="$(build_filename "ps4manjaro" "$DATESTAMP" "${1:-}")"

BACKUP_FILE="$BACKUP_DIR/$FILENAME"
LOG_FILE="${BACKUP_FILE}.log"
SUMMARY_LOG="${BACKUP_FILE}_summary.log"

read -r -a EXCLUDES <<< "$(load_excludes "$SCRIPT_DIR" \
    "$SCRIPT_DIR/global-exclusions.txt" \
    "$SCRIPT_DIR/backup-manjaro-exclusions.txt"
)"

{
    log_info "Starting Manjaro backup at $(date)"

    summary_info "Backup: $BACKUP_FILE"
    summary_info "Compression: $BACKUP_COMPRESSION -${BACKUP_COMPRESSION_LEVEL}"

    log_section "Loaded exclusions"

    for EX in "${EXCLUDES[@]}"; do
        CLEAN="${EX#--exclude=}"
        summary_info "Exclude: $CLEAN"
    done

    run_backup_tar "$BACKUP_FILE" "${EXCLUDES[@]}"

} >"$LOG_FILE" 2>&1 &

log_ok "Manjaro backup started"
echo "File: $BACKUP_FILE"
echo "Log:  $LOG_FILE"
echo "Summary: $SUMMARY_LOG"
