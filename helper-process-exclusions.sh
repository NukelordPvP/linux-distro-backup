#!/bin/bash

set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <exclusion_file1> [exclusion_file2 ...]"
    exit 1
fi

for FILE in "$@"; do
    if [ ! -f "$FILE" ]; then
        echo "[!] Warning: missing exclusion file: $FILE" >&2
        continue
    fi

    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        CLEAN="${line#/}"
        echo "--exclude=$CLEAN"

    done < "$FILE"
done
