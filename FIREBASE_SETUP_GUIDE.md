# 🔥 Guide Configuration Firebase - Notifications Push Art Luxury Bus

## 🚀 Problème : Notifications Push non reçues

Voici la procédure complète pour configurer Firebase et résoudre le problème des notifications push.

## ✅ Étape 1: Configuration Firebase Console

### 1.1 Créer/Configurer le projet Firebase
1. **Aller sur** [Firebase Console](https://console.firebase.google.com/)
2. **Créer un nouveau projet** ou utiliser un existant : `art-luxury-bus`
3. **Activer Cloud Messaging** (FCM) dans le projet

### 1.2 Ajouter l'application Android
1. **Cliquer** "Ajouter une application" → Android
2. **Package name** : `com.artluxurybus.app` (ou votre package)
3. **Télécharger** `google-services.json`
4. **Placer** le fichier dans : `/android/app/google-services.json`

### 1.3 Ajouter l'application iOS (optionnel)
1. **Cliquer** "Ajouter une application" → iOS
2. **Bundle ID** : `com.artluxurybus.app`
3. **Télécharger** `GoogleService-Info.plist`
4. **Placer** le fichier dans : `/ios/Runner/GoogleService-Info.plist`

## ✅ Étape 2: Configuration Android

### 2.1 Modifier `android/build.gradle.kts`
```kotlin
dependencies {
    classpath("com.android.tools.build:gradle:8.1.4")
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10")
    classpath("com.google.gms:google-services:4.4.0") // Ajouter cette ligne
}
```

### 2.2 Modifier `android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Ajouter cette ligne
}

dependencies {
    implementation("com.google.firebase:firebase-messaging:23.4.0")
    implementation("androidx.multidex:multidex:2.0.1")
}
```

### 2.3 Modifier `android/app/src/main/AndroidManifest.xml`
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permissions pour notifications -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
    
    <application
        android:label="Art Luxury Bus"
        android:name="androidx.multidex.MultiDexApplication"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Service Firebase Messaging -->
        <service
            android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
        
        <!-- Metadata Firebase -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="art_luxury_bus_channel" />
            
        <!-- Activité principale -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:windowSoftInputMode="adjustResize">
            
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
        </activity>
    </application>
</manifest>
```

### 2.4 Créer `android/app/src/main/res/values/colors.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#1976D2</color>
</resources>
```

## ✅ Étape 3: Configuration iOS (si applicable)

### 3.1 Modifier `ios/Runner/Info.plist`
```xml
<dict>
    <!-- ... autres configurations ... -->
    
    <!-- Firebase -->
    <key>FirebaseAppDelegateProxyEnabled</key>
    <false/>
    
    <!-- Notifications -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>remote-notification</string>
    </array>
</dict>
```

### 3.2 Modifier `ios/Runner/AppDelegate.swift`
```swift
import UIKit
import Flutter
import Firebase
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## ✅ Étape 4: Test des Notifications

### 4.1 Commandes pour tester
```bash
# Nettoyer et reconstruire
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter clean
flutter pub get
flutter run
```

### 4.2 Tester depuis Firebase Console
1. **Aller dans** Firebase Console → Cloud Messaging
2. **Cliquer** "Envoyer votre premier message"
3. **Titre** : "Test Art Luxury Bus"
4. **Corps** : "Test des notifications push"
5. **Sélectionner** votre application
6. **Envoyer** maintenant

### 4.3 Tester depuis votre backend Laravel
```bash
# Tester l'endpoint de configuration
curl -X GET https://gestion-compagny.universaltechnologiesafrica.com/api/notifications/test-config \
  -H "Authorization: Bearer YOUR_TOKEN"

# Envoyer une notification test
curl -X POST https://gestion-compagny.universaltechnologiesafrica.com/api/notifications/send-test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","message":"Test notification","user_ids":[1]}'
```

## ✅ Étape 5: Vérifications de Debug

### 5.1 Logs à surveiller
```dart
// Dans les logs Flutter/Android Studio
✅ Firebase initialisé
📱 Token FCM: eQg7Z2mKTR6...
✅ Permissions accordées
✅ Token enregistré sur le serveur
📨 Notification reçue en premier plan: Test
```

### 5.2 Problèmes courants

| Problème | Solution |
|----------|----------|
| `MissingPluginException` | Faire `flutter clean && flutter run` |
| Token FCM null | Vérifier google-services.json |
| Permissions refusées | Réinstaller l'app et accepter |
| Notifications en arrière-plan | Vérifier AndroidManifest.xml |
| Serveur non joignable | Vérifier l'URL backend |

## ✅ Étape 6: Provider Riverpod pour Notifications

### 6.1 Ajouter dans HomePage
```dart
// Dans _HomePageState
@override
void initState() {
  super.initState();
  
  // Écouter les notifications
  NotificationService.notificationStream?.listen((notification) {
    if (notification['type'] == 'tap') {
      _handleNotificationNavigation(notification);
    }
  });
}

void _handleNotificationNavigation(Map<String, dynamic> notification) {
  String type = notification['notification_type'] ?? '';
  
  switch (type) {
    case 'new_feedback':
      // Naviguer vers liste feedbacks
      break;
    case 'urgent_feedback':
      // Naviguer vers feedback spécifique
      break;
  }
}
```

## 🔧 Fichiers à créer/modifier

### Obligatoires :
- ✅ `/lib/services/notification_service.dart` (créé)
- ⏳ `/android/app/google-services.json` (à télécharger)
- ⏳ `/android/app/src/main/res/values/colors.xml` (à créer)
- ⏳ Modifier `android/build.gradle.kts` et `android/app/build.gradle.kts`
- ⏳ Modifier `android/app/src/main/AndroidManifest.xml`

### Optionnels (iOS) :
- `/ios/Runner/GoogleService-Info.plist`
- Modifier `ios/Runner/Info.plist`
- Modifier `ios/Runner/AppDelegate.swift`

## 🎯 Actions Immédiates

1. **Télécharger** `google-services.json` depuis Firebase Console
2. **Placer** le fichier dans `/android/app/`
3. **Modifier** les fichiers de configuration Android
4. **Faire** `flutter clean && flutter pub get && flutter run`
5. **Tester** une notification depuis Firebase Console

Une fois ces étapes suivies, les notifications push devraient fonctionner ! 🎉

## 📞 Support

Si le problème persiste :
1. **Vérifier** les logs dans Android Studio/VS Code
2. **Tester** avec le simulateur ET un appareil physique
3. **Confirmer** que le backend Laravel est bien configuré avec Firebase
4. **Vérifier** que l'URL `https://gestion-compagny.universaltechnologiesafrica.com/api` est accessible
