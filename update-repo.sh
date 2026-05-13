#!/bin/bash
# update-repo.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helper-logging.sh"

REPO_URL="https://github.com/NukelordPvP/linux-distro-backup"
BRANCH="main"

log_info "Checking repository status..."

# === VERIFY GIT ===

command -v git >/dev/null 2>&1 || \
    fatal "git is not installed"

# === ENSURE REPO ===

if [[ ! -d .git ]]; then

    log_warn "Not a git repository. Initializing..."

    git init

    git remote add origin "$REPO_URL"

    log_info "Fetching remote branch..."

    git fetch origin "$BRANCH"

    git checkout -t "origin/$BRANCH"

    log_ok "Repository initialized successfully"

    exit 0

fi

# === FETCH CHANGES ===

log_info "Fetching latest changes..."

git fetch origin "$BRANCH"

LOCAL="$(git rev-parse HEAD)"
REMOTE="$(git rev-parse "origin/$BRANCH")"

log_info "Local : $LOCAL"
log_info "Remote: $REMOTE"

# === COMPARE COMMITS ===

if [[ "$LOCAL" == "$REMOTE" ]]; then

    log_ok "Already up to date"
    exit 0

fi

log_warn "Update found. Pulling changes..."

git pull origin "$BRANCH"

log_ok "Repository updated successfully"
