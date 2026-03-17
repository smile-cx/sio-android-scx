#!/bin/bash
set -e

# This script is used by JitPack to download prebuilt AAR from GitHub Releases
# instead of rebuilding from source

VERSION="${1:-${GITHUB_REF_NAME:-main}}"
REPO="${2:-smile-cx/sio-android-scx}"

echo "=== Downloading prebuilt AAR from GitHub Releases ==="
echo "Version: $VERSION"
echo "Repository: $REPO"

# Create directories
mkdir -p shadow/libs
mkdir -p extracted

# Download release artifact
RELEASE_URL="https://github.com/$REPO/releases/download/$VERSION/sio-android-scx-release.aar"

echo "Downloading from: $RELEASE_URL"
curl -L -f -o "extracted/sio-android-scx-release.aar" "$RELEASE_URL"

if [ ! -f "extracted/sio-android-scx-release.aar" ]; then
    echo "Error: Failed to download release AAR"
    echo "Make sure the release $VERSION exists with the AAR artifact"
    exit 1
fi

# Extract AAR contents
cd extracted
unzip -q sio-android-scx-release.aar

# Extract classes.jar for shadow module
if [ -f "classes.jar" ]; then
    cp classes.jar ../shadow/libs/socketio-extracted.jar
    echo "Extracted classes.jar"
else
    echo "Warning: classes.jar not found in AAR"
fi

cd ..

echo "=== Prebuilt AAR extraction complete ==="
