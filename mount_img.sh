#!/bin/bash
# Prompt user for .img path and mount it for verification

set -euo pipefail

MOUNT_POINT="/mnt/distro-img"

read -rp "Enter full path to the .img file: " IMG_PATH

# === VALIDATE IMAGE ===
if [[ ! -f "$IMG_PATH" ]]; then
    echo "[!] File does not exist: $IMG_PATH"
    exit 1
fi

# === CREATE MOUNT POINT ===
echo "[*] Ensuring mount point exists..."
sudo mkdir -p "$MOUNT_POINT"

# === CHECK IF ALREADY MOUNTED ===
if mountpoint -q "$MOUNT_POINT"; then
    echo "[!] Already mounted at $MOUNT_POINT"
    exit 1
fi

# === CLEANUP FUNCTION ===
cleanup() {
    echo "[*] Unmounting image..."
    sudo umount "$MOUNT_POINT" 2>/dev/null || true
}
trap cleanup EXIT

# === MOUNT IMAGE ===
echo "[*] Mounting $IMG_PATH to $MOUNT_POINT..."

sudo mount -o loop,ro "$IMG_PATH" "$MOUNT_POINT"

# === VERIFY MOUNT SUCCESS ===
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "[!] Mount failed"
    exit 1
fi

echo "[✓] Image mounted successfully at $MOUNT_POINT"
echo "[*] Ready for verification"
