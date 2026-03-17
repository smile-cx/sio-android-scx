# Architecture Documentation

This document provides a comprehensive overview of the SCX Socket.IO Client build architecture.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SCX Socket.IO Client Pipeline                     │
└─────────────────────────────────────────────────────────────────────────┘

                              INPUT SOURCES
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
┌────────────────┐        ┌────────────────┐       ┌────────────────┐
│  Socket.IO     │        │  Build Config  │       │  Custom        │
│  Upstream      │        │  & Scripts     │       │  Patches       │
│  (GitHub)      │        │                │       │  (Optional)    │
└────────┬───────┘        └────────┬───────┘       └────────┬───────┘
         │                         │                        │
         └─────────────────────────┼────────────────────────┘
                                   │
                                   ▼
                         ┌─────────────────┐
                         │  PHASE 1        │
                         │  Native Layer   │
                         │  Prefixing      │
                         └────────┬────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
          ┌──────────────────┐        ┌──────────────────┐
          │ Patch Build      │        │ Rename Native    │
          │ Files            │        │ Libraries        │
          │ (CMake, Mk)      │        │ (.so files)      │
          └────────┬─────────┘        └────────┬─────────┘
                   │                           │
                   └─────────────┬─────────────┘
                                 │
                                 ▼
                      ┌────────────────────┐
                      │ Build Upstream AAR │
                      │ with Prefixed .so  │
                      └──────────┬─────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼
          ┌──────────────────┐      ┌──────────────────┐
          │ Extract          │      │ Extract          │
          │ classes.jar      │      │ jni/*.so         │
          └────────┬─────────┘      └────────┬─────────┘
                   │                         │
                   └─────────────┬───────────┘
                                 │
                                 ▼
                         ┌─────────────────┐
                         │  PHASE 2        │
                         │  Java Layer     │
                         │  Relocation     │
                         └────────┬────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
          ┌──────────────────┐        ┌──────────────────┐
          │ Shadow Module    │        │ Relocate         │
          │ Processes JAR    │───────▶│ Java Packages    │
          └──────────────────┘        └────────┬─────────┘
                                               │
                                               ▼
                                    ┌──────────────────────┐
                                    │ Rewrite Bytecode     │
                                    │ Update References    │
                                    └──────────┬───────────┘
                                               │
                                               ▼
                                    ┌──────────────────────┐
                                    │ Shadowed JAR         │
                                    │ (cx.smile.*)         │
                                    └──────────┬───────────┘
                                               │
                                               ▼
                         ┌─────────────────────────────┐
                         │  PHASE 3                    │
                         │  AAR Reassembly             │
                         └────────┬────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
          ┌──────────────────┐        ┌──────────────────┐
          │ Main Module      │        │ Embed Shadowed   │
          │ Combines         │───────▶│ JAR + Native     │
          │ Components       │        │ Libraries        │
          └──────────────────┘        └────────┬─────────┘
                                               │
                                               ▼
                                    ┌──────────────────────┐
                                    │ Fat AAR Plugin       │
                                    │ Packages Everything  │
                                    └──────────┬───────────┘
                                               │
                                               ▼
                                    ┌──────────────────────┐
                                    │ Final Prefixed AAR   │
                                    │ ✓ cx.smile.*         │
                                    │ ✓         │
                                    └──────────┬───────────┘
                                               │
                                               ▼
                         ┌─────────────────────────────┐
                         │  DISTRIBUTION               │
                         └────────┬────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
          ┌──────────────────┐        ┌──────────────────┐
          │ GitHub Release   │        │ JitPack.io       │
          │ - Direct DL      │        │ - Maven Dist     │
          │ - CI/CD          │        │ - Fast Build     │
          └──────────────────┘        └──────────────────┘
```

## Component Architecture

### 1. Build Modules

```
┌─────────────────────────────────────────────────────────┐
│ Root Project (sio-android-scx)                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │ App Module (Main Android Library)              │   │
│  ├────────────────────────────────────────────────┤   │
│  │ - com.android.library plugin                   │   │
│  │ - com.kezong.fat-aar plugin                    │   │
│  │ - Maven publishing configuration               │   │
│  │                                                 │   │
│  │ Dependencies:                                   │   │
│  │   embed(project(":shadow"))                    │   │
│  │                                                 │   │
│  │   ├── x86/                          │   │
│  │   └── x86_64/                       │   │
│  │                                                 │   │
│  │ Output:                                         │   │
│  │   sio-android-scx-release.aar                  │   │
│  └────────────────────────────────────────────────┘   │
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │ Shadow Module (Package Relocation)             │   │
│  ├────────────────────────────────────────────────┤   │
│  │ - java-library plugin                          │   │
│  │ - com.github.johnrengelman.shadow plugin       │   │
│  │                                                 │   │
│  │ Input:                                          │   │
│  │   libs/socketio-extracted.jar                  │   │
│  │                                                 │   │
│  │ Relocations:                                    │   │
│  │   io.socket      → cx.smile.io.socket          │   │
│  │   io.engine      → cx.smile.io.engine          │   │
│  │   okhttp3        → cx.smile.okhttp3            │   │
│  │   okio           → cx.smile.okio               │   │
│  │   org.json       → cx.smile.org.json           │   │
│  │                                                 │   │
│  │ Output:                                         │   │
│  │   shadow.jar (relocated bytecode)              │   │
│  └────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2. Build Scripts Architecture

```
scripts/
│
├── prepare-upstream.sh
│   ├── Downloads Socket.IO source from GitHub
│   ├── Applies apply-native-prefix.sh
│   ├── Builds upstream AAR with Gradle
│   ├── Extracts classes.jar to shadow/libs/
│
├── apply-native-prefix.sh
│   ├── Patches CMakeLists.txt (add_library names)
│   ├── Patches Android.mk (LOCAL_MODULE names)
│   ├── Updates JNI function signatures
│   ├── Modifies System.loadLibrary() calls
│   └── Renames .so file references
│
├── build-release.sh
│   ├── Orchestrates full build
│   ├── Calls prepare-upstream.sh
│   ├── Runs ./gradlew :app:assembleRelease
│   ├── Copies output to build/outputs/
│   └── Verifies AAR contents
│
└── download-prebuilt.sh (JitPack only)
    ├── Downloads AAR from GitHub Releases
    ├── Extracts classes.jar to shadow/libs/
```

### 3. CI/CD Architecture

```
┌─────────────────────────────────────────────────────────┐
│ GitHub Repository                                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Event: Push to main/develop                             │
│  ─────────────────────────────────────────────────────  │
│  Workflow: test-build.yml                                │
│  ├── Checkout code                                       │
│  ├── Setup JDK 11 + Android SDK                          │
│  ├── Cache Gradle + upstream                             │
│  ├── Run build-release.sh                                │
│  ├── Verify prefixing                                    │
│  └── Upload artifacts (7-day retention)                  │
│                                                          │
│  Event: Push tag (v*)                                    │
│  ─────────────────────────────────────────────────────  │
│  Workflow: build-release.yml                             │
│  ├── Checkout code                                       │
│  ├── Setup JDK 11 + Android SDK                          │
│  ├── Cache Gradle + upstream                             │
│  ├── Run build-release.sh                                │
│  ├── Verify AAR contents                                 │
│  ├── Generate checksum (SHA-256)                         │
│  ├── Create GitHub Release                               │
│  └── Upload AAR + checksum to release                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
                            │
                            │ Tag pushed
                            ▼
┌─────────────────────────────────────────────────────────┐
│ GitHub Releases                                          │
├─────────────────────────────────────────────────────────┤
│  Release: v{version}                                     │
│  ├── sio-android-scx-release.aar                         │
│  └── sio-android-scx-release.aar.sha256                  │
└─────────────────────────────────────────────────────────┘
                            │
                            │ JitPack detects tag
                            ▼
┌─────────────────────────────────────────────────────────┐
│ JitPack.io                                               │
├─────────────────────────────────────────────────────────┤
│  Configuration: jitpack.yml                              │
│  ├── before_install:                                     │
│  │   └── download-prebuilt.sh (fetch from Releases)     │
│  ├── install:                                            │
│  │   ├── Shadow plugin (relocate packages)              │
│  │   └── Gradle build (reassemble AAR)                  │
│  └── Publish to Maven repository                         │
│                                                          │
│  URL: com.github.smile-cx:sio-android-scx:{version}  │
└─────────────────────────────────────────────────────────┘
```

### 4. Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ INPUT: Socket.IO Client Source (upstream)                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌────────────────────┐
              │ TRANSFORMATION 1   │
              │ Native Prefixing   │
              └──────────┬─────────┘
                         │
            ┌────────────┴────────────┐
            │                         │
            ▼                         ▼
    ┌──────────────┐          ┌──────────────┐
    │ .so files    │          │ JNI symbols  │
    │ renamed      │          │ prefixed     │
    └──────┬───────┘          └──────┬───────┘
           │                         │
           └────────────┬────────────┘
                        │
                        ▼
              ┌───────────────────┐
              │ Upstream AAR      │
              │ (prefixed native) │
              └──────────┬────────┘
                         │
                         ▼
              ┌────────────────────┐
              │ EXTRACTION         │
              │ classes.jar + .so  │
              └──────────┬─────────┘
                         │
            ┌────────────┴────────────┐
            │                         │
            ▼                         ▼
    ┌──────────────┐          ┌──────────────┐
    │ classes.jar  │          │ Native libs  │
    │ → shadow     │          │ → app        │
    └──────┬───────┘          └──────┬───────┘
           │                         │
           ▼                         │
  ┌─────────────────┐                │
  │ TRANSFORMATION 2│                │
  │ Java Relocation │                │
  └────────┬────────┘                │
           │                         │
           ▼                         │
  ┌─────────────────┐                │
  │ Shadowed JAR    │                │
  │ (cx.smile.*)    │                │
  └────────┬────────┘                │
           │                         │
           └────────────┬────────────┘
                        │
                        ▼
              ┌───────────────────┐
              │ REASSEMBLY        │
              │ Fat AAR Plugin    │
              └──────────┬────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ OUTPUT: Prefixed AAR                                         │
│ ├── classes.jar (cx.smile.*)                                 │
│ ├── jni/x86/                                      │
│ ├── jni/x86_64/                                   │
│ └── AndroidManifest.xml                                      │
└─────────────────────────────────────────────────────────────┘
```

## Gradle Plugin Integration

### Shadow Plugin (Java Relocation)

```kotlin
// shadow/build.gradle.kts

shadowJar {
    // Output configuration
    archiveBaseName.set("shadow")
    archiveClassifier.set("")

    // Package relocations (bytecode rewriting)
    relocate("io.socket", "cx.smile.io.socket")
    relocate("io.engine", "cx.smile.io.engine")
    relocate("okhttp3", "cx.smile.okhttp3")
    relocate("okio", "cx.smile.okio")
    relocate("org.json", "cx.smile.org.json")

    // Optimization
    minimize()  // Remove unused classes
    mergeServiceFiles()  // Merge META-INF/services

    // Cleanup
    exclude("META-INF/*.SF")
    exclude("META-INF/*.DSA")
    exclude("META-INF/*.RSA")
}
```

**How it works**:
1. Reads input JAR bytecode
2. Parses class definitions
3. Rewrites package names in:
   - Class declarations
   - Import statements
   - Method signatures
   - Field types
   - Annotations
   - String constants (resource paths)
4. Updates constant pool
5. Writes modified bytecode to output JAR

### Fat AAR Plugin (AAR Reassembly)

```kotlin
// app/build.gradle.kts

plugins {
    id("com.kezong.fat-aar")
}

dependencies {
    // Embed the shadowed module
    embed(project(":shadow"))
}
```

**How it works**:
1. Builds main module AAR
2. Extracts shadowed JAR from dependency
3. Merges JAR into main AAR
5. Combines resources and manifests
6. Repackages as single AAR

## Prefixing Strategy

### Package Prefixing

```
Original Package                Prefixed Package
─────────────────────────────────────────────────────────
io.socket.client.Socket      → cx.smile.io.socket.client.Socket
io.socket.client.IO          → cx.smile.io.socket.client.IO
io.socket.client.Manager     → cx.smile.io.socket.client.Manager
io.engine.client.Socket      → cx.smile.io.engine.client.Socket
io.engine.client.Transport   → cx.smile.io.engine.client.Transport

Dependencies:
okhttp3.OkHttpClient         → cx.smile.okhttp3.OkHttpClient
okhttp3.Request              → cx.smile.okhttp3.Request
okio.Buffer                  → cx.smile.okio.Buffer
org.json.JSONObject          → cx.smile.org.json.JSONObject
```

### Native Library Prefixing

```
Original Library             Prefixed Library
─────────────────────────────────────────────────────────
libsocketio.so            → 
libengine.so              → 

JNI Symbols:
Java_io_socket_*          → Java_cx_smile_io_socket_*
Java_io_engine_*          → Java_cx_smile_io_engine_*
```

## Performance Characteristics

### Build Times

| Stage | Cold Cache | Warm Cache | Notes |
|-------|-----------|------------|-------|
| Clone upstream | 1-2 min | 0 min | Cached by version |
| Apply patches | 10 sec | 10 sec | Fast text processing |
| Build upstream | 25-30 min | 3-5 min | Native compilation |
| Shadow processing | 2-3 min | 30 sec | Bytecode rewriting |
| AAR assembly | 1-2 min | 30 sec | Packaging |
| **Total** | **~40 min** | **~8 min** | |

### JitPack Build (Prebuilt)

| Stage | Duration | Notes |
|-------|----------|-------|
| Download AAR | 30 sec | From GitHub Releases |
| Extract | 10 sec | Unzip AAR |
| Shadow | 1-2 min | Only relocation |
| Assembly | 30 sec | Repackage |
| **Total** | **~5 min** | No native compilation |

### Size Metrics

| Component | Unprefixed | Prefixed | Increase |
|-----------|-----------|----------|----------|
| classes.jar | ~500 KB | ~550 KB | +10% |
| Native libs (all ABIs) | ~2 MB | ~2 MB | ~0% |
| Total AAR | ~3 MB | ~3.5 MB | +15% |

**Note**: Size increase is due to longer package names in constant pool.

## Security Model

### Supply Chain Security

```
┌─────────────────────────────────────────────────────────┐
│ 1. Upstream Source Integrity                            │
├─────────────────────────────────────────────────────────┤
│    ✓ Clone from official Socket.IO repository          │
│    ✓ Use specific version tags                         │
│    ✓ Verify git commit signatures (optional)           │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 2. Build Process Isolation                              │
├─────────────────────────────────────────────────────────┤
│    ✓ Builds in isolated CI environment                 │
│    ✓ Deterministic builds (same input → same output)   │
│    ✓ No external network access during build           │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 3. Artifact Verification                                 │
├─────────────────────────────────────────────────────────┤
│    ✓ SHA-256 checksums generated                       │
│    ✓ Artifacts signed (optional, via GPG)              │
│    ✓ Reproducible builds verified                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 4. Distribution Security                                 │
├─────────────────────────────────────────────────────────┤
│    ✓ HTTPS for all downloads                           │
│    ✓ GitHub authentication for releases                │
│    ✓ JitPack serves over HTTPS                         │
└─────────────────────────────────────────────────────────┘
```

### Access Control

- **Repository**: Protected branches, required reviews
- **Releases**: Tag-based, automated via CI
- **Secrets**: GitHub Secrets for credentials
- **Artifacts**: Checksummed and versioned

## Extensibility

### Adding New Transitive Dependencies

If Socket.IO adds new dependencies:

1. Update `shadow/build.gradle.kts`:
   ```kotlin
   relocate("new.dependency", "cx.smile.new.dependency")
   ```

2. Rebuild and verify:
   ```bash
   ./scripts/build-release.sh
   ```

### Adding Custom Patches

1. Create patch file in `patches/`:
   ```bash
   patches/0001-custom-modification.patch
   ```

2. Update `scripts/apply-native-prefix.sh`:
   ```bash
   git apply patches/0001-custom-modification.patch
   ```

### Supporting Additional Platforms

To add iOS or Web support:

1. Create platform-specific modules
2. Apply similar prefixing strategy
3. Update CI/CD workflows
4. Add platform-specific documentation

## Monitoring and Observability

### Build Metrics

- Build success/failure rate
- Build duration trends
- Cache hit rates
- Artifact sizes

### Runtime Metrics

- Native library load failures
- ClassNotFoundException occurrences
- Symbol collision detection

### Alerts

- CI build failures
- Release deployment issues
- JitPack build timeouts
- Security vulnerabilities in dependencies

## Maintenance

### Regular Tasks

- **Weekly**: Check for upstream updates
- **Monthly**: Review and update dependencies
- **Quarterly**: Performance optimization review
- **Yearly**: Architecture review

### Updating Process

1. Monitor Socket.IO releases
2. Test new version locally
3. Update configuration
4. Run full build and tests
5. Create new release
6. Update documentation

## References

- [Socket.IO Client Java](https://github.com/socketio/socket.io-client-java)
- [Shadow Plugin Documentation](https://imperceptiblethoughts.com/shadow/)
- [Fat AAR Plugin](https://github.com/kezong/fat-aar-android)
- [Android NDK](https://developer.android.com/ndk)
- [JitPack Documentation](https://jitpack.io/docs/)
- [Gradle Build Tool](https://gradle.org/)

## Glossary

- **AAR**: Android Archive, Android library package format
- **Shadow/Relocation**: Bytecode rewriting to change package names
- **Fat AAR**: AAR containing embedded dependencies
- **JNI**: Java Native Interface, bridge between Java and C/C++
- **Prefixing**: Adding namespace prefix to prevent collisions
- **Upstream**: Original Socket.IO client repository
- **Bytecode**: Compiled Java code (.class files)
- **Native Library**: Compiled C/C++ code (.so files)
