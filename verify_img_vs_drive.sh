#!/bin/bash
# Verifies a mounted .img source against a backup directory
# Assumes both paths are already mounted and accessible

set -euo pipefail

# === CONFIGURE PATHS ===
SRC="${1:-/mnt/distro-img}"                 # Path to mounted source .img
TARGET="${2:-/media/$USER/psxitarch}"       # Path to mounted backup
CHECK_USER="${3:-vvsx87}"                   # Optional user to check in /etc/passwd

# Validate paths
if [ ! -d "$SRC" ]; then
echo "[!] Source path $SRC does not exist. Mount the .img first."
exit 1
fi
if [ ! -d "$TARGET" ]; then
echo "[!] Backup path $TARGET does not exist. Mount the backup first."
exit 1
fi

echo "=== Verifying mounted .img source vs backup ==="
echo "Source: $SRC"
echo "Backup: $TARGET"

# === Root directory listing ===
echo
echo "=== Root directories and permissions ==="
echo "[Source] $SRC:"
ls -lah "$SRC"
echo "[Backup] $TARGET:"
ls -lah "$TARGET"

# === Compare /etc/passwd for the user ===
if [ -n "$CHECK_USER" ]; then
echo
echo "=== Comparing /etc/passwd entries for user $CHECK_USER ==="
echo "[Source] $SRC/etc/passwd:"
grep "^$CHECK_USER:" "$SRC/etc/passwd" || echo "User $CHECK_USER not found in source"
echo "[Backup] $TARGET/etc/passwd:"
grep "^$CHECK_USER:" "$TARGET/etc/passwd" || echo "User $CHECK_USER not found in backup"
fi

# === Top-level file sizes ===
echo
echo "=== Top-level file sizes ==="
echo "[Source] $SRC:"
sudo find "$SRC" -maxdepth 1 -type f -exec du -ch {} + | grep total$ || echo "No top-level files in source"
echo "[Backup] $TARGET:"
sudo find "$TARGET" -maxdepth 1 -type f -exec du -ch {} + | grep total$ || echo "No top-level files in backup"

# === /usr/lib/ permissions ===
if [ -d "$SRC/usr/lib" ] && [ -d "$TARGET/usr/lib" ]; then
echo
echo "=== /usr/lib/ permissions ==="
echo "[Source] $SRC/usr/lib/:"
sudo ls -la "$SRC/usr/lib/" || echo "Cannot list source /usr/lib"
echo "[Backup] $TARGET/usr/lib/:"
sudo ls -la "$TARGET/usr/lib/" || echo "Cannot list backup /usr/lib"
fi

# === Differences ===
echo
echo "=== Differences ==="
echo "[Only in Source]:"
sudo diff -rq "$SRC" "$TARGET" 2>/dev/null | grep "^Only in $SRC" || echo "No differences found only in source"

echo "[Only in Backup]:"
sudo diff -rq "$SRC" "$TARGET" 2>/dev/null | grep "^Only in $TARGET" || echo "No differences found only in backup"

echo
echo "[?] Verification complete."
