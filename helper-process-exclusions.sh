#!/bin/bash
# helper-process-exclusions.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

if [[ "$#" -lt 1 ]]; then
    fatal "Usage: $0 <exclusion_file1> [exclusion_file2 ...]"
fi

for FILE in "$@"; do

    if [[ ! -f "$FILE" ]]; then
        log_warn "Missing exclusion file: $FILE"
        continue
    fi

    log_info "Loading exclusions from: $FILE"

    while IFS= read -r line || [[ -n "$line" ]]; do

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

        summary_exclude "$line"

        echo "--exclude=$line"

    done < "$FILE"

done
