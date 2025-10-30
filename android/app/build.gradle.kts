plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.artluxurybus"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Flag pour activer core library desugaring
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    // Supprimer les warnings Java 8
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf("-Xlint:-options"))
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.artluxurybus"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Support pour les grands écrans et différentes densités
        multiDexEnabled = true
        
        // Configuration pour totems (grands écrans)
        resConfigs("fr", "en") // Limiter aux langues nécessaires pour réduire la taille
    }

    buildTypes {
        debug {
            // Désactiver le stripping des symboles natifs pour éviter les erreurs
            ndk {
                debugSymbolLevel = "NONE"
            }
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Désactiver le shrinking qui peut causer des crashes
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Configuration ProGuard si nécessaire
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    buildFeatures {
        buildConfig = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring pour les fonctionnalités Java 8+
    // Version 2.1.4+ requise par flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // MultiDex support pour les grands écrans et applications volumineuses
    implementation("androidx.multidex:multidex:2.0.1")
}
