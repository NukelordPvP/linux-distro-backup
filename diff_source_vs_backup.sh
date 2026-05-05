#!/bin/bash
# diff_source_vs_backup.sh
# Integrity comparison between source and backup rootfs

set -euo pipefail

SRC="/media/$USER/psxitarch"
TARGET="/media/$USER/psxbackup"
CHECK_USER="vvsx87"

# === VALIDATION ===
if [ ! -d "$SRC" ]; then
    echo "[!] Source missing: $SRC"
    exit 1
fi

if [ ! -d "$TARGET" ]; then
    echo "[!] Target missing: $TARGET"
    exit 1
fi

# === ROOT LISTING ===
echo "=== Root directories (source) ==="
ls -lah "$SRC"

echo
echo "=== Root directories (backup) ==="
ls -lah "$TARGET"

# === USER CHECK ===
echo
echo "=== passwd comparison for $CHECK_USER ==="
echo "[Source]"
grep "^$CHECK_USER:" "$SRC/etc/passwd" || echo "Not found"

echo "[Backup]"
grep "^$CHECK_USER:" "$TARGET/etc/passwd" || echo "Not found"

# === LIB CHECK (no sudo needed if readable) ===
echo
echo "=== /usr/lib permissions ==="
ls -la "$SRC/usr/lib/" 2>/dev/null || echo "Missing in source"
ls -la "$TARGET/usr/lib/" 2>/dev/null || echo "Missing in backup"

# === FULL DIFF (correct + complete) ===
echo
echo "=== Full filesystem diff ==="
diff -rN "$SRC" "$TARGET" | head -n 200

echo
echo "[?] Verification complete."
