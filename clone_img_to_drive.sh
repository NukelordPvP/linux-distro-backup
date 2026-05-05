#!/bin/bash
# clone_img_to_drive.sh
# Mount .img, then copy its contents to mounted drive safely

set -euo pipefail

MOUNT_POINT="/mnt/distro-img"
TARGET="/media/$USER/psxitarch"

read -rp "Enter full path to the .img file: " IMG_PATH

if [ ! -f "$IMG_PATH" ]; then
    echo "[!] File does not exist: $IMG_PATH"
    exit 1
fi

if [ ! -d "$TARGET" ]; then
    echo "[!] Target does not exist: $TARGET"
    exit 1
fi

sudo mkdir -p "$MOUNT_POINT"

cleanup() {
    echo "[*] Cleaning up..."
    sudo umount "$MOUNT_POINT" 2>/dev/null || true
}
trap cleanup EXIT

echo "[*] Mounting image..."
sudo mount -o loop "$IMG_PATH" "$MOUNT_POINT"

echo "[*] Copying files to $TARGET..."

sudo rsync -aAXHv --numeric-ids --info=progress2 \
    --exclude=dev/ \
    --exclude=proc/ \
    --exclude=sys/ \
    --exclude=var/cache/ \
    "$MOUNT_POINT/" "$TARGET/"

echo "[✓] Copy complete"
