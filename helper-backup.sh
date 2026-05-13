#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helper-logging.sh"

BACKUP_COMPRESSION="${BACKUP_COMPRESSION:-xz}"
BACKUP_COMPRESSION_LEVEL="${BACKUP_COMPRESSION_LEVEL:-9}"

get_compression_cmd() {
    case "$BACKUP_COMPRESSION" in
        xz) echo "xz -${BACKUP_COMPRESSION_LEVEL}" ;;
        gzip) echo "gzip -${BACKUP_COMPRESSION_LEVEL}" ;;
        zstd) echo "zstd -${BACKUP_COMPRESSION_LEVEL}" ;;
        *) fatal "Unsupported compression: $BACKUP_COMPRESSION" ;;
    esac
}

# =========================
# CLEAN DATA-ONLY OUTPUT
# =========================

load_tar_excludes() {

    local file ex expanded

    for file in "$@"; do
        [[ -f "$file" ]] || continue

        while IFS= read -r ex || [[ -n "$ex" ]]; do

            ex="${ex#"${ex%%[![:space:]]*}"}"
            ex="${ex%"${ex##*[![:space:]]}"}"

            [[ -z "$ex" ]] && continue
            [[ "${ex:0:1}" == "#" ]] && continue

            # expand ~
            [[ "$ex" == "~"* ]] && ex="${ex/#\~/$HOME}"

            # normalize
            ex="${ex#/}"
            ex="${ex%/}"

            [[ -z "$ex" ]] && continue

            printf '%s\n' "$ex"

        done < "$file"
    done
}

run_backup_tar() {

    local backup_file="$1"
    shift

    local compression_cmd
    compression_cmd="$(get_compression_cmd)"

    cd /

    log_section "Loaded exclusions"

    local TAR_EXCLUDES=()

    while IFS= read -r ex; do
        log_info "Exclude: /$ex"
        TAR_EXCLUDES+=( "--exclude=$ex" )
    done < <(load_tar_excludes "$@")

    local backup_dir
    backup_dir="$(dirname "$backup_file")"
    backup_dir="${backup_dir#/}"

    log_info "Exclude: /$backup_dir"
    TAR_EXCLUDES+=( "--exclude=$backup_dir" )

    log_info "Creating archive..."

    tar -cf "$backup_file" \
        -I "$compression_cmd" \
        --one-file-system \
        --ignore-failed-read \
        "${TAR_EXCLUDES[@]}" \
        /

    log_ok "Backup complete"
}
