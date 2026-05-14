#!/bin/bash

set -euo pipefail

BACKUP_MOUNT="/mnt/backup"

LAST_BACKUP_PATH_FILE=""

get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}

save_last_backup_path() {
    local path="$1"
    printf '%s\n' "$path" > "$LAST_BACKUP_PATH_FILE"
}

load_last_backup_path() {

    [[ -f "$LAST_BACKUP_PATH_FILE" ]] || return 1

    cat "$LAST_BACKUP_PATH_FILE"
}

get_backup_dir() {

    local SCRIPT_DIR="$1"

    LAST_BACKUP_PATH_FILE="$SCRIPT_DIR/.last_backup_path"

    # =========================
    # MANUAL OVERRIDE
    # =========================

    if [[ -n "${BACKUP_PATH:-}" ]]; then

        mkdir -p "$BACKUP_PATH"

        if [[ ! -w "$BACKUP_PATH" ]]; then
            echo "[!] Backup path not writable: $BACKUP_PATH" >&2
            exit 1
        fi

        save_last_backup_path "$BACKUP_PATH"

        echo "$BACKUP_PATH"
        return
    fi

    # =========================
    # LAST USED PATH
    # =========================

    local remembered

    if remembered="$(load_last_backup_path 2>/dev/null)"; then

        if [[ -n "$remembered" ]]; then

            mkdir -p "$remembered"

            echo "$remembered"
            return
        fi
    fi

    # =========================
    # MOUNTED BACKUP DRIVE
    # =========================

    if [[ -d "$BACKUP_MOUNT" ]] && mountpoint -q "$BACKUP_MOUNT"; then

        local mount_path="$BACKUP_MOUNT/PS4Linux"

        mkdir -p "$mount_path"

        save_last_backup_path "$mount_path"

        echo "$mount_path"
        return
    fi

    # =========================
    # FALLBACK
    # =========================

    echo "[!] Backup mount not found. Using script directory." >&2

    local fallback="$SCRIPT_DIR/backups"

    mkdir -p "$fallback"

    save_last_backup_path "$fallback"

    echo "$fallback"
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

    if [[ -z "$CUSTOM_NAME" ]]; then
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

load_excludes() {

    local SCRIPT_DIR="$1"
    shift

    "$SCRIPT_DIR/helper-process-exclusions.sh" "$@"
}
