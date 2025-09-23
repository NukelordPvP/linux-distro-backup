#!/bin/bash
# Where the backup drive is normally mounted
BACKUP_MOUNT="/mnt/backup"

# Determine the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use backup mount if it exists, otherwise fallback to script dir
if [ -d "$BACKUP_MOUNT" ] && mountpoint -q "$BACKUP_MOUNT"; then
    BACKUP_DIR="$BACKUP_MOUNT/PS4Linux"
else
    echo "[!] Backup mount not found. Using script directory for backup."
    BACKUP_DIR="$SCRIPT_DIR/backups"
fi

# Make sure the backup dir exists
mkdir -p "$BACKUP_DIR"

# Timestamp
DATESTAMP=$(date +%Y%m%d_%H%M)

# Backup filename
BACKUP_FILE="$BACKUP_DIR/ps4fedora43kde_${DATESTAMP}.tar.xz"
LOG_FILE="$BACKUP_DIR/backup_${DATESTAMP}.log"

# Run backup with logging
{
    echo "[*] Starting backup at $(date)"
    cd /
    sudo tar -cvf "$BACKUP_FILE" \
        --exclude="$BACKUP_FILE" \
        --exclude=dev/ \
        --exclude=proc/ \
        --exclude=sys/ \
        --exclude=var/cache \
        --one-file-system ./ \
        -I "xz -9"
    echo "[?] Backup completed at $(date): $BACKUP_FILE"
} >"$LOG_FILE" 2>&1 &

echo "[?] Backup started in background. Log: $LOG_FILE"
