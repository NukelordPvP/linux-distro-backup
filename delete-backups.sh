#!/bin/bash
# delete-backups.sh
# Deletes all backup files inside the backups directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

BACKUP_DIR="$SCRIPT_DIR/backups"

# =========================================
# Validation
# =========================================

if [[ ! -d "$BACKUP_DIR" ]]; then
    fatal "Backup directory not found: $BACKUP_DIR"
fi

# =========================================
# Show files
# =========================================

log_section "Backup files"

find "$BACKUP_DIR" -maxdepth 1 -type f | sort || true

echo

read -rp "Delete ALL files in $BACKUP_DIR? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    log_info "Cancelled"
    exit 0
fi

# =========================================
# Delete files
# =========================================

FOUND=0

while IFS= read -r FILE; do

    [[ -f "$FILE" ]] || continue

    FOUND=1

    log_warn "Deleting: $FILE"

    rm -f "$FILE"

done < <(
    find "$BACKUP_DIR" -maxdepth 1 -type f | sort
)

echo

if [[ "$FOUND" -eq 0 ]]; then
    log_info "No files found"
else
    log_ok "All backup files deleted"
fi
