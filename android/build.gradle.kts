import com.android.build.gradle.BaseExtension

subprojects {
    afterEvaluate {
        if (project.name == "flutter_bluetooth_serial_ble" || project.name == "flutter_bluetooth_serial") {
            extensions.findByType(BaseExtension::class.java)?.let { android ->
                if (android.namespace == null) {
                    android.namespace = "io.github.edufolly.flutterbluetoothserial"
                }
            }
        }
    }
}
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

