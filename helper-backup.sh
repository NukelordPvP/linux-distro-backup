#!/bin/bash
# helper-backup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helper-logging.sh"

# =========================
# CONFIG
# =========================

BACKUP_COMPRESSION="${BACKUP_COMPRESSION:-xz}"
BACKUP_COMPRESSION_LEVEL="${BACKUP_COMPRESSION_LEVEL:-9}"

BACKUP_TAR_ARGS=(
    --one-file-system
    --ignore-failed-read
)

# =========================
# COMPRESSION
# =========================

get_compression_cmd() {
    case "$BACKUP_COMPRESSION" in
        xz) echo "xz -${BACKUP_COMPRESSION_LEVEL}" ;;
        gzip) echo "gzip -${BACKUP_COMPRESSION_LEVEL}" ;;
        zstd) echo "zstd -${BACKUP_COMPRESSION_LEVEL}" ;;
        *) fatal "Unsupported compression: $BACKUP_COMPRESSION" ;;
    esac
}

# =========================
# EXCLUSION LOADER (clean + correct)
# =========================

load_tar_excludes() {

    local file ex expanded normalized

    for file in "$@"; do
        [[ -f "$file" ]] || continue

        while IFS= read -r ex || [[ -n "$ex" ]]; do

            # trim whitespace
            ex="${ex#"${ex%%[![:space:]]*}"}"
            ex="${ex%"${ex##*[![:space:]]}"}"

            [[ -z "$ex" ]] && continue
            [[ "${ex:0:1}" == "#" ]] && continue

            # =========================
            # expand ~
            # =========================
            if [[ "$ex" == "~"* ]]; then
                expanded="${ex/#\~/$HOME}"
            else
                expanded="$ex"
            fi

            # =========================
            # normalize for tar
            # =========================
            expanded="${expanded#/}"
            expanded="${expanded%/}"

            [[ -z "$expanded" ]] && continue

            normalized="$expanded"

            # =========================
            # log ONLY final form
            # =========================
            log_info "Exclude: /$normalized"

            # =========================
            # output ONLY tool-ready value
            # =========================
            printf -- "--exclude=%s\n" "$normalized"

        done < "$file"
    done
}

# =========================
# BACKUP ENGINE
# =========================

run_backup_tar() {

    local backup_file="$1"
    shift

    local compression_cmd
    compression_cmd="$(get_compression_cmd)"

    log_info "Compression: $compression_cmd"
    cd /

    log_section "Loaded exclusions"

    local TAR_EXCLUDES=()

    while IFS= read -r ex; do
        TAR_EXCLUDES+=( "$ex" )
    done < <(load_tar_excludes "$@")

    # always exclude backup directory
    local backup_dir
    backup_dir="$(dirname "$backup_file")"
    backup_dir="${backup_dir#/}"

    log_info "Exclude: /$backup_dir"
    TAR_EXCLUDES+=( "--exclude=$backup_dir" )

    log_info "Creating archive..."

    tar -cf "$backup_file" \
        -I "$compression_cmd" \
        "${BACKUP_TAR_ARGS[@]}" \
        "${TAR_EXCLUDES[@]}" \
        /

    log_ok "Backup complete: $backup_file"
}
