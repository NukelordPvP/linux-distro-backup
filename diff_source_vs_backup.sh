#!/bin/bash
# diff_source_vs_backup.sh
# Verify integrity between original cloned root and backup extracted to a separate drive

set -euo pipefail

# === CONFIGURE PATHS ===
SRC="/media/$USER/psxitarch"      # Original cloned root
TARGET="/media/$USER/psxbackup"   # Backup extracted to separate drive

# User to check in passwd
CHECK_USER="vvsx87"

# === ROOT DIRECTORY LISTING ===
echo "=== Root directories and permissions ==="
echo "[Original Source] $SRC:"
ls -lah "$SRC"
echo "[Backup Target] $TARGET:"
ls -lah "$TARGET"

# === /etc/passwd COMPARISON ===
echo
echo "=== Comparing passwd entries for user $CHECK_USER ==="
echo "[Original Source] $SRC/etc/passwd:"
grep "^$CHECK_USER:" "$SRC/etc/passwd" || echo "User $CHECK_USER not found in source"
echo "[Backup Target] $TARGET/etc/passwd:"
grep "^$CHECK_USER:" "$TARGET/etc/passwd" || echo "User $CHECK_USER not found in backup"

# === ROOT FILES SIZE ===
echo
echo "=== Checking root file sizes (top-level) ==="
echo "[Original Source] $SRC:"
sudo find "$SRC" -maxdepth 1 -type f -exec du -ch {} + | grep total$ || echo "No files in source root"
echo "[Backup Target] $TARGET:"
sudo find "$TARGET" -maxdepth 1 -type f -exec du -ch {} + | grep total$ || echo "No files in backup root"

# === /usr/lib/ PERMISSIONS ===
echo
echo "=== /usr/lib/ permissions ==="
echo "[Original Source] $SRC/usr/lib/:"
sudo ls -la "$SRC/usr/lib/" || echo "Missing /usr/lib in source"
echo "[Backup Target] $TARGET/usr/lib/:"
sudo ls -la "$TARGET/usr/lib/" || echo "Missing /usr/lib in backup"

# === DIFF CHECK ===
echo
echo "=== Differences ==="
echo "[Only in Original Source]:"
sudo diff -rq "$SRC" "$TARGET" 2>/dev/null | grep "^Only in $SRC" || echo "No differences found in source only"

echo "[Only in Backup Target]:"
sudo diff -rq "$SRC" "$TARGET" 2>/dev/null | grep "^Only in $TARGET" || echo "No differences found in backup only"

echo
echo "[?] Verification complete."
