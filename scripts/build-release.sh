#!/bin/bash
set -e

echo "=== Building SCX Socket.IO Client Release ==="

# Build the shadowed and reassembled AAR
echo "Building final AAR with shadowing..."
./gradlew clean :app:assembleRelease

# Copy output to predictable location
OUTPUT_DIR="build/outputs"
mkdir -p "$OUTPUT_DIR"

AAR_FILE="app/build/outputs/aar/app-release.aar"

if [ ! -f "$AAR_FILE" ]; then
    echo "Error: AAR file not found at $AAR_FILE"
    exit 1
fi

cp "$AAR_FILE" "$OUTPUT_DIR/sio-android-scx-release.aar"

echo "=== Build complete ==="
echo "Output: $OUTPUT_DIR/sio-android-scx-release.aar"

# Show AAR contents for verification
echo ""
echo "AAR Contents:"
unzip -l "$OUTPUT_DIR/sio-android-scx-release.aar"
