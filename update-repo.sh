#!/bin/bash

set -e

REPO_URL="https://github.com/NukelordPvP/linux-distro-backup"
BRANCH="main"

echo "[*] Checking repository status..."

# Ensure we're inside a git repo
if [ ! -d .git ]; then
    echo "[!] Not a git repository. Initializing..."
    git init
    git remote add origin "$REPO_URL"
    git fetch origin "$BRANCH"
    git checkout -t origin/$BRANCH
    exit 0
fi

# Fetch latest changes
git fetch origin "$BRANCH"

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/$BRANCH)

echo "[*] Local : $LOCAL"
echo "[*] Remote: $REMOTE"

# Compare commits
if [ "$LOCAL" = "$REMOTE" ]; then
    echo "[✓] Already up to date."
    exit 0
fi

echo "[!] Update found. Pulling changes..."
git pull origin "$BRANCH"

echo "[✓] Repository updated successfully."
