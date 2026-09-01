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

// maplibre_gl's own build.gradle only applies the classic Kotlin Gradle
// Plugin when AGP < 9, assuming AGP 9's built-in Kotlin provides the
// `kotlin {}` extension it needs otherwise. This project (per the Flutter
// template's own gradle.properties: android.builtInKotlin=false) has that
// built-in support turned off, so on AGP 9 the extension never exists and
// the plugin's build fails with "Could not find method kotlin()". Apply
// KGP to that one subproject ourselves to fill the gap until maplibre_gl
// ships a fix (tracked upstream at maplibre/flutter-maplibre-gl).
subprojects {
    if (project.name == "maplibre_gl") {
        pluginManager.apply("org.jetbrains.kotlin.android")
    }
}

// another_telephony pins its own Kotlin compilation to JVM 1.8 but leaves
// its Java compilation on whatever default this toolchain picks (11 here),
// which AGP rejects as an inconsistent JVM target between the two. Bring
// its Java side down to match the Kotlin side it already declares.
subprojects {
    if (project.name == "another_telephony") {
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_1_8
                    targetCompatibility = JavaVersion.VERSION_1_8
                }
            }
        }
    }
}

// tflite_flutter declares its own Java compileOptions at 1.11, but its
// Kotlin compilation (auto-applied, not explicit in its build.gradle) lands
// on this toolchain's default of JVM 21, which AGP again rejects as
// inconsistent — same class of bug as another_telephony above, just the
// other direction: bring its Java side up to 21 to match.
subprojects {
    if (project.name == "tflite_flutter") {
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_21
                    targetCompatibility = JavaVersion.VERSION_21
                }
            }
        }
    }
}

// flutter_ringtone_player hardcodes compileSdkVersion 33 in its own
// build.gradle, but several of its own androidx dependencies (fragment,
// activity, lifecycle-*, core-ktx, etc.) now require compileSdk 34+ —
// AGP's AAR-metadata check rejects that mismatch. Bump it to match the
// rest of this project's toolchain.
subprojects {
    if (project.name == "flutter_ringtone_player") {
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
                compileSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
