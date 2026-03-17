plugins {
    id("com.android.library")
    `maven-publish`
}

android {
    namespace = "cx.smile.io.socket"
    compileSdk = 34

    defaultConfig {
        minSdk = 21

        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

// Task to copy shadow JAR into libs directory which Android automatically includes
val copyShadowJar = tasks.register<Copy>("copyShadowJar") {
    dependsOn(":shadow:shadowJar")
    from(project(":shadow").layout.buildDirectory.file("libs/shadow.jar"))
    into(projectDir.resolve("libs"))
}

dependencies {
    // Include the shadow JAR from libs directory
    // This will be automatically bundled into the AAR
    api(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar"))))
}

// Make pre-build depend on copying shadow JAR
tasks.named("preBuild") {
    dependsOn(copyShadowJar)
}

// Maven publishing configuration
afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                from(components["release"])

                groupId = findProperty("GROUP") as String? ?: "cx.smile.socketio"
                artifactId = findProperty("POM_ARTIFACT_ID") as String? ?: "sio-android-scx"
                version = findProperty("VERSION_NAME") as String? ?: "2.1.0"

                pom {
                    name.set("SCX Socket.IO Client")
                    description.set("Modified Socket.IO client for Android with package relocation to avoid symbol collisions. Bundles Socket.IO (MIT), OkHttp/Okio (Apache 2.0), and org.json. See LICENSE and NOTICE for complete attribution.")
                    url.set("https://github.com/smile-cx/sio-android-scx")

                    licenses {
                        license {
                            name.set("Multiple Licenses")
                            url.set("https://github.com/smile-cx/sio-android-scx/blob/main/LICENSE")
                            comments.set("This distribution includes MIT, Apache 2.0, and custom licensed components. See LICENSE file for complete license texts.")
                        }
                    }

                    developers {
                        developer {
                            id.set("smilecx")
                            name.set("Smile CX")
                        }
                    }

                    scm {
                        connection.set("scm:git:git://github.com/smile-cx/sio-android-scx.git")
                        developerConnection.set("scm:git:ssh://github.com/smile-cx/sio-android-scx.git")
                        url.set("https://github.com/smile-cx/sio-android-scx")
                    }
                }
            }
        }
    }
}
