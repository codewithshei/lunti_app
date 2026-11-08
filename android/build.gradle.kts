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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Raise every Android library subproject — including Flutter plugins such as
// :printing, whose own build.gradle pins an older compileSdk — to the app's
// compileSdk. A library compiled below the minCompileSdk of its AndroidX
// dependencies fails the build with AAR metadata errors such as
// "androidx.arch.core:core-runtime:2.2.0 requires ... compile against version
// 33 or later ... :printing is currently compiled against android-30".
//
// pluginManager.withPlugin is deliberate: the evaluationDependsOn(":app") block
// above can leave a subproject already evaluated, and registering
// afterEvaluate on an evaluated project throws
// "Cannot run Project.afterEvaluate(Action) when the project is already
// evaluated". withPlugin is idempotent — it fires immediately when the plugin is
// already applied and defers otherwise — so it is safe in either order.
//
// This sets the value at plugin-apply time, which is the only window AGP 9
// accepts: setting it later fails with "It is too late to set compileSdk. It has
// already been read to configure this project." A plugin that pins its own lower
// compileSdk in its android {} block therefore still wins, and the only fix for
// those is to raise it in the plugin itself — printing 5.15.1 does exactly that
// (compileSdk 30 -> 34), which is why the app depends on ^5.15.1.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        val android = extensions.findByName("android")
            as? com.android.build.gradle.LibraryExtension
            ?: return@withPlugin
        android.compileSdk = 36
    }
}