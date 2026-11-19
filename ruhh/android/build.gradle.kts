allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    // AGP 8+ requires a namespace. isar_flutter_libs 3.1.0+1 still
    // keeps it only as the manifest package attribute.
    pluginManager.withPlugin("com.android.library") {
        val androidExt =
            extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        if (androidExt.namespace == null) {
            val manifest = file("src/main/AndroidManifest.xml")
            val pkg = Regex("""package="([^"]+)"""")
                .find(manifest.readText())
                ?.groupValues
                ?.getOrNull(1)
            if (pkg != null) androidExt.namespace = pkg
        }
        extensions
            .getByType(
                com.android.build.api.variant.LibraryAndroidComponentsExtension::class.java,
            )
            .finalizeDsl { ext ->
                if ((ext.compileSdk ?: 0) < 36) ext.compileSdk = 36
            }
    }
    pluginManager.withPlugin("org.jetbrains.kotlin.android") {
        extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
