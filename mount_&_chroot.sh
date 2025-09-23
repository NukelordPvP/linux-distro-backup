#!/bin/bash
# mount_&_chroot.sh
# Script to mount partitions and chroot into a cloned Linux root filesystem

set -euo pipefail

# Change these UUIDs to match your system
ROOT_UUID="52ab6e70-758a-4ed3-ada5-5e086a3ce7ae"
SWAP_UUID="068e0e11-0403-4847-bf22-73dfb7efac1b"
VFAT_UUID="AA7B-B809"

# Base mount point (user-specific)
BASE="/media/$USER"

# Mount points
ROOT_MOUNT="$BASE/psxitarch"
SWAP_MOUNT="$BASE/psxswap"
VFAT_MOUNT="$BASE/psxvfat"

# Create directories
echo "[*] Creating mount points..."
sudo mkdir -p "$ROOT_MOUNT" "$SWAP_MOUNT" "$VFAT_MOUNT"
sudo mkdir -p "$ROOT_MOUNT/proc" "$ROOT_MOUNT/sys" "$ROOT_MOUNT/dev" "$ROOT_MOUNT/dev/pts"

# Mount partitions
echo "[*] Mounting partitions..."
sudo mount UUID="$ROOT_UUID" "$ROOT_MOUNT"
sudo mount UUID="$SWAP_UUID" "$SWAP_MOUNT"
sudo mount UUID="$VFAT_UUID" "$VFAT_MOUNT"

# Mount special filesystems
echo "[*] Mounting special filesystems..."
sudo mount -t proc proc "$ROOT_MOUNT/proc"
sudo mount -t sysfs sysfs "$ROOT_MOUNT/sys"
sudo mount --bind /dev "$ROOT_MOUNT/dev"
sudo mount -t devpts devpts "$ROOT_MOUNT/dev/pts"

# Chroot into the new system
echo "[*] Entering chroot..."
sudo chroot "$ROOT_MOUNT" /bin/bash
