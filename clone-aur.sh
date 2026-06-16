#!/usr/bin/env bash
set -euo pipefail

# Usage: ./clone-aur.sh <pkgname>

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <pkgname>"
    exit 1
fi

PKG="$1"
AUR_URL="https://aur.archlinux.org/${PKG}.git"

if [ -d "$PKG" ]; then
    echo "Error: directory '$PKG' already exists."
    exit 1
fi

echo "Cloning $AUR_URL ..."
git clone "$AUR_URL"

# Remove the nested .git directory so it becomes a regular subdir of the parent repo
rm -rf "$PKG/.git"

# Add, commit, and push to the parent repo
git add "$PKG"

if git diff --cached --quiet; then
    echo "Nothing to commit."
    exit 0
fi

git commit -m "chore: Add $PKG from AUR"
# git push

echo "Done: $PKG added and pushed."
