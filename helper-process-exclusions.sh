#!/bin/bash
# helper-process-exclusions.sh

set -euo pipefail

if [[ "$#" -lt 1 ]]; then
    echo "Usage: $0 <exclusion_file1> [exclusion_file2 ...]" >&2
    exit 1
fi

for FILE in "$@"; do

    if [[ ! -f "$FILE" ]]; then
        echo "[!] Warning: missing exclusion file: $FILE" >&2
        continue
    fi

    # informational output -> stderr ONLY
    echo "[*] Loading exclusions from: $FILE" >&2

    while IFS= read -r line || [[ -n "$line" ]]; do

        # =========================================
        # Trim whitespace
        # =========================================

        line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

        # =========================================
        # Skip comments / blanks
        # =========================================

        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # =========================================
        # Expand ~/
        # =========================================

        if [[ "$line" == "~/"* ]]; then
            line="${HOME}/${line#"~/"}"
        fi

        # =========================================
        # Convert absolute paths to tar-relative
        # =========================================

        if [[ "$line" == /* ]]; then
            line="./${line#/}"
        fi

        # =========================================
        # Output exclusion
        # =========================================

        echo "--exclude=$line"

    done < "$FILE"

done
