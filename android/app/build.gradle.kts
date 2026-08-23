plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val productionSigningVariableNames =
    listOf(
        "CLOCK_RHYTHM_ANDROID_KEYSTORE",
        "CLOCK_RHYTHM_ANDROID_KEY_ALIAS",
        "CLOCK_RHYTHM_ANDROID_STORE_PASSWORD",
        "CLOCK_RHYTHM_ANDROID_KEY_PASSWORD",
    )
val productionSigningValues =
    productionSigningVariableNames.associateWith { variableName ->
        providers.environmentVariable(variableName).orNull
    }
val missingProductionSigningVariables =
    productionSigningValues
        .filterValues { value -> value.isNullOrBlank() }
        .keys
        .sorted()
val requestsProductionRelease =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("ProductionRelease", ignoreCase = true)
    }
val validateProductionSigningConfiguration = {
    if (missingProductionSigningVariables.isNotEmpty()) {
        throw GradleException(
            "Production Android signing credentials are missing: " +
                missingProductionSigningVariables.joinToString(", "),
        )
    }
    val keystore =
        file(productionSigningValues.getValue("CLOCK_RHYTHM_ANDROID_KEYSTORE")!!)
            .canonicalFile
    val repositoryRoot = rootProject.projectDir.parentFile.canonicalFile
    if (keystore.toPath().startsWith(repositoryRoot.toPath())) {
        throw GradleException(
            "Production Android keystore must be stored outside the repository.",
        )
    }
    if (!keystore.isFile) {
        throw GradleException("Production Android keystore file does not exist.")
    }
}
if (requestsProductionRelease) {
    validateProductionSigningConfiguration()
}

android {
    namespace = "dev.wndls.clockrhythm"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 24
        targetSdk = 36
        multiDexEnabled = true
        versionCode = 1
    }

    flavorDimensions += "releaseChannel"
    productFlavors {
        create("beta") {
            dimension = "releaseChannel"
            applicationId = "dev.wndls.clockrhythm.beta"
            versionCode = 1
            versionName = "0.1.0"
            buildConfigField(
                "String",
                "RHYTHM_NOTIFICATION_CHANNEL_ID",
                "\"dev.wndls.clockrhythm.beta.rhythm-events\"",
            )
        }
        create("production") {
            dimension = "releaseChannel"
            applicationId = "dev.wndls.clockrhythm"
            versionCode = 1
            versionName = "1.0.0"
            buildConfigField(
                "String",
                "RHYTHM_NOTIFICATION_CHANNEL_ID",
                "\"dev.wndls.clockrhythm.rhythm-events\"",
            )
        }
    }

    signingConfigs {
        if (missingProductionSigningVariables.isEmpty()) {
            create("production") {
                storeFile = file(productionSigningValues.getValue("CLOCK_RHYTHM_ANDROID_KEYSTORE")!!)
                keyAlias = productionSigningValues.getValue("CLOCK_RHYTHM_ANDROID_KEY_ALIAS")
                storePassword = productionSigningValues.getValue("CLOCK_RHYTHM_ANDROID_STORE_PASSWORD")
                keyPassword = productionSigningValues.getValue("CLOCK_RHYTHM_ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        getByName("release") {
            productFlavors.getByName("beta").signingConfig =
                signingConfigs.getByName("debug")
            if (missingProductionSigningVariables.isEmpty()) {
                productFlavors.getByName("production").signingConfig =
                    signingConfigs.getByName("production")
            }
        }
    }

    buildFeatures {
        buildConfig = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

val validateProductionReleaseSigning =
    tasks.register("validateProductionReleaseSigning") {
        group = "verification"
        description = "Validates external production Android signing credentials."
        doLast {
            validateProductionSigningConfiguration()
        }
    }

tasks.configureEach {
    if (name in setOf("assembleProductionRelease", "bundleProductionRelease")) {
        dependsOn(validateProductionReleaseSigning)
    }
}

val debugFlavorNames = listOf("Beta", "Production")
val rhythmDebugUnitTestTasks =
    debugFlavorNames.associateWith { flavorName ->
        tasks.register<JavaExec>("testRhythm${flavorName}DebugUnitTest") {
            group = "verification"
            description =
                "Runs app-owned Android Rhythm $flavorName unit tests without external test libraries."
            dependsOn("compile${flavorName}DebugUnitTestKotlin")
            mainClass.set(
                "dev.wndls.clockrhythm.rhythm.RhythmDeliveryTestRunner",
            )
            workingDir = project.projectDir
            doFirst {
                val androidUnitTest =
                    tasks.named<Test>("test${flavorName}DebugUnitTest").get()
                classpath =
                    files(
                        layout.buildDirectory.dir(
                            "tmp/kotlin-classes/${flavorName.lowercase()}DebugUnitTest",
                        ),
                    ) +
                    files(
                        layout.buildDirectory.dir(
                            "tmp/kotlin-classes/${flavorName.lowercase()}Debug",
                        ),
                    ) +
                    androidUnitTest.classpath
            }
        }
    }

tasks.withType<Test>().matching { task ->
    task.name in debugFlavorNames.map { flavorName ->
        "test${flavorName}DebugUnitTest"
    }
}.configureEach {
    failOnNoDiscoveredTests = false
    val flavorName = name.removePrefix("test").removeSuffix("DebugUnitTest")
    dependsOn(rhythmDebugUnitTestTasks.getValue(flavorName))
}

tasks.register("testDebugUnitTest") {
    group = "verification"
    description = "Runs beta and production Android debug unit tests."
    dependsOn(debugFlavorNames.map { flavorName -> "test${flavorName}DebugUnitTest" })
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
