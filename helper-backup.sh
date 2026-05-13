#!/bin/bash
# helper-backup.sh
# Snapshot-based backup engine (2-phase: list → archive)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helper-logging.sh"

# =========================================
# CONFIG
# =========================================

BACKUP_COMPRESSION="${BACKUP_COMPRESSION:-xz}"
BACKUP_COMPRESSION_LEVEL="${BACKUP_COMPRESSION_LEVEL:-9}"

BACKUP_TAR_ARGS=(
    --one-file-system
    --ignore-failed-read
)

# =========================================
# COMPRESSION
# =========================================

get_compression_cmd() {
    case "$BACKUP_COMPRESSION" in
        xz) echo "xz -${BACKUP_COMPRESSION_LEVEL}" ;;
        gzip) echo "gzip -${BACKUP_COMPRESSION_LEVEL}" ;;
        zstd) echo "zstd -${BACKUP_COMPRESSION_LEVEL}" ;;
        *) fatal "Unsupported compression: $BACKUP_COMPRESSION" ;;
    esac
}

# =========================================
# EXCLUSION BUILDER
# convert /path → ./path (for find . snapshot)
# =========================================

_build_find_prune() {

    local ex
    local args=()

    for ex in "$@"; do

        ex="${ex#--exclude=}"
        [[ -z "$ex" ]] && continue
        [[ "$ex" != /* ]] && continue

        ex=".${ex}"

        log_info "Pruning: $ex"

        args+=( -path "$ex" -o )

    done

    [[ "${#args[@]}" -gt 0 ]] && unset 'args[${#args[@]}-1]'

    printf '%s\0' "${args[@]}"
}

# =========================================
# SNAPSHOT BACKUP ENGINE
# =========================================

run_backup_tar() {

    local backup_file="$1"
    shift

    local backup_dir
    backup_dir="$(dirname "$backup_file")"

    local compression_cmd
    compression_cmd="$(get_compression_cmd)"

    log_info "Compression: $compression_cmd"

    cd /

    # ALWAYS exclude output directory (self-protection)
    set -- "$@" "$backup_dir"

    log_info "Phase 1: building file snapshot list..."

    local FILELIST
    FILELIST="$(mktemp)"

    local PRUNE_EXPR=()
    mapfile -d '' -t PRUNE_EXPR < <(_build_find_prune "$@")

    if [[ "${#PRUNE_EXPR[@]}" -gt 0 ]]; then

        find . \( "${PRUNE_EXPR[@]}" \) -prune -o -print > "$FILELIST"

    else

        find . -print > "$FILELIST"

    fi

    log_info "Phase 2: creating archive..."

    tar -cf "$backup_file" \
        -I "$compression_cmd" \
        "${BACKUP_TAR_ARGS[@]}" \
        -T "$FILELIST"

    rm -f "$FILELIST"

    log_ok "Backup complete: $backup_file"
}
