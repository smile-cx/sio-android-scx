#!/bin/bash
set -e

echo "=== Local Build Test Script ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo "ℹ $1"
}

# Check prerequisites
echo "=== Checking Prerequisites ==="
echo ""

# Check Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -ge 17 ]; then
    print_success "Java version: $JAVA_VERSION (requires 17+)"
else
    print_error "Java version $JAVA_VERSION is too old. Requires JDK 17 or later."
    exit 1
fi

# Check Android SDK (optional but recommended)
if [ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ]; then
    print_success "Android SDK found: ${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
else
    print_warning "ANDROID_HOME not set. Build may fail if Android SDK is not configured."
fi

# Check Gradle
if [ -x "./gradlew" ]; then
    print_success "Gradle wrapper found"
else
    print_error "Gradle wrapper not found or not executable"
    exit 1
fi

echo ""
echo "=== Cleaning Previous Builds ==="
./gradlew clean
print_success "Clean completed"

echo ""
echo "=== Building Shadow JAR (Package Relocation) ==="
./gradlew :shadow:shadowJar

# Check shadow JAR was created
if [ -f "shadow/build/libs/shadow.jar" ]; then
    SHADOW_SIZE=$(ls -lh shadow/build/libs/shadow.jar | awk '{print $5}')
    print_success "Shadow JAR created: $SHADOW_SIZE"
else
    print_error "Shadow JAR not found"
    exit 1
fi

echo ""
echo "=== Building Android AAR ==="
./gradlew :app:assembleRelease

# Check AAR was created
if [ -f "app/build/outputs/aar/app-release.aar" ]; then
    AAR_SIZE=$(ls -lh app/build/outputs/aar/app-release.aar | awk '{print $5}')
    print_success "AAR created: $AAR_SIZE"
else
    print_error "AAR not found"
    exit 1
fi

echo ""
echo "=== Copying to build/outputs ==="
mkdir -p build/outputs
cp app/build/outputs/aar/app-release.aar build/outputs/sio-android-scx-release.aar
print_success "Copied to: build/outputs/sio-android-scx-release.aar"

echo ""
echo "=== Verifying Prefixing ==="

# Extract and check shadow JAR from AAR
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
unzip -q "$OLDPWD/build/outputs/sio-android-scx-release.aar" libs/shadow.jar

# Check for prefixed classes
PREFIXED_COUNT=$(jar tf libs/shadow.jar | grep -c "cx/smile/" || true)
if [ "$PREFIXED_COUNT" -gt 0 ]; then
    print_success "Found $PREFIXED_COUNT prefixed classes (cx/smile/)"
else
    print_error "No prefixed classes found!"
    cd "$OLDPWD"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Check for Socket.IO classes
SOCKET_IO_COUNT=$(jar tf libs/shadow.jar | grep -c "cx/smile/io/socket/" || true)
if [ "$SOCKET_IO_COUNT" -gt 0 ]; then
    print_success "Socket.IO classes: $SOCKET_IO_COUNT"
else
    print_error "No Socket.IO classes found!"
    cd "$OLDPWD"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Check for OkHttp classes
OKHTTP_COUNT=$(jar tf libs/shadow.jar | grep -c "cx/smile/okhttp3/" || true)
if [ "$OKHTTP_COUNT" -gt 0 ]; then
    print_success "OkHttp classes: $OKHTTP_COUNT"
else
    print_warning "No OkHttp classes found (may be minimized)"
fi

# Check for unprefixed classes (should be none)
UNPREFIXED=$(jar tf libs/shadow.jar | grep -E "^(io/socket|io/engine|okhttp3|okio)/" || true)
if [ -z "$UNPREFIXED" ]; then
    print_success "No unprefixed Socket.IO/OkHttp classes found"
else
    print_error "Found unprefixed classes:"
    echo "$UNPREFIXED"
    cd "$OLDPWD"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo "=== Sample Prefixed Classes ==="
jar tf libs/shadow.jar | grep "cx/smile/io/socket/client" | head -10

cd "$OLDPWD"
rm -rf "$TEMP_DIR"

echo ""
echo "=== AAR Contents ==="
unzip -l build/outputs/sio-android-scx-release.aar

echo ""
echo "=== Build Test Summary ==="
echo ""
print_success "Build completed successfully"
print_success "All prefixing verified"
print_success "Output: build/outputs/sio-android-scx-release.aar ($AAR_SIZE)"
echo ""
print_info "You can now safely create and push a release tag:"
echo "  git tag v2.1.0"
echo "  git push origin v2.1.0"
echo ""
