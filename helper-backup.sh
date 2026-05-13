#!/bin/bash
# helper-backup.sh
# Shared backup helpers/configuration

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
# Shared tar backup runner
# =========================================

run_backup_tar() {

    local backup_file="$1"
    shift

    local compression_cmd
    compression_cmd="$(get_compression_cmd)"

    log_info "Using compression: $compression_cmd"

    tar -cf "$backup_file" \
        -I "$compression_cmd" \
        "${BACKUP_TAR_ARGS[@]}" \
        "$@"
}
