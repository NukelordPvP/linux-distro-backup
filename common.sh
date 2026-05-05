#!/bin/bash
# Shared functions for backup scripts

set -euo pipefail

# Default mount location
BACKUP_MOUNT="/mnt/backup"

# Get script directory (caller-safe)
get_script_dir() {
    local SRC="${BASH_SOURCE[1]}"
    cd "$(dirname "$SRC")" && pwd
}

# Determine backup directory
get_backup_dir() {
    local SCRIPT_DIR="$1"

    if [ -d "$BACKUP_MOUNT" ] && mountpoint -q "$BACKUP_MOUNT"; then
        echo "$BACKUP_MOUNT/PS4Linux"
    else
        echo "[!] Backup mount not found. Using script directory." >&2
        echo "$SCRIPT_DIR/backups"
    fi
}

# Ensure directory exists
ensure_dir() {
    mkdir -p "$1"
}

# Generate timestamp
get_timestamp() {
    date +%Y%m%d_%H%M
}

# Build filename
build_filename() {
    local PREFIX="$1"
    local DATESTAMP="$2"
    local CUSTOM_NAME="${3:-}"

    if [ -z "$CUSTOM_NAME" ]; then
        echo "${PREFIX}_${DATESTAMP}.tar.xz"
    else
        [[ "$CUSTOM_NAME" != *.tar.xz ]] && CUSTOM_NAME="${CUSTOM_NAME}.tar.xz"
        echo "$CUSTOM_NAME"
    fi
}

# Build log file path
build_logfile() {
    local BACKUP_DIR="$1"
    local FILENAME="$2"
    echo "$BACKUP_DIR/${FILENAME%.tar.xz}.log"
}

# Load exclusions into array
load_excludes() {
    local SCRIPT_DIR="$1"
    shift

    read -r -a EXCLUDES <<< "$("$SCRIPT_DIR/helper-process-exclusions.sh" "$@")"
    echo "${EXCLUDES[@]}"
}
