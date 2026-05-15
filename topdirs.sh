#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXCLUDE_FILES=(
    "$SCRIPT_DIR/global-exclusions.txt"
    "$SCRIPT_DIR/backup-fedora-exclusions.txt"
    "$SCRIPT_DIR/backup-manjaro-exclusions.txt"
)

DU_EXCLUDES=()

# =========================
# LOAD EXCLUSIONS
# =========================

for file in "${EXCLUDE_FILES[@]}"; do

    [[ -f "$file" ]] || continue

    while IFS= read -r ex || [[ -n "$ex" ]]; do

        # trim whitespace
        ex="${ex#"${ex%%[![:space:]]*}"}"
        ex="${ex%"${ex##*[![:space:]]}"}"

        # skip blanks/comments
        [[ -z "$ex" ]] && continue
        [[ "${ex:0:1}" == "#" ]] && continue

        # expand ~
        if [[ "$ex" == "~"* ]]; then
            REAL_HOME="$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)"
            ex="${ex/#\~/$REAL_HOME}"
        fi

        # normalize
        ex="${ex%/}"

        # du expects full paths
        [[ "$ex" != /* ]] && ex="/$ex"

        DU_EXCLUDES+=( "--exclude=$ex" )

    done < "$file"

done

# =========================
# RUN
# =========================

sudo du -ahx / \
    "${DU_EXCLUDES[@]}" \
    2>/dev/null | sort -rh | head -20
