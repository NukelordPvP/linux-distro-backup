#!/bin/bash
# clone-img-to-drive.sh
# Mount .img, then copy its contents to mounted drive safely

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

MOUNT_POINT="/mnt/distro-img"
TARGET="/media/$USER/psxitarch"

read -rp "Enter full path to the .img file: " IMG_PATH

if [[ ! -f "$IMG_PATH" ]]; then
    fatal "File does not exist: $IMG_PATH"
fi

if [[ ! -d "$TARGET" ]]; then
    fatal "Target does not exist: $TARGET"
fi

log_info "Ensuring mount point exists..."
sudo mkdir -p "$MOUNT_POINT"

if mountpoint -q "$MOUNT_POINT"; then
    fatal "Mount point already in use: $MOUNT_POINT"
fi

cleanup() {

    log_info "Cleaning up..."

    sudo umount "$MOUNT_POINT" 2>/dev/null || true
}

trap cleanup EXIT

log_info "Mounting image..."

sudo mount -o loop "$IMG_PATH" "$MOUNT_POINT"

if ! mountpoint -q "$MOUNT_POINT"; then
    fatal "Failed to mount image"
fi

log_ok "Image mounted successfully"

log_section "Starting rsync clone"

log_info "Source : $MOUNT_POINT"
log_info "Target : $TARGET"

sudo rsync -aAXH --numeric-ids --info=progress2 \
    --exclude=dev/ \
    --exclude=proc/ \
    --exclude=sys/ \
    --exclude=tmp/ \
    --exclude=run/ \
    --exclude=mnt/ \
    --exclude=media/ \
    --exclude=lost+found/ \
    --exclude=var/cache/ \
    "$MOUNT_POINT/" "$TARGET/"

log_ok "Clone complete"
