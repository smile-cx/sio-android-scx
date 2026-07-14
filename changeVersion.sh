#!/usr/bin/env bash
# Usage: ./changeVersion.sh <version>
# Sets the sio-android-scx version (single source of truth) and commits.
set -euo pipefail

[[ $# -eq 1 ]] || { echo "Usage: $0 <version>"; exit 1; }
VERSION="$1"
ROOT="$(cd "$(dirname "$0")" && pwd)"

perl -i -pe "s|^VERSION_NAME=.*|VERSION_NAME=${VERSION}|" "$ROOT/gradle.properties"

git -C "$ROOT" add gradle.properties
git -C "$ROOT" diff --cached --quiet || git -C "$ROOT" commit -m "chore: bump version to ${VERSION}"
echo "sio-android-scx version → ${VERSION}"
