#!/usr/bin/env bash
set -euo pipefail

# Usage: ./clone-aur.sh <pkgname>
# Clones a new AUR package or updates an existing one in this repository.

# TODO: check update
# curl "https://aur.archlinux.org/rpc/v5/info?arg[]={pkgname}"

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <pkgname>"
    exit 1
fi

PKG="$1"
AUR_URL="https://aur.archlinux.org/${PKG}.git"
TMPDIR=$(mktemp -d)

cleanup() {
    echo "Cleaning up $TMPDIR"
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

if [ -z "$(git ls-remote "$AUR_URL" 2>/dev/null)" ]; then
    echo "Error: package '$PKG' not found on AUR."
    exit 1
fi

echo "Fetching $AUR_URL ..."
git clone --depth 1 "$AUR_URL" "$TMPDIR/$PKG"

# Create a source marker file inside the package directory
echo "$AUR_URL" >"$TMPDIR/$PKG/.clone.source"
git -C "$TMPDIR/$PKG" log -1 --format="last_commit_time=%cI" >>"$TMPDIR/$PKG/.clone.source"

# Remove the nested .git directory so it becomes a regular subdir of the parent repo
rm -rf "$TMPDIR/$PKG/.git"

# Ensure .clone.source is not excluded by blanket gitignore rules
echo >>"$TMPDIR/$PKG/.gitignore"
echo "!.clone.source" >>"$TMPDIR/$PKG/.gitignore"

if [ -d "$PKG" ]; then
    if diff -rq "$PKG" "$TMPDIR/$PKG" >/dev/null 2>&1; then
        echo "$PKG is already up to date."
        exit 0
    fi
    echo "Updating $PKG ..."
    rm -rf "$PKG"
    mv "$TMPDIR/$PKG" "$PKG"
    git add "$PKG"
    if git diff --cached --quiet; then
        echo "Nothing to commit."
        exit 0
    fi
    git commit -m "chore: Update $PKG from AUR"
    echo "Done: $PKG updated."
else
    echo "Cloning $PKG ..."
    mv "$TMPDIR/$PKG" "$PKG"
    git add "$PKG"
    if git diff --cached --quiet; then
        echo "Nothing to commit."
        exit 0
    fi
    git commit -m "chore: Add $PKG from AUR"
    echo "Done: $PKG added."
fi
