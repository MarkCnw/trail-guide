allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// 🛠️ FIX ISAR NAMESPACE ISSUE (ย้ายมาไว้ตรงนี้! ก่อนส่วนอื่นๆ)
subprojects {
    afterEvaluate {
        if (name == "isar_flutter_libs") {
            try {
                // บังคับใส่ Namespace ให้ Isar
                val android = extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
                android?.namespace = "dev.isar.isar_flutter_libs"
            } catch (e: Exception) {
                println("Could not set namespace for isar_flutter_libs: $e")
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