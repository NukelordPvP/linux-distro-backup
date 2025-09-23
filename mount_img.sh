#!/bin/bash
# Prompt user for .img path and mount it for verification

set -euo pipefail

# Default mount point (matches verification script)
MOUNT_POINT="/mnt/distro-img"

# Prompt user for .img file path
read -rp "Enter full path to the .img file: " IMG_PATH

# Check if file exists
if [ ! -f "$IMG_PATH" ]; then
echo "[!] File does not exist: $IMG_PATH"
exit 1
fi

# Create mount point if it doesn't exist
echo "[*] Creating mount point at $MOUNT_POINT..."
sudo mkdir -p "$MOUNT_POINT"

# Mount the .img file
echo "[*] Mounting $IMG_PATH to $MOUNT_POINT..."
sudo mount -o loop "$IMG_PATH" "$MOUNT_POINT"
