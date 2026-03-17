# Usage Guide

This guide shows how to use the prefixed Socket.IO client in your Android application.

## Installation

### Method 1: JitPack (Recommended)

Add JitPack repository to your project's `settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```

Or in legacy `build.gradle`:
```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

Add dependency to your app's `build.gradle.kts`:
```kotlin
dependencies {
    implementation("com.github.smile-cx:sio-android-scx:v2.1.0")
}
```

### Method 2: Direct AAR

1. Download `sio-android-scx-release.aar` from [Releases](../../releases)
2. Place in `app/libs/`
3. Add dependency:

```kotlin
dependencies {
    implementation(files("libs/sio-android-scx-release.aar"))
}
```

## Basic Usage

### Connecting to a Server

```java
import cx.smile.io.socket.client.IO;
import cx.smile.io.socket.client.Socket;

try {
    Socket socket = IO.socket("http://localhost:3000");
    socket.connect();
} catch (URISyntaxException e) {
    e.printStackTrace();
}
```

### Listening for Events

```java
socket.on(Socket.EVENT_CONNECT, args -> {
    Log.d("Socket", "Connected");
});

socket.on(Socket.EVENT_DISCONNECT, args -> {
    Log.d("Socket", "Disconnected");
});

socket.on("message", args -> {
    String message = (String) args[0];
    Log.d("Socket", "Received: " + message);
});
```

### Emitting Events

```java
socket.emit("message", "Hello, Server!");

// With acknowledgment
socket.emit("message", "Hello", (Ack) args -> {
    Log.d("Socket", "Server acknowledged");
});
```

### Disconnecting

```java
socket.disconnect();
```

## Advanced Usage

### Connection Options

```java
IO.Options options = new IO.Options();
options.transports = new String[]{"websocket"};
options.reconnection = true;
options.reconnectionDelay = 1000;
options.reconnectionAttempts = 10;

Socket socket = IO.socket("http://localhost:3000", options);
```

### Namespaces

```java
Socket socket = IO.socket("http://localhost:3000/chat");
socket.connect();
```

### SSL/TLS

```java
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

IO.Options options = new IO.Options();
options.secure = true;

// For self-signed certificates (development only)
TrustManager[] trustAllCerts = new TrustManager[]{
    new X509TrustManager() {
        public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[]{}; }
        public void checkClientTrusted(X509Certificate[] chain, String authType) {}
        public void checkServerTrusted(X509Certificate[] chain, String authType) {}
    }
};

SSLContext sslContext = SSLContext.getInstance("TLS");
sslContext.init(null, trustAllCerts, new SecureRandom());
options.sslContext = sslContext;
options.hostnameVerifier = (hostname, session) -> true;

Socket socket = IO.socket("https://localhost:3000", options);
```

## Kotlin Example

```kotlin
import cx.smile.io.socket.client.IO
import cx.smile.io.socket.client.Socket
import java.net.URISyntaxException

class SocketManager {
    private lateinit var socket: Socket

    fun connect() {
        try {
            val options = IO.Options().apply {
                transports = arrayOf("websocket")
                reconnection = true
            }

            socket = IO.socket("http://localhost:3000", options)

            socket.on(Socket.EVENT_CONNECT) {
                println("Connected")
            }

            socket.on(Socket.EVENT_DISCONNECT) {
                println("Disconnected")
            }

            socket.on("message") { args ->
                val message = args[0] as String
                println("Received: $message")
            }

            socket.connect()
        } catch (e: URISyntaxException) {
            e.printStackTrace()
        }
    }

    fun sendMessage(message: String) {
        socket.emit("message", message)
    }

    fun disconnect() {
        socket.disconnect()
    }
}
```

## Android Lifecycle Integration

```kotlin
class ChatActivity : AppCompatActivity() {
    private lateinit var socket: Socket

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        socket = IO.socket("http://localhost:3000")
        socket.connect()
    }

    override fun onDestroy() {
        super.onDestroy()
        socket.disconnect()
    }
}
```

## ProGuard/R8

ProGuard rules are included automatically via consumer ProGuard files. If needed, add:

```proguard
-keep class cx.smile.io.socket.** { *; }
-keep class cx.smile.io.engine.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
```

## Permissions

Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Avoiding Conflicts

This library is prefixed to avoid conflicts with other Socket.IO implementations. You can safely use both:

```kotlin
// Prefixed version (this library)
import cx.smile.io.socket.client.IO as SCXIO

// Original version (if also present)
import io.socket.client.IO

val scxSocket = SCXIO.socket("http://localhost:3000")
val originalSocket = IO.socket("http://localhost:4000")
```

Both instances will work independently without symbol collisions.

## Troubleshooting

### Connection Issues

```kotlin
socket.on(Socket.EVENT_CONNECT_ERROR) { args ->
    val error = args[0] as Exception
    Log.e("Socket", "Connection error: ${error.message}")
}
```

### Network Security Configuration

For cleartext traffic (HTTP), add to `AndroidManifest.xml`:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config">
    ...
</application>
```

Create `res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>
</network-security-config>
```

## Migration from Original Socket.IO

If migrating from the original Socket.IO client:

1. Update imports:
   ```kotlin
   // Before
   import io.socket.client.IO

   // After
   import cx.smile.io.socket.client.IO
   ```

2. Update ProGuard rules (if custom):
   ```proguard
   # Before
   -keep class io.socket.** { *; }

   # After
   -keep class cx.smile.io.socket.** { *; }
   ```

3. Everything else remains the same - the API is identical

## Example Application

See the [examples](examples/) directory for complete sample applications:
- Basic chat client
- Room-based messaging
- Binary data transfer
- Acknowledgments and callbacks

## Further Reading

- [Socket.IO Official Documentation](https://socket.io/docs/v4/)
- [Android Network Guide](https://developer.android.com/training/basics/network-ops)
- [BUILD_GUIDE.md](BUILD_GUIDE.md) - How this library is built
