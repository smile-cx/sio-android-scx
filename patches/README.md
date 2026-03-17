# Patches Directory

This directory contains patches to be applied to the upstream Socket.IO client source code for native library prefixing.

## Patch Application

Patches are automatically applied by `scripts/apply-native-prefix.sh` during the build process.

## Example Patches

While the build script applies prefixes programmatically, you can add custom patches here for specific edge cases:

### Example: Custom Native Library Patch

```patch
--- a/socket.io-client/src/main/cpp/CMakeLists.txt
+++ b/socket.io-client/src/main/cpp/CMakeLists.txt
@@ -1,7 +1,7 @@
 cmake_minimum_required(VERSION 3.10)

-project("socket.io")
+project("scx_socket.io")

-add_library(socketio SHARED
+add_library(scx_socketio SHARED
         native-lib.cpp)
```

### Example: JNI Header Patch

```patch
--- a/socket.io-client/src/main/cpp/native-lib.h
+++ b/socket.io-client/src/main/cpp/native-lib.h
@@ -5,10 +5,10 @@
 extern "C" {
 #endif

-JNIEXPORT void JNICALL Java_io_socket_client_NativeHelper_init
+JNIEXPORT void JNICALL Java_cx_smile_io_socket_client_NativeHelper_init
   (JNIEnv *, jobject);

-JNIEXPORT void JNICALL Java_io_socket_client_NativeHelper_cleanup
+JNIEXPORT void JNICALL Java_cx_smile_io_socket_client_NativeHelper_cleanup
   (JNIEnv *, jobject);

 #ifdef __cplusplus
```

## Creating New Patches

If the automated patching doesn't cover a specific case:

1. Make changes to the upstream source manually
2. Generate a patch:
   ```bash
   cd upstream-source/source
   git diff > ../../patches/0001-description.patch
   ```
3. Add patch application to `scripts/apply-native-prefix.sh`:
   ```bash
   git apply patches/0001-description.patch
   ```

## Patch Naming Convention

Use numbered prefixes for ordered application:
- `0001-prefix-cmake-files.patch`
- `0002-update-jni-symbols.patch`
- `0003-fix-special-case.patch`

## Note

Most Socket.IO client Java versions don't include native code. If native components are added in future versions, create appropriate patches here.
