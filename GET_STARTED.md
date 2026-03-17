# Get Started in 5 Minutes

This is your **fastest path** to building and distributing the prefixed Socket.IO client.

## Prerequisites Check

```bash
# Verify you have everything:
java -version    # Should be 11+
git --version    # Any recent version
```

If missing JDK: https://adoptium.net/

## Step 1: Configure (2 minutes)

```bash
cd /Volumes/Dev/smilecx/repos/sio-android-scx

# Make scripts executable
chmod +x scripts/*.sh gradlew

# Update GitHub username
sed -i '' 's/smile-cx/YOUR_ACTUAL_USERNAME/g' README.md
sed -i '' 's/smile-cx/YOUR_ACTUAL_USERNAME/g' .github/workflows/*.yml
sed -i '' 's/smile-cx/YOUR_ACTUAL_USERNAME/g' scripts/download-prebuilt.sh
```

## Step 2: Test Build (5 minutes)

```bash
# Build (takes ~5-8 minutes)
./scripts/build-release.sh
```

**Verify:**

```bash
# Check output
ls -lh build/outputs/sio-android-scx-release.aar

# Verify prefixing
unzip -p build/outputs/sio-android-scx-release.aar classes.jar | \
    jar tf - | grep "cx/smile" | head -10
```

## Step 3: Create Release (1 minute)

```bash
# Commit
git add .
git commit -m "Initial setup of SCX Socket.IO Client"
git push origin main

# Tag and push
git tag v2.1.0
git push origin v2.1.0
```

## Step 4: Enable JitPack (1 minute)

After CI completes:
1. Go to https://jitpack.io
2. Enter: `com.github.YOUR_USERNAME/sio-android-scx`
3. Select `v2.1.0` and click **Get it**

## Step 5: Use It!

```kotlin
dependencies {
    implementation("com.github.YOUR_USERNAME:sio-android-scx:v2.1.0")
}
```

```kotlin
import cx.smile.io.socket.client.IO

val socket = IO.socket("http://localhost:3000")
socket.connect()
```

## Done! 🎉

**What's Included?**

Single AAR with ALL dependencies:
- `cx.smile.io.socket.*` - Socket.IO
- `cx.smile.okhttp3.*` - HTTP client
- `cx.smile.okio.*` - I/O utilities
- All transitive dependencies

**No symbol collisions, everything in one package!**
