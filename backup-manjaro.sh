#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/helper-logging.sh"
source "$SCRIPT_DIR/helper-backup.sh"

# 🔒 lock
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

# =========================================
# Load exclusions
# =========================================

read -r -a EXCLUDES <<< "$(load_excludes "$SCRIPT_DIR" \
    "$SCRIPT_DIR/global-exclusions.txt" \
    "$SCRIPT_DIR/backup-manjaro-exclusions.txt"
)"

{
    both_info "Starting Manjaro backup at $(date)"

    summary_info "Backup file: $BACKUP_FILE"

    log_backup_config

    log_section "Loaded exclusions"

    for EXCLUDE in "${EXCLUDES[@]}"; do

        CLEAN_EXCLUDE="${EXCLUDE#--exclude=}"

        log_info "Exclusion rule: $CLEAN_EXCLUDE"

        summary_exclude "$CLEAN_EXCLUDE"

    done

    both_info "Creating archive..."

    run_backup_tar \
        "$BACKUP_FILE" \
        "${EXCLUDES[@]}" \
        --exclude="$BACKUP_FILE" \
        --exclude="$LOG_FILE" \
        --exclude="$SUMMARY_LOG"

    FINAL_SIZE="$(du -h "$BACKUP_FILE" | awk '{print $1}')"

    both_ok "Backup completed at $(date): $BACKUP_FILE"

    summary_info "Final size: $FINAL_SIZE"

} >"$LOG_FILE" 2>&1 &

log_ok "Manjaro backup started"

echo "    File:         $BACKUP_FILE"
echo "    Verbose Log:  $LOG_FILE"
echo "    Summary Log:  $SUMMARY_LOG"
