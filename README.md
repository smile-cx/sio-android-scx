# SCX Socket.IO Client for Android

Modified and prefixed distribution of [socket.io-client-java](https://github.com/socketio/socket.io-client-java) to avoid symbol collisions.

**Note**: This is not an official Socket.IO distribution. This repository redistributes Socket.IO Client for Java and its dependencies with package relocation applied. All original libraries are modified through bytecode transformation to add the `cx.smile.` package prefix.

## Features

- **Java Package Prefix**: `cx.smile.` (e.g., `cx.smile.io.socket.client`)
- **Bytecode Relocation**: All package references updated automatically
- **Transitive Dependencies**: okhttp3, okio, and other dependencies also prefixed

## Distribution

### Via JitPack

Add JitPack repository:
```gradle
repositories {
    maven { url 'https://jitpack.io' }
}
```

Add dependency:
```gradle
dependencies {
    implementation 'com.github.smile-cx:sio-android-scx:2.1.0'
}
```

### Via GitHub Releases

Download the prefixed AAR from [Releases](../../releases).

## Building from Source

### Prerequisites

- JDK 17+
- Android SDK (API 21+)
- Gradle 8.0+

### Build Command

```bash
./gradlew assembleRelease
```

This will produce `sio-android-scx-release.aar` in `app/build/outputs/aar/`.

## Architecture

This build pipeline uses a streamlined approach:

1. **Download**: Fetch Socket.IO client from Maven Central via Gradle dependency
2. **Relocation**: Shadow plugin relocates Java packages via bytecode rewriting
3. **Packaging**: Embed shadowed JAR into Android AAR library

## CI/CD

GitHub Actions automatically:
- Builds prefixed AAR on push to tags
- Uploads artifacts to GitHub Releases
- Enables JitPack distribution

## License and Third-Party Notices

This repository contains build infrastructure (Smile CX, MIT License) and redistributes modified third-party software components with package relocation applied.

### Bundled Components

This distribution bundles the following third-party software:

1. **Socket.IO Client for Java** (MIT License)
   - Copyright (c) 2014 Naoyuki Kanezawa
   - Copyright (c) 2023 Socket.IO
   - Modified: Package relocation from `io.socket.*` to `cx.smile.io.socket.*`

2. **Engine.IO Client for Java** (MIT License)
   - Copyright (c) 2014 Naoyuki Kanezawa
   - Modified: Package relocation from `io.engine.*` to `cx.smile.io.engine.*`

3. **OkHttp** (Apache License 2.0)
   - Copyright (c) Square, Inc.
   - Modified: Package relocation from `okhttp3.*` to `cx.smile.okhttp3.*`

4. **Okio** (Apache License 2.0)
   - Copyright (c) Square, Inc.
   - Modified: Package relocation from `okio.*` to `cx.smile.okio.*`

5. **JSON in Java** (Custom License - "Good, not Evil")
   - Copyright (c) 2002 JSON.org
   - Modified: Package relocation from `org.json.*` to `cx.smile.org.json.*`

All modifications are limited to package namespace changes via Gradle Shadow plugin bytecode rewriting. No functional changes have been made to the original libraries.

### License Files

- [LICENSE](LICENSE) - Complete license texts for all components
- [NOTICE](NOTICE) - Detailed attribution and modification notices
- [UPSTREAM_LICENSE](UPSTREAM_LICENSE) - Original Socket.IO Client license (preserved for reference)

Users of this distribution must comply with all applicable license terms, including:
- Preserving copyright notices and license texts in redistributions
- Including the NOTICE file in distributions
- Complying with Apache 2.0 requirements for OkHttp and Okio
- Complying with the JSON.org license terms

For the official, unmodified Socket.IO Client for Java, see: https://github.com/socketio/socket.io-client-java
