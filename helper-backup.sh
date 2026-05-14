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
        xz)   echo "xz -${BACKUP_COMPRESSION_LEVEL}" ;;
        gzip) echo "gzip -${BACKUP_COMPRESSION_LEVEL}" ;;
        zstd) echo "zstd -${BACKUP_COMPRESSION_LEVEL}" ;;
        *) fatal "Unsupported compression: $BACKUP_COMPRESSION" ;;
    esac
}

# =========================
# EXCLUSIONS
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

            local REAL_HOME
            REAL_HOME="$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)"

            [[ "$ex" == "~"* ]] && ex="${ex/#\~/$REAL_HOME}"

            ex="${ex#/}"
            ex="${ex%/}"

            [[ -z "$ex" ]] && continue

            printf '%s\n' "$ex"

        done < "$file"
    done
}

# =========================
# BACKUP ENGINE
# =========================

run_backup_tar() {

    local backup_file="$1"
    shift

    [[ -n "$backup_file" ]] || fatal "Backup file is empty"

    local REAL_USER
    local REAL_GROUP

    REAL_USER="${SUDO_USER:-$USER}"
    REAL_GROUP="$(id -gn "$REAL_USER")"

    local compression_cmd
    compression_cmd="$(get_compression_cmd)"

    log_info "Compression: $compression_cmd"

    cd /

    log_section "Loaded exclusions"

    local TAR_EXCLUDES=()
    local EXCLUDED_COUNT=0

    while IFS= read -r ex; do

        log_info "Exclude: /$ex"

        TAR_EXCLUDES+=( "--exclude=$ex" )

        ((++EXCLUDED_COUNT))

    done < <(load_tar_excludes "$@")

    local backup_dir
    backup_dir="$(dirname "$backup_file")"
    backup_dir="${backup_dir#/}"

    TAR_EXCLUDES+=( "--exclude=$backup_dir" )

    log_info "Exclude: /$backup_dir"

    ((++EXCLUDED_COUNT))

    # =========================
    # SUMMARY PRE-STATS
    # =========================

    summary_info "Backup Started: $(date)"
    summary_info "Archive: $backup_file"
    summary_info "Compression: $BACKUP_COMPRESSION -${BACKUP_COMPRESSION_LEVEL}"
    summary_info "Excluded Paths: $EXCLUDED_COUNT"

    log_info "Counting filesystem entries..."

    local TOTAL_FILES
    TOTAL_FILES="$(find / -xdev 2>/dev/null | wc -l)"

    summary_info "Filesystem Entries Scanned: $TOTAL_FILES"

    # =========================
    # TAR EXECUTION
    # =========================

    log_info "Creating archive..."

    local TAR_STDERR
    TAR_STDERR="$(mktemp)"

    tar -cvf "$backup_file" \
        -I "$compression_cmd" \
        "${BACKUP_TAR_ARGS[@]}" \
        "${TAR_EXCLUDES[@]}" \
        / \
        2> "$TAR_STDERR"

    local rc=$?

    if [[ $rc -ne 0 ]]; then

        cat "$TAR_STDERR" >&2

        rm -f "$TAR_STDERR"

        fatal "tar failed with exit code $rc"
    fi

    # =========================
    # VERIFY
    # =========================

    [[ -f "$backup_file" ]] || fatal "Backup file was NOT created"

    # =========================
    # STATS
    # =========================

    local FILE_SIZE
    FILE_SIZE="$(du -h "$backup_file" | awk '{print $1}')"

    local FILE_COUNT
    FILE_COUNT="$(tar -tf "$backup_file" 2>/dev/null | wc -l)"

    local WARNING_COUNT
    WARNING_COUNT="$(grep -ci "warning" "$TAR_STDERR" || true)"

    local ERROR_COUNT
    ERROR_COUNT="$(grep -ci "error" "$TAR_STDERR" || true)"

    summary_ok "Backup Completed: $(date)"
    summary_info "Archive Size: $FILE_SIZE"
    summary_info "Archived Entries: $FILE_COUNT"
    summary_info "Excluded Paths: $EXCLUDED_COUNT"
    summary_warn "Warnings: $WARNING_COUNT"
    summary_error "Errors: $ERROR_COUNT"

    rm -f "$TAR_STDERR"

    # =========================
    # FIX OWNERSHIP
    # =========================

    chown "$REAL_USER:$REAL_GROUP" \
        "$backup_file" \
        "$LOG_FILE" \
        "$SUMMARY_LOG" 2>/dev/null || true

    log_ok "Backup complete: $backup_file"
}
