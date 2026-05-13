#!/bin/bash

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
# EXCLUSIONS (DATA ONLY)
# =========================

load_tar_excludes() {

    local file ex

    for file in "$@"; do
        [[ -f "$file" ]] || continue

        while IFS= read -r ex || [[ -n "$ex" ]]; do

            ex="${ex#"${ex%%[![:space:]]*}"}"
            ex="${ex%"${ex##*[![:space:]]}"}"

            [[ -z "$ex" ]] && continue
            [[ "${ex:0:1}" == "#" ]] && continue

            # expand ~
            [[ "$ex" == "~"* ]] && ex="${ex/#\~/$HOME}"

            # normalize for tar
            ex="${ex#/}"
            ex="${ex%/}"

            [[ -z "$ex" ]] && continue

            printf '%s\n' "$ex"

        done < "$file"
    done
}

# =========================
# BACKUP ENGINE (HARD VALIDATION)
# =========================

run_backup_tar() {

    local backup_file="$1"
    shift

    # -------------------------
    # VALIDATE OUTPUT PATH
    # -------------------------
    if [[ -z "$backup_file" ]]; then
        fatal "Backup file is empty"
    fi

    local compression_cmd
    compression_cmd="$(get_compression_cmd)"

    log_info "Compression: $compression_cmd"
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
        "${BACKUP_TAR_ARGS[@]}" \
        "${TAR_EXCLUDES[@]}" \
        /

    local rc=$?

    if [[ $rc -ne 0 ]]; then
        fatal "tar failed with exit code $rc"
    fi

    # -------------------------
    # VERIFY OUTPUT
    # -------------------------
    if [[ ! -f "$backup_file" ]]; then
        fatal "Backup file was NOT created: $backup_file"
    fi

    log_ok "Backup complete: $backup_file"
}
