#!/bin/bash
# helper-backup.sh

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
# EXCLUSION BUILDER (FIXED: CLEAN STDOUT ONLY)
# =========================================

_build_find_prune() {

    local ex
    local args=()

    for ex in "$@"; do

        ex="${ex#--exclude=}"
        [[ -z "$ex" ]] && continue
        [[ "$ex" != /* ]] && continue

        ex=".${ex}"

        # IMPORTANT: log MUST NOT contaminate stdout used by command substitution
        log_info "Pruning: $ex" >&2

        args+=( -path "$ex" -o )

    done

    # remove trailing -o safely
    if [[ "${#args[@]}" -gt 0 ]]; then
        unset 'args[${#args[@]}-1]'
    fi

    # IMPORTANT: stdout = ONLY find args
    printf '%s\n' "${args[@]}"
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

    set -- "$@" "$backup_dir"

    log_info "Phase 1: building snapshot..."

    local FILELIST
    FILELIST="$(mktemp)"

    local PRUNE_ARGS=()
    mapfile -t PRUNE_ARGS < <(_build_find_prune "$@")

    if [[ "${#PRUNE_ARGS[@]}" -gt 0 ]]; then
        log_info "Using find-based exclusion traversal"

        find . \( "${PRUNE_ARGS[@]}" \) -prune -o -print > "$FILELIST"
    else
        log_info "No exclusions"
        find . -print > "$FILELIST"
    fi

    log_info "Phase 2: archiving..."

    tar -cf "$backup_file" \
        -I "$compression_cmd" \
        "${BACKUP_TAR_ARGS[@]}" \
        -T "$FILELIST"

    rm -f "$FILELIST"

    log_ok "Backup complete: $backup_file"
}
