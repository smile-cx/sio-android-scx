# Quick Start Guide

Get up and running with the SCX Socket.IO Client build pipeline in minutes.

## Prerequisites

- **Git**: Version control
- **JDK 11+**: Java Development Kit
- **Android SDK**: API level 21+
- **Gradle**: Included via wrapper

## Step 1: Setup Repository

```bash
cd /Volumes/Dev/smilecx/repos/sio-android-scx

# Make scripts executable
chmod +x scripts/*.sh gradlew

# Update GitHub username in key files
sed -i '' 's/smile-cx/YOUR_ACTUAL_USERNAME/g' README.md
sed -i '' 's/smile-cx/YOUR_ACTUAL_USERNAME/g' .github/workflows/*.yml
sed -i '' 's/smile-cx/YOUR_ACTUAL_USERNAME/g' scripts/download-prebuilt.sh
```

## Step 2: Configure

Edit `gradle.properties`:

```properties
# Set Socket.IO version to match upstream
VERSION_NAME=2.1.0
UPSTREAM_VERSION=2.1.0

# Package prefix (already set correctly)
PACKAGE_PREFIX=cx.smile.
```

## Step 3: Test Build Locally

```bash
# Start the build (takes ~5-8 minutes)
./scripts/build-release.sh
```

Verify output:

```bash
# Check output exists
ls -lh build/outputs/sio-android-scx-release.aar

# Verify prefixing worked
unzip -p build/outputs/sio-android-scx-release.aar classes.jar | \
    jar tf - | grep "cx/smile" | head -10
```

You should see classes like:
```
cx/smile/io/socket/client/Socket.class
cx/smile/io/socket/client/IO.class
cx/smile/io/engine/client/Socket.class
```

## Step 4: Create Release

```bash
# Commit initial setup
git add .
git commit -m "Initial setup of SCX Socket.IO Client"
git push origin main

# Create and push tag
git tag v2.1.0
git push origin v2.1.0
```

GitHub Actions will:
- Build the AAR (~10-15 minutes)
- Create a GitHub Release
- Upload the artifact

Check progress: **Your Repo → Actions tab**

## Step 5: Enable JitPack

After CI completes:

1. Go to https://jitpack.io
2. Enter: `com.github.YOUR_USERNAME/sio-android-scx`
3. Click **Look up**
4. Select `v2.1.0`
5. Click **Get it**

JitPack builds in ~3 minutes (uses your prebuilt AAR).

## Step 6: Use It!

In your app's `build.gradle.kts`:

```kotlin
repositories {
    maven { url = uri("https://jitpack.io") }
}

dependencies {
    implementation("com.github.YOUR_USERNAME:sio-android-scx:v2.1.0")
}
```

In your code:

```kotlin
import cx.smile.io.socket.client.IO
import cx.smile.io.socket.client.Socket

val socket = IO.socket("http://localhost:3000")
socket.connect()

socket.on(Socket.EVENT_CONNECT) {
    println("Connected!")
}
```

## Done! 🎉

You now have:
- ✅ Prefixed Socket.IO client (no collisions)
- ✅ Single AAR with ALL dependencies included
- ✅ Automated CI/CD pipeline
- ✅ GitHub Releases + JitPack distribution

## Common Tasks

### Update to New Socket.IO Version

```bash
# 1. Update gradle.properties
echo "UPSTREAM_VERSION=2.2.0" >> gradle.properties
echo "VERSION_NAME=2.2.0" >> gradle.properties

# 2. Test locally
./scripts/build-release.sh

# 3. Commit and tag
git add gradle.properties
git commit -m "Bump to Socket.IO 2.2.0"
git tag v2.2.0
git push origin main v2.2.0
```

### Test Without Publishing

```bash
# Build locally
./scripts/build-release.sh

# Use in test app
cd /path/to/test-app
mkdir -p libs
cp /path/to/sio-android-scx/build/outputs/sio-android-scx-release.aar libs/

# In test app's build.gradle.kts
dependencies {
    implementation(files("libs/sio-android-scx-release.aar"))
}
```

## Troubleshooting

**Build fails?**
```bash
./gradlew clean
rm -rf extracted shadow/libs
./scripts/build-release.sh
```

**CI fails?**
Check logs in GitHub Actions tab.

**JitPack fails?**
Ensure GitHub Release has the AAR file.

**Need help?**
See [BUILD_GUIDE.md](BUILD_GUIDE.md) for detailed information.

---

**Questions?** Check the comprehensive docs in this repo!
