#!/bin/bash

set -euo pipefail

if [[ "$#" -lt 1 ]]; then
    echo "Usage: $0 <exclusion_file1> [exclusion_file2 ...]" >&2
    exit 1
fi

for FILE in "$@"; do

    [[ -f "$FILE" ]] || {
        echo "[!] Warning: missing exclusion file: $FILE" >&2
        continue
    }

    echo "[*] Loading exclusions from: $FILE" >&2

    while IFS= read -r line || [[ -n "$line" ]]; do

        # trim whitespace (safe POSIX way)
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        [[ -z "$line" || "${line:0:1}" == "#" ]] && continue

        # expand ~
        if [[ "$line" == "~/"* ]]; then
            line="${HOME}/${line#"~/"}"
        fi

        # MUST stay absolute
        [[ "$line" != /* ]] && continue

        # output as absolute path (NO ./ conversion)
        printf '%s\n' "$line"

    done < "$FILE"

done
