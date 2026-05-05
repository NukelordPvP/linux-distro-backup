#!/bin/bash
# mount_&_chroot.sh (auto-detect from selected sdX/nvmeX partition)

set -euo pipefail

BASE="/media/$USER"

ROOT_MOUNT="$BASE/psxitarch"
SWAP_MOUNT="$BASE/psxswap"
VFAT_MOUNT="$BASE/psxvfat"

# === SHOW CANDIDATES ===
echo "[*] Available Linux partitions:"
lsblk -rpno NAME,SIZE,FSTYPE,TYPE | awk '$4=="part" && $3 ~ /ext4|btrfs|xfs/ {print}'

# === SELECT ROOT ===
read -rp "Enter root partition (e.g. /dev/sda2): " ROOT_DEV

# === VALIDATE ===
if [[ ! -b "$ROOT_DEV" ]]; then
    echo "[!] Invalid block device: $ROOT_DEV"
    exit 1
fi

# === RESOLVE UUID ===
ROOT_UUID="$(blkid -s UUID -o value "$ROOT_DEV")"

if [[ -z "$ROOT_UUID" ]]; then
    echo "[!] Could not resolve UUID for $ROOT_DEV"
    exit 1
fi

echo "[*] Selected root: $ROOT_DEV"
echo "[*] UUID: $ROOT_UUID"

# === DISCOVER DISK ===
DISK="/dev/$(lsblk -no PKNAME "$ROOT_DEV")"
echo "[*] Base disk: $DISK"

# === OPTIONAL PARTITIONS ===
SWAP_DEV="$(lsblk -rpno NAME,FSTYPE,TYPE "$DISK" | awk '$3=="part" && $2=="swap"{print $1; exit}')"
VFAT_DEV="$(lsblk -rpno NAME,FSTYPE,TYPE "$DISK" | awk '$3=="part" && $2=="vfat"{print $1; exit}')"

SWAP_UUID=""
VFAT_UUID=""

[[ -n "$SWAP_DEV" ]] && SWAP_UUID="$(blkid -s UUID -o value "$SWAP_DEV" 2>/dev/null || true)"
[[ -n "$VFAT_DEV" ]] && VFAT_UUID="$(blkid -s UUID -o value "$VFAT_DEV" 2>/dev/null || true)"

# === CREATE MOUNTS ===
echo "[*] Creating mount points..."
sudo mkdir -p "$ROOT_MOUNT" "$SWAP_MOUNT" "$VFAT_MOUNT"
sudo mkdir -p "$ROOT_MOUNT/proc" "$ROOT_MOUNT/sys" "$ROOT_MOUNT/dev" "$ROOT_MOUNT/dev/pts"

# === CHECK DOUBLE MOUNT ===
if mountpoint -q "$ROOT_MOUNT"; then
    echo "[!] Root already mounted"
    exit 1
fi

# === CLEANUP ===
cleanup() {
    echo "[*] Cleaning up mounts..."

    sudo umount -lf "$ROOT_MOUNT/dev/pts" 2>/dev/null || true
    sudo umount -lf "$ROOT_MOUNT/dev" 2>/dev/null || true
    sudo umount -lf "$ROOT_MOUNT/proc" 2>/dev/null || true
    sudo umount -lf "$ROOT_MOUNT/sys" 2>/dev/null || true

    sudo umount -lf "$VFAT_MOUNT" 2>/dev/null || true
    sudo umount -lf "$ROOT_MOUNT" 2>/dev/null || true

    [[ -n "$SWAP_DEV" ]] && sudo swapoff "$SWAP_DEV" 2>/dev/null || true
}
trap cleanup EXIT

# === MOUNT ROOT ===
echo "[*] Mounting root..."
sudo mount "$ROOT_DEV" "$ROOT_MOUNT"

# === SWAP (optional) ===
if [[ -n "$SWAP_DEV" ]]; then
    echo "[*] Activating swap: $SWAP_DEV"
    sudo swapon "$SWAP_DEV" || true
fi

# === VFAT (optional) ===
if [[ -n "$VFAT_DEV" ]]; then
    echo "[*] Mounting VFAT: $VFAT_DEV"
    sudo mount "$VFAT_DEV" "$VFAT_MOUNT" || true
fi

# === SYSTEM BINDS ===
echo "[*] Mounting system filesystems..."
sudo mount -t proc proc "$ROOT_MOUNT/proc"
sudo mount -t sysfs sysfs "$ROOT_MOUNT/sys"
sudo mount --bind /dev "$ROOT_MOUNT/dev"
sudo mount -t devpts devpts "$ROOT_MOUNT/dev/pts"

# === VALIDATE ROOTFS ===
if [[ ! -x "$ROOT_MOUNT/bin/bash" ]]; then
    echo "[!] Invalid root filesystem (missing /bin/bash)"
    exit 1
fi

# === CHROOT ===
echo "[*] Entering chroot..."
sudo chroot "$ROOT_MOUNT" /bin/bash
