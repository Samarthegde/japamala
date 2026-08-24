plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.eterniqo.japamala"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications, which uses java.time APIs
        // unavailable on older Android versions without desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }
    kotlin {
    jvmToolchain(21)
}

    defaultConfig {
        applicationId = "in.eterniqo.japamala"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

 signingConfigs {
        create("release") {
            val keyAliasStr = keystoreProperties["keyAlias"] as? String
            val keyPasswordStr = keystoreProperties["keyPassword"] as? String
            val storeFilePath = keystoreProperties["storeFile"] as? String
            val storePasswordStr = keystoreProperties["storePassword"] as? String

            if (!storeFilePath.isNullOrEmpty() && !keyAliasStr.isNullOrEmpty()) {
                keyAlias = keyAliasStr
                keyPassword = keyPasswordStr
                storeFile = file(storeFilePath)
                storePassword = storePasswordStr
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}


flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
