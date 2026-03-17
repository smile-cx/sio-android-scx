// Top-level build file
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.2")
    }
}

plugins {
    id("com.android.library") version "8.2.2" apply false
    id("com.github.johnrengelman.shadow") version "8.1.1" apply false
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
