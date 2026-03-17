plugins {
    `java-library`
    id("com.github.johnrengelman.shadow") version "8.1.1"
}

java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

// This module takes the upstream Socket.IO JAR and relocates its packages
// Package relocation constitutes modification under the original licenses.
// See LICENSE and NOTICE files for complete attribution and compliance information.
tasks.named<com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar>("shadowJar") {
    archiveBaseName.set("shadow")
    archiveClassifier.set("")
    archiveVersion.set("")

    // Include runtime dependencies (Socket.IO + transitive deps)
    configurations = listOf(project.configurations.runtimeClasspath.get())

    // Relocate all Socket.IO packages to cx.smile prefix
    relocate("io.socket", "cx.smile.io.socket")
    relocate("io.engine", "cx.smile.io.engine")

    // Relocate transitive dependencies to avoid conflicts
    relocate("okhttp3", "cx.smile.okhttp3")
    relocate("okio", "cx.smile.okio")
    relocate("org.json", "cx.smile.org.json")

    // Don't minimize - keep all classes
    // minimize() can cause issues with reflection and service loading

    // Merge service files
    mergeServiceFiles()

    // Exclude signatures
    exclude("META-INF/*.SF")
    exclude("META-INF/*.DSA")
    exclude("META-INF/*.RSA")
}

tasks.named("assemble") {
    dependsOn("shadowJar")
}

dependencies {
    // Socket.IO Client Java from Maven Central
    // This automatically includes all transitive dependencies:
    // - io.socket:engine.io-client
    // - com.squareup.okhttp3:okhttp
    // - com.squareup.okio:okio
    // - org.json:json
    implementation("io.socket:socket.io-client:${project.findProperty("UPSTREAM_VERSION") ?: "2.1.0"}")
}
