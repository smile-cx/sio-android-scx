# Add project specific ProGuard rules here.

# Keep prefixed Socket.IO classes
-keep class cx.smile.io.socket.** { *; }
-keep class cx.smile.io.engine.** { *; }

# Socket.IO event handlers
-keepclassmembers class * {
    @cx.smile.io.socket.client.On *;
}
