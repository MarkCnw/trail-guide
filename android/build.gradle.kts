allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// 🛠️ FIX ISAR NAMESPACE ISSUE
subprojects {
    afterEvaluate {
        if (name == "isar_flutter_libs") {
            try {
                val android = extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
                android?.namespace = "dev.isar.isar_flutter_libs"
            } catch (e: Exception) {
                println("Could not set namespace for isar_flutter_libs: $e")
            }
        }
    }
}

// ✅ เพิ่มส่วนนี้ - บังคับให้ทุก subproject ใช้ compileSdk 35
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            
            when (android) {
                is com.android.build.gradle.LibraryExtension -> {
                    android.compileSdk = 35
                }
                is com.android.build.gradle.AppExtension -> {
                    android.compileSdkVersion(35)
                }
            }
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}