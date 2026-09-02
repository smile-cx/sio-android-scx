// Top-level build file
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:9.4.0")
    }
}

plugins {
    id("com.android.library") version "9.4.0" apply false
    id("com.gradleup.shadow") version "9.6.1" apply false
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
