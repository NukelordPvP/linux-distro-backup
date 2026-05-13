#!/bin/bash
# kill-running-backup.sh
# Force kills active distro backup jobs + optionally removes incomplete outputs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

LOCKS=(
    "/tmp/backup-fedora.lock"
    "/tmp/backup-manjaro.lock"
)

FOUND=0
KILLED_FILES=()

log_section "Searching for running backups"

# =========================================
# Kill tar backup processes
# =========================================

while IFS= read -r LINE; do

    PID="$(awk '{print $1}' <<< "$LINE")"
    CMD="$(cut -d' ' -f2- <<< "$LINE")"

    [[ -n "${PID:-}" ]] || continue

    FOUND=1

    echo
    log_warn "Found active backup process"

    echo "    PID : $PID"
    echo "    Cmd : $CMD"

    log_info "Sending SIGTERM..."
    kill "$PID" 2>/dev/null || true

    sleep 2

    if kill -0 "$PID" 2>/dev/null; then
        log_warn "Still running, sending SIGKILL..."
        kill -9 "$PID" 2>/dev/null || true
        sleep 1
    fi

    if kill -0 "$PID" 2>/dev/null; then
        log_warn "Failed to kill PID $PID"
    else
        log_ok "Killed PID $PID"
        KILLED_FILES+=("$CMD")
    fi

done < <(
    ps -eo pid,args | \
    grep -E 'tar .*\.tar\.(xz|gz|zst)' | \
    grep -v grep || true
)

# =========================================
# Cleanup stale locks
# =========================================

for LOCK in "${LOCKS[@]}"; do

    if [[ -f "$LOCK" ]]; then

        HOLDER="$(lsof -t "$LOCK" 2>/dev/null || true)"

        if [[ -z "${HOLDER:-}" ]]; then
            log_warn "Removing stale lock: $LOCK"
            rm -f "$LOCK"
        fi
    fi

done

# =========================================
# DELETE INCOMPLETE FILES (NEW)
# =========================================

if [[ "$FOUND" -eq 1 ]]; then

    echo
    log_section "Incomplete backup cleanup"

    read -rp "Delete incomplete backup files? (y/N): " CONFIRM

    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then

        echo
        log_warn "Scanning for partial backup files..."

        find . -maxdepth 1 -type f \( \
            -name "*.tar.xz" -o \
            -name "*.tar.gz" -o \
            -name "*.tar.zst" -o \
            -name "*.log" -o \
            -name "*_summary.log" \
        \) -print | while read -r FILE; do

            log_warn "Deleting: $FILE"
            rm -f "$FILE"

        done

        log_ok "Cleanup complete"

    else
        log_info "Skipped cleanup"
    fi
fi

# =========================================
# Final status
# =========================================

if [[ "$FOUND" -eq 0 ]]; then
    log_ok "No running backups found"
fi
