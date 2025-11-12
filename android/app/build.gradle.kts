plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter plugin must come after Android and Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.kwt"

    // 🔧 Fix: Explicitly set compileSdk for qr_code_scanner_plus
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.kwt"
        minSdk = 23                // Safe minimum for Flutter plugins
        targetSdk = 36             // Match compileSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        // 🔧 Fix: Upgrade Java compatibility to 17 (avoid warnings)
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // 🔧 Fix: JVM target for modern Kotlin compiler
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
