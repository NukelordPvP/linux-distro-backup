#!/bin/bash
# mount-and-chroot.sh
# Auto-detect from selected sdX/nvmeX partition

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

BASE="/media/$USER"

ROOT_MOUNT="$BASE/psxitarch"
SWAP_MOUNT="$BASE/psxswap"
VFAT_MOUNT="$BASE/psxvfat"

# === SHOW CANDIDATES ===

log_section "Available Linux partitions"

lsblk -rpno NAME,SIZE,FSTYPE,TYPE | \
    awk '$4=="part" && $3 ~ /ext4|btrfs|xfs/ {print}'

# === SELECT ROOT ===

read -rp "Enter root partition (e.g. /dev/sda2): " ROOT_DEV

# === VALIDATE ===

[[ -b "$ROOT_DEV" ]] || fatal "Invalid block device: $ROOT_DEV"

# === RESOLVE UUID ===

ROOT_UUID="$(blkid -s UUID -o value "$ROOT_DEV")"

[[ -n "$ROOT_UUID" ]] || \
    fatal "Could not resolve UUID for $ROOT_DEV"

log_info "Selected root: $ROOT_DEV"
log_info "UUID: $ROOT_UUID"

# === DISCOVER DISK ===

DISK="/dev/$(lsblk -no PKNAME "$ROOT_DEV")"

log_info "Base disk: $DISK"

# === OPTIONAL PARTITIONS ===

SWAP_DEV="$(lsblk -rpno NAME,FSTYPE,TYPE "$DISK" | \
    awk '$3=="part" && $2=="swap"{print $1; exit}')"

VFAT_DEV="$(lsblk -rpno NAME,FSTYPE,TYPE "$DISK" | \
    awk '$3=="part" && $2=="vfat"{print $1; exit}')"

# === CREATE MOUNTS ===

log_info "Creating mount points..."

sudo mkdir -p \
    "$ROOT_MOUNT" \
    "$SWAP_MOUNT" \
    "$VFAT_MOUNT"

sudo mkdir -p \
    "$ROOT_MOUNT/proc" \
    "$ROOT_MOUNT/sys" \
    "$ROOT_MOUNT/dev" \
    "$ROOT_MOUNT/dev/pts"

# === CHECK DOUBLE MOUNT ===

mountpoint -q "$ROOT_MOUNT" && \
    fatal "Root already mounted"

# === CLEANUP ===

cleanup() {

    log_info "Cleaning up mounts..."

    sudo umount -lf "$ROOT_MOUNT/dev/pts" 2>/dev/null || true
    sudo umount -lf "$ROOT_MOUNT/dev" 2>/dev/null || true
    sudo umount -lf "$ROOT_MOUNT/proc" 2>/dev/null || true
    sudo umount -lf "$ROOT_MOUNT/sys" 2>/dev/null || true

    sudo umount -lf "$VFAT_MOUNT" 2>/dev/null || true
    sudo umount -lf "$ROOT_MOUNT" 2>/dev/null || true

    [[ -n "${SWAP_DEV:-}" ]] && \
        sudo swapoff "$SWAP_DEV" 2>/dev/null || true
}

trap cleanup EXIT

# === MOUNT ROOT ===

log_info "Mounting root filesystem..."

sudo mount "$ROOT_DEV" "$ROOT_MOUNT"

mountpoint -q "$ROOT_MOUNT" || \
    fatal "Failed to mount root filesystem"

log_ok "Root mounted successfully"

# === SWAP ===

if [[ -n "${SWAP_DEV:-}" ]]; then

    log_info "Activating swap: $SWAP_DEV"

    sudo swapon "$SWAP_DEV" || \
        log_warn "Failed to activate swap"

fi

# === VFAT ===

if [[ -n "${VFAT_DEV:-}" ]]; then

    log_info "Mounting VFAT partition: $VFAT_DEV"

    sudo mount "$VFAT_DEV" "$VFAT_MOUNT" || \
        log_warn "Failed to mount VFAT partition"

fi

# === SYSTEM BINDS ===

log_info "Mounting system filesystems..."

sudo mount -t proc proc "$ROOT_MOUNT/proc"
sudo mount -t sysfs sysfs "$ROOT_MOUNT/sys"
sudo mount --bind /dev "$ROOT_MOUNT/dev"
sudo mount -t devpts devpts "$ROOT_MOUNT/dev/pts"

# === VALIDATE ROOTFS ===

[[ -x "$ROOT_MOUNT/bin/bash" ]] || \
    fatal "Invalid root filesystem (missing /bin/bash)"

# === CHROOT ===

log_ok "Entering chroot..."

sudo chroot "$ROOT_MOUNT" /bin/bash
