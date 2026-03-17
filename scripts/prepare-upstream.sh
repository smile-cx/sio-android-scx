#!/bin/bash
set -e

# Configuration
SOCKETIO_VERSION="${UPSTREAM_VERSION:-2.1.0}"

echo "=== Preparing Socket.IO Client upstream library ==="
echo "Version: $SOCKETIO_VERSION"
echo ""
echo "Socket.IO Client Java is a pure Java library (no native code)."
echo "Dependencies will be fetched automatically by Gradle from Maven Central."
echo ""
echo "The Shadow plugin will:"
echo "  1. Download Socket.IO client JAR and all transitive dependencies"
echo "  2. Relocate all packages to cx.smile.* namespace"
echo "  3. Bundle everything into a single JAR"
echo ""
echo "=== Upstream preparation complete ==="
echo "Ready to build with: ./gradlew :shadow:shadowJar"
