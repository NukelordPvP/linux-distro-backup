#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =========================
# EXCLUSION FILES
# =========================

EXCLUDE_FILES=(
    "$SCRIPT_DIR/global-exclusions.txt"
    "$SCRIPT_DIR/backup-fedora-exclusions.txt"
    "$SCRIPT_DIR/backup-manjaro-exclusions.txt"
    "$SCRIPT_DIR/topdirs-ignore.txt"
)

DU_EXCLUDES=()

REAL_HOME="$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)"

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
        [[ "$ex" == "~"* ]] && ex="${ex/#\~/$REAL_HOME}"

        # normalize
        ex="${ex%/}"

        # ensure absolute path
        [[ "$ex" != /* ]] && ex="/$ex"

        DU_EXCLUDES+=( "--exclude=$ex" )

    done < "$file"

done

# =========================
# RUN
# =========================

sudo du -ahx / \
    "${DU_EXCLUDES[@]}" \
    2>/dev/null \
    | sort -rh \
    | head -20
