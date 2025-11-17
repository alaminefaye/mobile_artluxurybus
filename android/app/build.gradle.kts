import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Configuration du keystore pour la signature en mode release
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "ci.artluxurybus.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Flag pour activer core library desugaring
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
    
    // Supprimer les warnings Java 8 pour toutes les tâches de compilation
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
        options.compilerArgs.addAll(listOf("-Xlint:-options"))
    }

    // Configuration de la signature
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ci.artluxurybus.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // CRITIQUE: Désactiver testOnly pour permettre l'upload sur Google Play
        manifestPlaceholders["testOnly"] = "false"
        
        // Support pour les grands écrans et différentes densités
        multiDexEnabled = true
        
        // Configuration pour totems (grands écrans)
        resConfigs("fr", "en") // Limiter aux langues nécessaires pour réduire la taille
    }

    buildTypes {
        debug {
            // IMPORTANT: Mode debug ne doit PAS utiliser la signature release
            // Pas de signingConfig spécifié = utilise la clé debug par défaut
            
            // Désactiver le stripping des symboles natifs pour éviter les erreurs
            ndk {
                debugSymbolLevel = "NONE"
            }
        }
        release {
            // CRITIQUE: Utiliser UNIQUEMENT la configuration de signature release
            signingConfig = signingConfigs.getByName("release")
            
            // Vérifier que la signature est bien configurée
            if (signingConfig == null) {
                throw GradleException("La configuration de signature release n'est pas définie!")
            }
            
            // Désactiver le shrinking qui peut causer des crashes
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Marquer explicitement comme release (pas debuggable)
            isDebuggable = false
            isJniDebuggable = false
            
            // IMPORTANT: Marquer comme version de production
            manifestPlaceholders["isTestMode"] = "false"
            
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
