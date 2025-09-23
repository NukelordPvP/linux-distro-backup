#!/bin/bash
# clone_img_to_drive.sh
# Mount .img, then copy its contents to empty mounted drive

set -euo pipefail

MOUNT_POINT="/mnt/distro-img"
TARGET="/media/$USER/psxitarch"

# Prompt for .img file path
read -rp "Enter full path to the .img file: " IMG_PATH

# Validate .img file
if [ ! -f "$IMG_PATH" ]; then
echo "[!] File does not exist: $IMG_PATH"
exit 1
fi

# Create mount point if missing
sudo mkdir -p "$MOUNT_POINT"

# Mount image
echo "[*] Mounting $IMG_PATH at $MOUNT_POINT..."
sudo mount -o loop "$IMG_PATH" "$MOUNT_POINT"

# Change to mount point
cd "$MOUNT_POINT"

# Rsync copy
echo "[*] Copying files to $TARGET..."
sudo rsync -aAXHv --numeric-ids --info=progress2 \
--exclude=dev/ --exclude=proc/ --exclude=sys/ --exclude=var/cache/ \
./ "$TARGET/"

# Unmount afterwards
echo "[*] Unmounting $MOUNT_POINT..."
sudo umount "$MOUNT_POINT"

echo "[?] Copy complete and unmounted successfully!"
