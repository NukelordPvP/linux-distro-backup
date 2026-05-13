#!/bin/bash
# helper-backup.sh
# Shared backup helpers/configuration (FIXED: stable find-based pruning)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

# =========================================
# Backup configuration
# =========================================

BACKUP_COMPRESSION="${BACKUP_COMPRESSION:-xz}"
BACKUP_COMPRESSION_LEVEL="${BACKUP_COMPRESSION_LEVEL:-9}"

BACKUP_TAR_ARGS=(
    --one-file-system
    --ignore-failed-read
)

# =========================================
# Compression helper
# =========================================

get_compression_cmd() {
    case "$BACKUP_COMPRESSION" in
        xz)
            echo "xz -${BACKUP_COMPRESSION_LEVEL}"
            ;;
        gzip)
            echo "gzip -${BACKUP_COMPRESSION_LEVEL}"
            ;;
        zstd)
            echo "zstd -${BACKUP_COMPRESSION_LEVEL}"
            ;;
        *)
            fatal "Unsupported compression type: $BACKUP_COMPRESSION"
            ;;
    esac
}

# =========================================
# Log helpers
# =========================================

log_backup_config() {
    summary_info "Compression: ${BACKUP_COMPRESSION} -${BACKUP_COMPRESSION_LEVEL}"

    for ARG in "${BACKUP_TAR_ARGS[@]}"; do
        summary_info "tar arg: $ARG"
    done
}

# =========================================
# EXCLUSION BUILDER (FIXED)
# Converts /mnt → ./mnt for find -path matching
# =========================================

_build_find_prune() {

    local ex
    local args=()

    for ex in "$@"; do

        ex="${ex#--exclude=}"

        [[ -z "$ex" ]] && continue

        # convert absolute /path → ./path for find . traversal
        if [[ "$ex" == /* ]]; then
            ex=".${ex}"
        fi

        args+=( -path "$ex" -o )

    done

    # remove trailing -o safely
    if [[ "${#args[@]}" -gt 0 ]]; then
        unset 'args[${#args[@]}-1]'
    fi

    printf '%s\0' "${args[@]}"
}

# =========================================
# Shared backup runner (FIXED CORE)
# =========================================

run_backup_tar() {

    local backup_file="$1"
    shift

    local compression_cmd
    compression_cmd="$(get_compression_cmd)"

    log_info "Using compression: $compression_cmd"

    cd /

    # Build prune expression safely
    local PRUNE_EXPR=()
    mapfile -d '' -t PRUNE_EXPR < <(_build_find_prune "$@")

    if [[ "${#PRUNE_EXPR[@]}" -gt 0 ]]; then

        log_info "Using find-based exclusion traversal"

        find . \( "${PRUNE_EXPR[@]}" \) -prune -o -print0 \
        | tar --null -cf "$backup_file" \
            -I "$compression_cmd" \
            "${BACKUP_TAR_ARGS[@]}" \
            --files-from=-

    else

        log_info "No exclusions provided"

        find . -print0 \
        | tar --null -cf "$backup_file" \
            -I "$compression_cmd" \
            "${BACKUP_TAR_ARGS[@]}" \
            --files-from=-

    fi
}
