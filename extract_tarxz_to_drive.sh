#!/bin/bash
# Unpack a distro tar.xz archive into a mounted drive safely

set -euo pipefail

read -rp "Enter path to the distro tar.xz archive: " TAR_PATH

if [[ ! -f "$TAR_PATH" ]]; then
    echo "[!] File not found: $TAR_PATH"
    exit 1
fi

DEFAULT_MNT="/media/$USER/psxitarch"

if [[ -d "$DEFAULT_MNT" && $(mountpoint -q "$DEFAULT_MNT"; echo $?) -eq 0 ]]; then
    TARGET_MNT="$DEFAULT_MNT"
    echo "[*] Found mounted psxitarch: $TARGET_MNT"
else
    read -rp "Enter valid mounted target directory: " TARGET_MNT
    if [[ ! -d "$TARGET_MNT" ]]; then
        echo "[!] Target does not exist: $TARGET_MNT"
        exit 1
    fi
fi

echo "About to extract:"
echo "  Archive: $TAR_PATH"
echo "  Target : $TARGET_MNT"
read -rp "Proceed? (y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || exit 1

echo "[*] Extracting..."

sudo tar -xJpf "$TAR_PATH" \
    -C "$TARGET_MNT" \
    --numeric-owner \
    --warning=no-timestamp

echo "[+] Extraction complete."
