#!/bin/bash
# Unpack a distro tar.xz archive into a mounted drive

set -euo pipefail

# Prompt for tar.xz path
read -rp "Enter path to the distro tar.xz archive: " TAR_PATH

# Check if tar file exists
if [[ ! -f "$TAR_PATH" ]]; then
echo "[!] File not found: $TAR_PATH"
exit 1
fi

# Default target uses current user
DEFAULT_MNT="/media/$USER/psxitarch"

# Check for default psxitarch mount
if [[ -d "$DEFAULT_MNT" ]]; then
TARGET_MNT="$DEFAULT_MNT"
echo "[*] Found psxitarch mount: $TARGET_MNT"
else
read -rp "psxitarch mount not found. Enter target mount point: " TARGET_MNT
if [[ ! -d "$TARGET_MNT" ]]; then
echo "[!] Mount point not found: $TARGET_MNT"
exit 1
fi
fi

# Confirm with user
echo "About to extract:"
echo "  Archive: $TAR_PATH"
echo "  Target : $TARGET_MNT"
read -rp "Proceed? (y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || exit 1

# Extract with tar
echo "[*] Extracting $TAR_PATH to $TARGET_MNT..."
sudo tar -xvJpf "$TAR_PATH" -C "$TARGET_MNT" --numeric-owner

echo "[+] Extraction complete."
