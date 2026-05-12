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

    while IFS= read -r line || [ -n "$line" ]; do

        # Trim whitespace
        line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

        # Skip comments/blank lines
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Expand ~/
        if [[ "$line" == ~/* ]]; then
            line="${HOME}/${line#~/}"
        fi

        # Convert absolute path to tar-style relative path
        if [[ "$line" == /* ]]; then
            line="./${line#/}"
        fi

        echo "--exclude=$line"

    done < "$FILE"
done
