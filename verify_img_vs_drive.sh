#!/bin/bash
# verify_img_vs_drive.sh
# Verifies mounted .img source vs mounted target drive

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

SRC="${1:-/mnt/distro-img}"
TARGET="${2:-/media/$USER/psxitarch}"
CHECK_USER="${3:-vvsx87}"

# === VALIDATION ===

[[ -d "$SRC" ]] || \
    fatal "Source directory missing: $SRC"

[[ -d "$TARGET" ]] || \
    fatal "Target directory missing: $TARGET"

mountpoint -q "$SRC" || \
    fatal "Source is not mounted: $SRC"

mountpoint -q "$TARGET" || \
    fatal "Target is not mounted: $TARGET"

# === REPORT HEADER ===

log_section "Verification Report"

echo "Source : $SRC"
echo "Target : $TARGET"

# === ROOT LISTINGS ===

echo

log_section "Root directories (source)"
ls -lah "$SRC"

echo

log_section "Root directories (target)"
ls -lah "$TARGET"

# === PASSWD CHECK ===

echo

log_section "/etc/passwd comparison"

if [[ -f "$SRC/etc/passwd" && -f "$TARGET/etc/passwd" ]]; then

    echo "[Source]"
    grep "^$CHECK_USER:" "$SRC/etc/passwd" || echo "Not found"

    echo

    echo "[Target]"
    grep "^$CHECK_USER:" "$TARGET/etc/passwd" || echo "Not found"

else

    log_warn "Missing /etc/passwd in one or both systems"

fi

# === FILE COUNTS ===

echo

log_section "Top-level file counts"

echo "[Source]"
find "$SRC" -maxdepth 1 -type f | wc -l

echo

echo "[Target]"
find "$TARGET" -maxdepth 1 -type f | wc -l

# === /usr/lib CHECK ===

echo

log_section "/usr/lib comparison"

if [[ -d "$SRC/usr/lib" ]]; then
    ls -la "$SRC/usr/lib/"
else
    log_warn "Missing source /usr/lib"
fi

echo

if [[ -d "$TARGET/usr/lib" ]]; then
    ls -la "$TARGET/usr/lib/"
else
    log_warn "Missing target /usr/lib"
fi

# === FULL DIFF ===

echo

log_section "Full diff report"

diff -rN \
    --no-dereference \
    "$SRC" "$TARGET" || true

echo

log_ok "Verification complete"
