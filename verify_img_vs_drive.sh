#!/bin/bash
# Verifies mounted .img source vs backup directory

set -euo pipefail

SRC="${1:-/mnt/distro-img}"
TARGET="${2:-/media/$USER/psxitarch}"
CHECK_USER="${3:-vvsx87}"

# === VALIDATION ===
if [[ ! -d "$SRC" ]]; then
    echo "[!] Source not mounted: $SRC"
    exit 1
fi

if [[ ! -d "$TARGET" ]]; then
    echo "[!] Backup not mounted: $TARGET"
    exit 1
fi

if ! mountpoint -q "$SRC"; then
    echo "[!] Source is not a mountpoint: $SRC"
    exit 1
fi

if ! mountpoint -q "$TARGET"; then
    echo "[!] Target is not a mountpoint: $TARGET"
    exit 1
fi

echo "=== Verification Report ==="
echo "Source : $SRC"
echo "Backup : $TARGET"

# === ROOT LISTING ===
echo
echo "=== Root directories ==="
ls -lah "$SRC"
echo
ls -lah "$TARGET"

# === PASSWD CHECK ===
echo
echo "=== /etc/passwd comparison ==="

if [[ -f "$SRC/etc/passwd" && -f "$TARGET/etc/passwd" ]]; then
    echo "[Source]"
    grep "^$CHECK_USER:" "$SRC/etc/passwd" || echo "Not found"

    echo "[Backup]"
    grep "^$CHECK_USER:" "$TARGET/etc/passwd" || echo "Not found"
else
    echo "[!] Missing /etc/passwd in one or both systems"
fi

# === ROOT FILE COUNTS (better than du misuse) ===
echo
echo "=== File counts (top-level) ==="

echo "[Source]"
find "$SRC" -maxdepth 1 -type f | wc -l

echo "[Backup]"
find "$TARGET" -maxdepth 1 -type f | wc -l

# === /usr/lib CHECK ===
echo
echo "=== /usr/lib comparison ==="

[[ -d "$SRC/usr/lib" ]] && ls -la "$SRC/usr/lib/" || echo "Missing source /usr/lib"
[[ -d "$TARGET/usr/lib" ]] && ls -la "$TARGET/usr/lib/" || echo "Missing backup /usr/lib"

# === DIFFERENCE REPORT (FULL, NO FILTERING) ===
echo
echo "=== Full diff report ==="
diff -rN "$SRC" "$TARGET" || true

echo
echo "[✓] Verification complete"
