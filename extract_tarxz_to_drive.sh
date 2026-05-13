#!/bin/bash
# extract_tarxz_to_drive.sh
# Unpack a distro tar.xz archive into a mounted drive safely

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

read -rp "Enter path to the distro tar.xz archive: " TAR_PATH

[[ -f "$TAR_PATH" ]] || fatal "File not found: $TAR_PATH"

DEFAULT_MNT="/media/$USER/psxitarch"

if mountpoint -q "$DEFAULT_MNT"; then

    TARGET_MNT="$DEFAULT_MNT"

    log_ok "Found mounted psxitarch: $TARGET_MNT"

else

    read -rp "Enter valid mounted target directory: " TARGET_MNT

    [[ -d "$TARGET_MNT" ]] || fatal "Target does not exist: $TARGET_MNT"

    mountpoint -q "$TARGET_MNT" || \
        fatal "Target is not a mounted filesystem: $TARGET_MNT"

fi

log_section "Extraction confirmation"

echo "Archive : $TAR_PATH"
echo "Target  : $TARGET_MNT"

read -rp "Proceed? (y/N): " CONFIRM

[[ "$CONFIRM" =~ ^[Yy]$ ]] || {
    log_warn "Extraction cancelled"
    exit 1
}

log_info "Starting extraction..."

sudo tar -xpf "$TAR_PATH" \
    -I "xz -9" \
    -C "$TARGET_MNT" \
    --numeric-owner \
    --warning=no-timestamp

log_ok "Extraction complete"
