#!/bin/bash
# Combines exclusion lists and outputs tar-compatible --exclude arguments

set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <exclusion_file1> [exclusion_file2 ...]"
    exit 1
fi

EXCLUDES=()

for FILE in "$@"; do
    if [ ! -f "$FILE" ]; then
        echo "[!] Warning: Exclusion file not found: $FILE" >&2
        continue
    fi

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Remove leading slash for consistency
        CLEAN="${line#/}"

        EXCLUDES+=("--exclude=$CLEAN")
    done < "$FILE"
done

# Output as space-separated string (for safe array usage)
echo "${EXCLUDES[@]}"
