# Build Guide: Prefixing Socket.IO Client

This guide explains the complete build pipeline for creating a prefixed Socket.IO client library.

## Overview

The build process has two main phases:

1. **Build-time modifications (native layer)**: Patch and build upstream source with prefixed native libraries
2. **Post-processing (Java layer)**: Relocate Java packages using Shadow plugin and reassemble with Fat AAR

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: Build Upstream with Native Prefixing              │
├─────────────────────────────────────────────────────────────┤
│ 1. Clone socket.io-client-java                              │
│ 2. Apply patches:                                            │
│    - Rename .so files: libname.so ->          │
│    - Update JNI symbols: Java_io_* -> Java_cx_smile_io_*    │
│    - Update System.loadLibrary() calls                       │
│ 3. Build AAR                                                 │
│ 4. Extract:                                                  │
│    - classes.jar -> shadow/libs/socketio-extracted.jar      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Phase 2: Java Package Relocation & Reassembly              │
├─────────────────────────────────────────────────────────────┤
│ 1. Shadow module processes socketio-extracted.jar:          │
│    - Relocate: io.socket -> cx.smile.io.socket             │
│    - Relocate: io.engine -> cx.smile.io.engine             │
│    - Relocate dependencies: okhttp3, okio, org.json        │
│ 2. Main module reassembles AAR:                             │
│    - Embed shadowed JAR                                      │
│    - Include prefixed native libraries                       │
│    - Generate final AAR                                      │
└─────────────────────────────────────────────────────────────┘
```

## Module Structure

```
sio-android-scx/
├── app/                           # Main Android library module
│   ├── build.gradle.kts          # Fat AAR plugin configuration
│   └── src/main/
│       ├── AndroidManifest.xml
│           ├── x86/
│           └── x86_64/
├── shadow/                        # Shadow/relocation module
│   ├── build.gradle.kts          # Shadow plugin configuration
│   └── libs/
│       └── socketio-extracted.jar # Extracted from upstream AAR
└── scripts/
    ├── prepare-upstream.sh       # Download, patch, build upstream
    ├── apply-native-prefix.sh    # Apply native library patches
    ├── download-prebuilt.sh      # For JitPack (use prebuilt AAR)
    └── build-release.sh          # Complete build orchestration
```

## Build Steps

### Local Build

```bash
# Full build from source
./scripts/build-release.sh

# Output: build/outputs/sio-android-scx-release.aar
```

### CI Build (GitHub Actions)

Triggered on tag push:
```bash
git tag v2.1.0
git push origin v2.1.0
```

GitHub Actions will:
1. Build the prefixed AAR
2. Create a GitHub Release
3. Upload AAR artifact

### JitPack Build

When a user requests the library via JitPack:
1. JitPack clones the repository
2. `jitpack.yml` runs `download-prebuilt.sh` to fetch AAR from GitHub Releases
3. Extracts JAR and native libraries
4. Runs Shadow + reassembly (quick, no native compilation)
5. Publishes to JitPack Maven repository

## Transitive Dependencies

Socket.IO depends on several libraries that must also be prefixed to avoid conflicts:

### Handled by Shadow Plugin

The following dependencies are relocated automatically:
- `okhttp3` -> `cx.smile.okhttp3`
- `okio` -> `cx.smile.okio`
- `org.json` -> `cx.smile.org.json`

### Native Dependencies

If Socket.IO's transitive dependencies include native libraries:
1. Extract their .so files
2. Apply the same prefixing strategy
3. Include in the final AAR

## Gradle Plugins

### 1. Shadow Plugin (com.github.johnrengelman.shadow)

**Purpose**: Relocate Java packages by rewriting bytecode

**Configuration** (shadow/build.gradle.kts):
```kotlin
tasks.named<ShadowJar>("shadowJar") {
    relocate("io.socket", "cx.smile.io.socket")
    relocate("io.engine", "cx.smile.io.engine")
    relocate("okhttp3", "cx.smile.okhttp3")
    // ... more relocations
}
```

### 2. Fat AAR Plugin (com.kezong.fat-aar)

**Purpose**: Combine shadowed JAR with native libraries into final AAR

**Configuration** (app/build.gradle.kts):
```kotlin
plugins {
    id("com.kezong.fat-aar")
}

dependencies {
    embed(project(":shadow"))
}
```

## Verification

After building, verify the prefixing worked:

```bash
# Check Java packages
unzip -p build/outputs/sio-android-scx-release.aar classes.jar | \
    jar tf - | grep "cx/smile"

# Check native libraries
unzip -l build/outputs/sio-android-scx-release.aar | grep ".so$"
```

Expected results:
- Java classes under `cx/smile/io/socket/` and `cx/smile/io/engine/`
- Native libraries named ``
- No classes under `io/socket/` or `io/engine/`

## Troubleshooting

### Native Library Not Found

If you get `UnsatisfiedLinkError`:
1. Check `System.loadLibrary()` calls use prefixed names
2. Verify .so files are named with prefix
3. Check JNI function names match package prefix

### Class Not Found

If you get `ClassNotFoundException`:
1. Verify Shadow plugin relocated all packages
2. Check for hardcoded class names in strings
3. Review reflection usage

### Duplicate Classes

If you get `Duplicate class` errors:
1. Ensure all transitive dependencies are relocated
2. Check consumer's dependencies don't conflict
3. Verify prefix is unique enough

## Custom Patches

For advanced scenarios, create custom patches in `patches/`:

```bash
patches/
├── 0001-prefix-native-libraries.patch
├── 0002-update-jni-headers.patch
└── 0003-relocate-resources.patch
```

Apply in `scripts/apply-native-prefix.sh`:
```bash
for patch in patches/*.patch; do
    git apply "$patch"
done
```

## Distribution

### GitHub Releases

Automatic via GitHub Actions:
- Tag format: `v{version}` (e.g., `v2.1.0`)
- Asset: `sio-android-scx-release.aar`

### JitPack

Automatic once pushed to GitHub:
```gradle
repositories {
    maven { url 'https://jitpack.io' }
}

dependencies {
    implementation 'com.github.smile-cx:sio-android-scx:v2.1.0'
}
```

### Maven Central (Optional)

For Maven Central publishing, add signing and OSSRH configuration to `app/build.gradle.kts`.

## Updating to New Upstream Versions

1. Update `UPSTREAM_VERSION` in `gradle.properties`
2. Test build locally: `./scripts/build-release.sh`
3. Create and push tag: `git tag v{new-version}-scx`
4. GitHub Actions builds and releases automatically

## Performance Optimization

### Build Cache

- Upstream source cached by version
- Gradle cache enabled
- JitPack uses prebuilt AAR (no native recompilation)

### Parallel Builds

Enable in `gradle.properties`:
```properties
org.gradle.parallel=true
org.gradle.caching=true
```

## Security Considerations

- Native library prefixing prevents symbol hijacking
- Package relocation prevents class loading conflicts
- ProGuard rules preserve required symbols
