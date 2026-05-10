import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read the upload-key credentials from android/key.properties. The file
// is gitignored — the dev keeps it locally and on a backup. Missing-file
// path falls back to debug signing so `flutter run` still works on a
// fresh checkout.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.docscanar.app"
    // Bumped from 34 -> 36 so the `camera` plugin's CameraX 1.5.3 backend
    // compiles. targetSdk stays at 34 per the spec (compileSdk affects
    // available APIs at compile time only, not runtime behavior).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.docscanar.app"
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use the release upload key when the dev has key.properties
            // wired up; otherwise fall through to debug so a clean clone
            // still builds.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 strips classes that ML Kit / AdMob / IAP reach via reflection
            // and the missing-class errors break the build. We ship a
            // `proguard-rules.pro` file with the right keep rules; turn
            // minification back on once you've validated those rules in
            // a release-mode device run.
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

// ML Kit Text Recognition v2 ships one model per script, and the
// google_mlkit_text_recognition plugin marks the non-Latin ones as
// compileOnly so the default APK only carries Latin. Add them as
// `implementation` here so the user's selected script (Chinese,
// Japanese, Korean, Devanagari) actually has a model to load — without
// these, switching the OCR script in Settings would silently fall back
// to Latin every time.
dependencies {
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
}
