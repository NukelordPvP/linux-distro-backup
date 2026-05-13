#!/bin/bash
# kill-running-backup.sh
# Stops active distro backup jobs safely

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

LOCKS=(
    "/tmp/backup-fedora.lock"
    "/tmp/backup-manjaro.lock"
)

FOUND=0

log_section "Searching for running backups"

# =========================================
# Lock-based detection
# =========================================

for LOCK in "${LOCKS[@]}"; do

    [[ -f "$LOCK" ]] || continue

    PID="$(lsof -t "$LOCK" 2>/dev/null | head -n 1 || true)"

    [[ -n "${PID:-}" ]] || continue

    FOUND=1

    CMD="$(ps -p "$PID" -o cmd= 2>/dev/null || true)"

    log_warn "Found backup lock"

    echo "    PID : $PID"
    echo "    Lock: $LOCK"
    echo "    Cmd : $CMD"

    read -rp "Kill this process? (y/N): " CONFIRM

    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then

        log_info "Stopping PID $PID..."

        kill "$PID" 2>/dev/null || true

        sleep 2

        if kill -0 "$PID" 2>/dev/null; then

            log_warn "Process still alive, sending SIGKILL..."

            kill -9 "$PID"

        fi

        log_ok "Process stopped"

    fi

done

# =========================================
# tar/xz fallback detection
# =========================================

while IFS= read -r LINE; do

    PID="$(awk '{print $1}' <<< "$LINE")"

    CMD="$(cut -d' ' -f2- <<< "$LINE")"

    [[ -n "$PID" ]] || continue

    FOUND=1

    echo
    log_warn "Found active tar/xz backup process"

    echo "    PID : $PID"
    echo "    Cmd : $CMD"

    read -rp "Kill this process? (y/N): " CONFIRM

    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then

        log_info "Stopping PID $PID..."

        kill "$PID" 2>/dev/null || true

        sleep 2

        if kill -0 "$PID" 2>/dev/null; then

            log_warn "Process still alive, sending SIGKILL..."

            kill -9 "$PID"

        fi

        log_ok "Process stopped"

    fi

done < <(
    ps -eo pid,args | grep -E 'tar .*\.tar\.(xz|gz|zst)' | grep -v grep || true
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
# Final status
# =========================================

if [[ "$FOUND" -eq 0 ]]; then
    log_ok "No running backups found"
fi
