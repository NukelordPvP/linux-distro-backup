#!/bin/bash
# mount-img.sh
# Prompt user for .img path and mount it for verification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

MOUNT_POINT="/mnt/distro-img"

read -rp "Enter full path to the .img file: " IMG_PATH

# === VALIDATE IMAGE ===

[[ -f "$IMG_PATH" ]] || \
    fatal "File does not exist: $IMG_PATH"

# === CREATE MOUNT POINT ===

log_info "Ensuring mount point exists..."

sudo mkdir -p "$MOUNT_POINT"

# === CHECK IF ALREADY MOUNTED ===

mountpoint -q "$MOUNT_POINT" && \
    fatal "Already mounted at $MOUNT_POINT"

# === CLEANUP ===

cleanup() {

    log_info "Unmounting image..."

    sudo umount "$MOUNT_POINT" 2>/dev/null || true
}

trap cleanup EXIT

# === MOUNT IMAGE ===

log_info "Mounting image..."

log_info "Image : $IMG_PATH"
log_info "Target: $MOUNT_POINT"

sudo mount -o loop,ro "$IMG_PATH" "$MOUNT_POINT"

# === VERIFY MOUNT SUCCESS ===

mountpoint -q "$MOUNT_POINT" || \
    fatal "Mount failed"

log_ok "Image mounted successfully"
log_info "Ready for verification"
