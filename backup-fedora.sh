#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 🔒 lock (prevents double runs)
LOCK="/tmp/backup-fedora.lock"
exec 200>"$LOCK"
flock -n 200 || {
    echo "[!] Fedora backup already running"
    exit 1
}

DATESTAMP="$(get_timestamp)"
BACKUP_DIR="$(get_backup_dir "$SCRIPT_DIR")"
ensure_dir "$BACKUP_DIR"

FILENAME="$(build_filename "ps4fedora" "$DATESTAMP" "${1:-}")"
BACKUP_FILE="$BACKUP_DIR/$FILENAME"
LOG_FILE="$(build_logfile "$BACKUP_DIR" "$FILENAME")"

# Load exclusions
read -r -a EXCLUDES <<< "$(load_excludes "$SCRIPT_DIR" \
    "$SCRIPT_DIR/global-exclusions.txt" \
    "$SCRIPT_DIR/backup-fedora-exclusions.txt"
)"

{
    echo "[*] Starting Fedora backup at $(date)"
    cd /

    tar -cvf "$BACKUP_FILE" \
        "${EXCLUDES[@]}" \
        --exclude="$BACKUP_FILE" \
        --one-file-system ./ \
        -I "xz -9"

    echo "[✓] Backup completed at $(date): $BACKUP_FILE"

} >"$LOG_FILE" 2>&1 &

echo "[✓] Fedora backup started"
echo "    File: $BACKUP_FILE"
echo "    Log:  $LOG_FILE"
