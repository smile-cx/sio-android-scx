# Project Summary: SCX Socket.IO Client for Android

## Purpose

This project creates a **prefixed distribution** of the Socket.IO client for Android Java/Kotlin, designed to prevent symbol collisions when multiple versions or implementations of Socket.IO exist in the same application.

## Problem Statement

When an Android SDK (library) depends on Socket.IO, and the host application also includes Socket.IO (or another library with Socket.IO), symbol collisions occur:

- **Java/Kotlin**: Duplicate class errors, ClassLoader conflicts
- **Native (JNI)**: Symbol collision, undefined behavior, crashes

## Solution

Apply comprehensive prefixing at **both layers**:

### 1. Java/Kotlin Layer (Shadow Plugin)
- Package relocation: `io.socket.*` → `cx.smile.io.socket.*`
- Bytecode rewriting: All references updated automatically
- Transitive dependencies also relocated (okhttp3, okio, etc.)

### 2. Native Layer (Build-time Patching)
- Shared library renaming: `libname.so` → ``
- JNI symbol prefixing: `Java_io_*` → `Java_cx_smile_io_*`
- CMake/Android.mk patching

## Technical Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                     Build Pipeline                             │
└───────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│ Socket.IO Upstream  │  (GitHub: socketio/socket.io-client-java)
│ v2.1.0              │
└──────────┬──────────┘
           │
           ├──► Download Source
           │
           ▼
┌─────────────────────┐
│ Apply Patches       │
├─────────────────────┤
│ - Rename .so files  │
│ - Update JNI names  │
│ - Patch build files │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Build Upstream AAR  │
│ (with prefixed .so) │
└──────────┬──────────┘
           │
           ├──► Extract classes.jar
           ├──► Extract jni/*.so
           │
           ▼
┌─────────────────────────────────────────────────────────┐
│ Multi-Module Gradle Project                             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐        ┌──────────────────┐     │
│  │ shadow module    │        │ app module       │     │
│  ├──────────────────┤        ├──────────────────┤     │
│  │ - Shadow Plugin  │───────▶│ - Fat AAR Plugin │     │
│  │ - Relocate pkgs  │        │ - Embed shadow   │     │
│  │ - Process JAR    │        │ - Add .so files  │     │
│  └──────────────────┘        │ - Generate AAR   │     │
│                               └──────────────────┘     │
│                                                         │
└─────────────────────────────────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │ Final Prefixed AAR     │
                    ├────────────────────────┤
                    │ cx.smile.io.socket.*   │
                    │             │
                    └────────────────────────┘
```

## Key Components

### 1. Gradle Plugins

| Plugin | Purpose | Module |
|--------|---------|--------|
| Shadow | Java package relocation via bytecode rewriting | `shadow/` |
| Fat AAR | Reassemble AAR with embedded dependencies | `app/` |
| Android Library | Base Android AAR build | `app/` |

### 2. Build Scripts

| Script | Purpose |
|--------|---------|
| `prepare-upstream.sh` | Download, patch, and build Socket.IO |
| `apply-native-prefix.sh` | Apply native library prefixes |
| `build-release.sh` | Orchestrate complete build |
| `download-prebuilt.sh` | JitPack: download from GitHub Releases |

### 3. CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `test-build.yml` | Push/PR to main | Validate build process |
| `build-release.yml` | Tag push (`v*`) | Build and release AAR |

### 4. Distribution

| Method | Implementation |
|--------|---------------|
| GitHub Releases | Automatic via GitHub Actions |
| JitPack | Uses prebuilt AAR, runs shadow only |

## Prefixing Conventions

### Java/Kotlin
- **Package prefix**: `cx.smile.`
- **Example**: `io.socket.client.Socket` → `cx.smile.io.socket.client.Socket`

### Class Names (Public APIs)
- **Class prefix**: `SCX`
- **Example**: `SocketIO` → `SCXSocketIO` (if applicable)

### Native Libraries
- **Library prefix**: `scx_`
- **Example**: `libsocketio.so` → ``

### JNI Symbols
- **Symbol prefix**: `Java_cx_smile_`
- **Example**: `Java_io_socket_*` → `Java_cx_smile_io_socket_*`

## File Structure

```
sio-android-scx/
├── app/                          # Main Android library module
│   ├── build.gradle.kts         # Fat AAR configuration
│   ├── src/main/
│   │   ├── AndroidManifest.xml
│   │       ├── x86/
│   │       └── x86_64/
│   ├── proguard-rules.pro
│   └── consumer-rules.pro
├── shadow/                       # Shadow module for relocation
│   ├── build.gradle.kts         # Shadow plugin configuration
│   └── libs/
│       └── socketio-extracted.jar
├── scripts/
│   ├── prepare-upstream.sh      # Download and patch upstream
│   ├── apply-native-prefix.sh   # Native prefixing
│   ├── build-release.sh         # Complete build
│   └── download-prebuilt.sh     # JitPack helper
├── patches/                      # Custom patches (if needed)
│   └── README.md
├── .github/
│   └── workflows/
│       ├── build-release.yml    # Release workflow
│       └── test-build.yml       # Test workflow
├── gradle/
│   └── wrapper/
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── build.gradle.kts             # Root build configuration
├── settings.gradle.kts          # Module configuration
├── gradle.properties            # Build properties
├── jitpack.yml                  # JitPack configuration
├── README.md                    # User documentation
├── BUILD_GUIDE.md               # Build process guide
├── USAGE.md                     # Usage examples
├── CI_CD.md                     # CI/CD documentation
├── LICENSE                      # Complete license texts (all components)
├── NOTICE                       # Attribution and modification notices
├── UPSTREAM_LICENSE             # Original Socket.IO license (reference)
└── gradlew                      # Gradle wrapper script
```

## Build Process

### Phase 1: Prepare Upstream (Native Prefixing)

1. Clone Socket.IO client source
2. Apply patches to build files (CMakeLists.txt, Android.mk)
3. Rename native libraries in build configuration
4. Update JNI function names in headers
5. Modify `System.loadLibrary()` calls
6. Build upstream AAR with prefixed native code
7. Extract `classes.jar` and native libraries

### Phase 2: Java Relocation (Shadow)

1. Shadow module takes extracted JAR
2. Relocates packages:
   - `io.socket` → `cx.smile.io.socket`
   - `io.engine` → `cx.smile.io.engine`
   - Transitive dependencies (okhttp3, okio, etc.)
3. Produces shadowed JAR with rewritten bytecode

### Phase 3: Reassembly (Fat AAR)

1. Main module includes shadowed JAR
2. Adds prefixed native libraries from Phase 1
3. Combines into final AAR with all resources
4. Generates Maven artifacts

## CI/CD Pipeline

### Automatic Build (Tag Push)

```bash
git tag v2.1.0
git push origin v2.1.0
```

**GitHub Actions executes**:
1. Download upstream Socket.IO
2. Apply prefixes
3. Build and verify
4. Create GitHub Release
5. Upload AAR artifact

**Duration**: ~45-60 minutes

### JitPack Distribution

When user requests via JitPack:
1. JitPack downloads prebuilt AAR from GitHub Release
2. Extracts components
3. Runs Shadow + reassembly only (~5 minutes)
4. Publishes to Maven

**No native recompilation needed** ✓

## Verification

### Package Prefixing
```bash
jar tf classes.jar | grep "cx/smile"
```

### Native Libraries
```bash
unzip -l sio-android-scx-release.aar | grep ".so$"
```

### No Unprefixed Classes
```bash
jar tf classes.jar | grep "^io/socket/"
# Should return empty
```

## Usage in Applications

### Installation

```gradle
repositories {
    maven { url 'https://jitpack.io' }
}

dependencies {
    implementation 'com.github.smile-cx:sio-android-scx:v2.1.0'
}
```

### Code Example

```kotlin
import cx.smile.io.socket.client.IO
import cx.smile.io.socket.client.Socket

val socket = IO.socket("http://localhost:3000")
socket.connect()

socket.on(Socket.EVENT_CONNECT) {
    println("Connected")
}
```

## Handling Transitive Dependencies

All transitive dependencies are automatically relocated:

| Original | Prefixed |
|----------|----------|
| `okhttp3.*` | `cx.smile.okhttp3.*` |
| `okio.*` | `cx.smile.okio.*` |
| `org.json.*` | `cx.smile.org.json.*` |

This ensures complete isolation from other versions in the application.

## Maintenance

### Update to New Socket.IO Version

1. Update `gradle.properties`:
   ```properties
   UPSTREAM_VERSION=2.2.0
   ```

2. Test locally:
   ```bash
   ./scripts/build-release.sh
   ```

3. Create release:
   ```bash
   git tag v2.2.0
   git push origin v2.2.0
   ```

### Update Build Dependencies

1. Modify `build.gradle.kts` plugin versions
2. Test build
3. Create new release

## Performance

| Stage | Duration (Fresh) | Duration (Cached) |
|-------|------------------|-------------------|
| Upstream Build | ~30 min | ~5 min |
| Shadow Processing | ~3 min | ~1 min |
| AAR Assembly | ~2 min | ~1 min |
| **Total** | **~40 min** | **~10 min** |

**JitPack**: ~5 minutes (uses prebuilt)

## Benefits

1. **No Symbol Collisions**: Complete isolation from other Socket.IO instances
2. **Backward Compatible**: API remains identical (only packages change)
3. **Native Safety**: JNI symbols don't conflict
4. **Automatic**: CI/CD fully automated
5. **Fast Distribution**: JitPack uses prebuilt artifacts
6. **Verified**: Automated verification in CI

## Limitations

1. **Build Time**: Initial build takes ~40 minutes (native compilation)
2. **Package Names**: Import statements must use `cx.smile.*` prefix
3. **Maintenance**: Must track upstream Socket.IO updates
4. **Size**: May be slightly larger due to relocated dependencies

## Future Enhancements

1. Add Maven Central publishing
2. Implement incremental builds
3. Add more comprehensive tests
4. Support for additional platforms (iOS, Web)
5. Automated upstream version detection

## References

- [Socket.IO Client Java](https://github.com/socketio/socket.io-client-java)
- [Shadow Plugin](https://github.com/johnrengelman/shadow)
- [Fat AAR Plugin](https://github.com/kezong/fat-aar-android)
- [JitPack Documentation](https://jitpack.io/docs/)

## Support

- **Issues**: [GitHub Issues](../../issues)
- **Documentation**: See `BUILD_GUIDE.md`, `USAGE.md`, `CI_CD.md`
- **License**: MIT (see LICENSE and UPSTREAM_LICENSE)
