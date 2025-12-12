pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    // 👇 แก้ตรงนี้ครับ! เปลี่ยนจาก PREFER_SETTINGS เป็น PREFER_PROJECT
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT) 
    
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        // เพิ่มบรรทัดนี้กันเหนียว สำหรับโหลดของ Flutter โดยเฉพาะ
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") } 
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")