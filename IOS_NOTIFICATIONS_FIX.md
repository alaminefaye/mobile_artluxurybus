# 🔧 Fix Notifications iOS - Art Luxury Bus

## ❌ Problème
Les notifications fonctionnent sur Android mais **PAS sur iOS**.

## 🔍 Diagnostic

### Configuration Actuelle (Vérifiée ✅)
1. ✅ Firebase configuré (`GoogleService-Info.plist` présent)
2. ✅ `AppDelegate.swift` avec Firebase initialisé
3. ✅ Permissions dans `Info.plist` (UIBackgroundModes)
4. ✅ Code Flutter pour notifications (NotificationService)

### ⚠️ Problèmes Identifiés

#### 1. **Certificat APNs Manquant** (Cause Principale)
iOS nécessite un certificat APNs (Apple Push Notification service) configuré dans Firebase Console.

#### 2. **Capabilities Xcode Non Configurées**
Les capacités Push Notifications doivent être activées dans Xcode.

#### 3. **Entitlements Manquant**
Fichier `.entitlements` absent pour les permissions iOS.

---

## 🛠️ Solutions

### Solution 1: Configurer APNs dans Firebase Console

#### Étape 1: Obtenir la clé APNs
1. Aller sur [Apple Developer](https://developer.apple.com/account/resources/authkeys/list)
2. Cliquer sur **"+"** pour créer une nouvelle clé
3. Cocher **"Apple Push Notifications service (APNs)"**
4. Télécharger le fichier `.p8`
5. Noter le **Key ID** et **Team ID**

#### Étape 2: Ajouter la clé dans Firebase
1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner le projet **artluxurybus-d7a63**
3. Aller dans **Project Settings** (⚙️) > **Cloud Messaging**
4. Dans la section **Apple app configuration**:
   - Cliquer sur **Upload** sous "APNs Authentication Key"
   - Uploader le fichier `.p8`
   - Entrer le **Key ID**
   - Entrer le **Team ID**
5. Sauvegarder

---

### Solution 2: Activer Push Notifications dans Xcode

#### Méthode Automatique (Recommandée)
```bash
cd ios
open Runner.xcworkspace
```

Dans Xcode:
1. Sélectionner le projet **Runner** dans le navigateur
2. Sélectionner la target **Runner**
3. Aller dans l'onglet **Signing & Capabilities**
4. Cliquer sur **"+ Capability"**
5. Ajouter **"Push Notifications"**
6. Ajouter **"Background Modes"** et cocher:
   - ✅ Remote notifications
   - ✅ Background fetch

---

### Solution 3: Créer le fichier Entitlements

Créer le fichier `/ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <!-- Pour production, changer en: <string>production</string> -->
</dict>
</plist>
```

---

### Solution 4: Vérifier le Bundle ID

Le Bundle ID doit correspondre exactement entre:
- Firebase Console: `com.example.artluxurybus`
- Xcode: `com.example.artluxurybus`
- Apple Developer: `com.example.artluxurybus`

---

### Solution 5: Mettre à jour AppDelegate.swift

Le fichier est déjà correct, mais vérifier qu'il contient bien:

```swift
import Firebase
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configurer Firebase
    FirebaseApp.configure()
    
    // Demander les permissions pour les notifications
    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        if granted {
          print("✅ Permissions notifications accordées")
        } else {
          print("❌ Permissions notifications refusées")
        }
      }
    )
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Callback pour le token APNs
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("✅ Token APNs reçu: \(deviceToken)")
  }
  
  // Callback en cas d'erreur
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Erreur enregistrement notifications: \(error)")
  }
  
  // Gestion des notifications en arrière-plan
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📬 Notification reçue: \(userInfo)")
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}
```

---

## 🧪 Tests

### Test 1: Vérifier les logs Xcode
```bash
# Lancer l'app en mode debug depuis Xcode
# Vérifier dans la console:
✅ Permissions notifications accordées
✅ Token APNs reçu: <...>
✅ Token FCM obtenu avec succès
```

### Test 2: Envoyer une notification test depuis Firebase
1. Firebase Console > Cloud Messaging
2. Cliquer sur **"Send your first message"**
3. Entrer un titre et message
4. Cliquer sur **"Send test message"**
5. Coller le **FCM token** de l'iPhone
6. Cliquer sur **"Test"**

### Test 3: Vérifier le token FCM
Dans l'app Flutter, ajouter temporairement:
```dart
final token = await FirebaseMessaging.instance.getToken();
print('🔑 FCM Token iOS: $token');
```

---

## 📋 Checklist de Vérification

### Configuration Apple Developer
- [ ] Certificat APNs créé (fichier .p8)
- [ ] Key ID noté
- [ ] Team ID noté
- [ ] Bundle ID enregistré: `com.example.artluxurybus`

### Configuration Firebase
- [ ] Clé APNs uploadée dans Firebase Console
- [ ] Key ID et Team ID configurés
- [ ] GoogleService-Info.plist téléchargé et ajouté au projet

### Configuration Xcode
- [ ] Capability "Push Notifications" activée
- [ ] Capability "Background Modes" activée (Remote notifications)
- [ ] Fichier Runner.entitlements créé et lié
- [ ] Bundle ID correct: `com.example.artluxurybus`
- [ ] Signing configuré (Development ou Distribution)

### Code iOS
- [ ] AppDelegate.swift avec Firebase.configure()
- [ ] Permissions notifications demandées
- [ ] application.registerForRemoteNotifications() appelé
- [ ] Callbacks didRegisterForRemoteNotifications implémentés

### Tests
- [ ] App compile et lance sans erreur
- [ ] Permissions notifications acceptées sur l'iPhone
- [ ] Token FCM généré et visible dans les logs
- [ ] Token APNs reçu (visible dans les logs Xcode)
- [ ] Notification test depuis Firebase Console reçue

---

## 🚨 Erreurs Courantes

### Erreur: "No valid 'aps-environment' entitlement"
**Solution**: Créer le fichier `Runner.entitlements` et l'ajouter dans Xcode.

### Erreur: "Failed to register for remote notifications"
**Solution**: Vérifier que le certificat APNs est bien configuré dans Firebase.

### Erreur: Token FCM généré mais pas de notification
**Solution**: Vérifier que la clé APNs est uploadée dans Firebase Console.

### Notifications reçues uniquement en foreground
**Solution**: Vérifier que "Background Modes" > "Remote notifications" est activé.

---

## 📞 Support

Si le problème persiste après toutes ces étapes:
1. Vérifier les logs Xcode pour les erreurs spécifiques
2. Vérifier les logs Firebase Console (Cloud Messaging)
3. Tester avec un autre appareil iOS
4. Vérifier que l'iPhone n'est pas en mode "Ne pas déranger"

---

## ✅ Résultat Attendu

Après configuration:
- ✅ Notifications reçues sur iOS (foreground + background)
- ✅ Notifications reçues sur Android (déjà fonctionnel)
- ✅ Token FCM enregistré sur le serveur Laravel
- ✅ Notifications automatiques lors de création de feedback
