#!/bin/bash
# diff-source-vs-backup.sh
# Integrity comparison between source and backup rootfs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

SRC="/media/$USER/psxitarch"
TARGET="/media/$USER/psxbackup"
CHECK_USER="vvsx87"

# === VALIDATION ===

[[ -d "$SRC" ]] || fatal "Source missing: $SRC"
[[ -d "$TARGET" ]] || fatal "Target missing: $TARGET"

# === ROOT LISTING ===

log_section "Root directories (source)"
ls -lah "$SRC"

echo

log_section "Root directories (backup)"
ls -lah "$TARGET"

# === USER CHECK ===

echo

log_section "passwd comparison for $CHECK_USER"

echo "[Source]"
grep "^$CHECK_USER:" "$SRC/etc/passwd" || echo "Not found"

echo

echo "[Backup]"
grep "^$CHECK_USER:" "$TARGET/etc/passwd" || echo "Not found"

# === LIB CHECK ===

echo

log_section "/usr/lib permissions"

ls -la "$SRC/usr/lib/" 2>/dev/null || log_warn "Missing in source"
echo
ls -la "$TARGET/usr/lib/" 2>/dev/null || log_warn "Missing in backup"

# === FULL DIFF ===

echo

log_section "Full filesystem diff"

diff -rN \
    --no-dereference \
    "$SRC" "$TARGET" | head -n 200 || true

echo

log_ok "Verification complete"
