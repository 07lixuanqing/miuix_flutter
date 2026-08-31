plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystorePath = providers.gradleProperty("MIUIX_RELEASE_KEYSTORE")
    .orElse(providers.environmentVariable("MIUIX_RELEASE_KEYSTORE"))
    .orNull
val releaseStorePassword = providers.gradleProperty("MIUIX_RELEASE_STORE_PASSWORD")
    .orElse(providers.environmentVariable("MIUIX_RELEASE_STORE_PASSWORD"))
    .orNull
val releaseKeyAlias = providers.gradleProperty("MIUIX_RELEASE_KEY_ALIAS")
    .orElse(providers.environmentVariable("MIUIX_RELEASE_KEY_ALIAS"))
    .orNull
val releaseKeyPassword = providers.gradleProperty("MIUIX_RELEASE_KEY_PASSWORD")
    .orElse(providers.environmentVariable("MIUIX_RELEASE_KEY_PASSWORD"))
    .orNull
val allowTestReleaseSigning = providers.gradleProperty("MIUIX_ALLOW_TEST_SIGNING")
    .orElse(providers.environmentVariable("MIUIX_ALLOW_TEST_SIGNING"))
    .map(String::toBoolean)
    .getOrElse(false)
val productionSigningValues = listOf(
    releaseKeystorePath,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
)
val hasAnyProductionSigningValue = productionSigningValues.any { !it.isNullOrBlank() }
val hasCompleteProductionSigning = productionSigningValues.all { !it.isNullOrBlank() }
if (hasAnyProductionSigningValue && !hasCompleteProductionSigning) {
    throw GradleException(
        "Production signing is incomplete. Provide MIUIX_RELEASE_KEYSTORE, " +
            "MIUIX_RELEASE_STORE_PASSWORD, MIUIX_RELEASE_KEY_ALIAS, and " +
            "MIUIX_RELEASE_KEY_PASSWORD together.",
    )
}
if (!hasCompleteProductionSigning && !allowTestReleaseSigning) {
    gradle.taskGraph.whenReady {
        if (allTasks.any { it.name.contains("Release", ignoreCase = true) }) {
            throw GradleException(
                "Release signing was not selected. Use the repository build " +
                    "script for an explicit test-signed build, or provide all " +
                    "MIUIX_RELEASE_* production signing values.",
            )
        }
    }
}

android {
    namespace = "com.xinxin.miuix_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.xinxin.miuix_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasCompleteProductionSigning) {
            create("productionRelease") {
                val keystore = file(releaseKeystorePath!!)
                if (!keystore.isFile) {
                    throw GradleException(
                        "Production keystore does not exist: ${keystore.absolutePath}",
                    )
                }
                storeFile = keystore
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                hasCompleteProductionSigning ->
                    signingConfigs.getByName("productionRelease")
                allowTestReleaseSigning -> signingConfigs.getByName("debug")
                else -> null
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
