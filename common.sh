#!/bin/bash

set -euo pipefail

BACKUP_MOUNT="/mnt/backup"

get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}

get_backup_dir() {
    local SCRIPT_DIR="$1"

    if [ -d "$BACKUP_MOUNT" ] && mountpoint -q "$BACKUP_MOUNT"; then
        echo "$BACKUP_MOUNT/PS4Linux"
    else
        echo "[!] Backup mount not found. Using script directory." >&2
        echo "$SCRIPT_DIR/backups"
    fi
}

ensure_dir() {
    mkdir -p "$1"
}

get_timestamp() {
    date +%Y%m%d_%H%M
}

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

build_logfile() {
    local BACKUP_DIR="$1"
    local FILENAME="$2"
    echo "$BACKUP_DIR/${FILENAME%.tar.xz}.log"
}

# FIXED: no broken array echoing
load_excludes() {
    local SCRIPT_DIR="$1"
    shift

    "$SCRIPT_DIR/helper-process-exclusions.sh" "$@"
}
