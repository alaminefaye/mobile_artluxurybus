# 🐛 Debug Notifications Push - Art Luxury Bus

## ❌ Problème : "Je ne reçois pas de notifications push"

Voici le plan de débogage étape par étape pour résoudre ce problème.

## 🔧 Étapes de Debug Immédiates

### 1. **Installer les dépendances Firebase**
```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter clean
flutter pub get
```

### 2. **Créer les fichiers de configuration Android**

#### A. Créer `android/app/src/main/res/values/colors.xml`
```bash
mkdir -p android/app/src/main/res/values
```

Puis créer le fichier avec :
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#1976D2</color>
</resources>
```

#### B. Vérifier/Modifier `android/build.gradle.kts`
Ajouter dans la section `dependencies` :
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

#### C. Vérifier/Modifier `android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation("com.google.firebase:firebase-messaging:23.4.0")
}
```

### 3. **Tester l'app sans Firebase d'abord**
```bash
flutter run
```

**Dans la console, chercher :**
```
✅ Firebase initialisé
📱 Token FCM: eQg7Z2mKTR6...
✅ Permissions accordées
✅ Token enregistré sur le serveur
```

## 🎯 Plan de Test Step-by-Step

### Test 1: **Notification Locale (Sans Firebase)**
1. **Lancer l'app**
2. **Se connecter en tant qu'admin**
3. **Appuyer sur le bouton "Tester les Notifications"**
4. **Résultat attendu** : Une notification locale s'affiche

**Si ça ne marche pas** :
- Problème de permissions Android
- Solution : Réinstaller l'app et accepter les permissions

### Test 2: **Token FCM**
**Dans les logs Flutter, vérifier :**
```
📱 Token FCM: eQg7Z2mKTR6KnR5FcIz_M2:APA91...
✅ Token enregistré sur le serveur
```

**Si pas de token** :
- Problème de configuration Firebase
- **Action** : Télécharger `google-services.json`

### Test 3: **Firebase Console Test**
1. **Aller sur** [Firebase Console](https://console.firebase.google.com/)
2. **Projet** → Cloud Messaging
3. **"Envoyer votre premier message"**
4. **Cibler** votre application
5. **Envoyer**

### Test 4: **Backend Laravel Test**
```bash
# Tester la configuration du serveur
curl -X GET https://gestion-compagny.universaltechnologiesafrica.com/api/notifications/test-config \
  -H "Authorization: Bearer YOUR_TOKEN"
  
# Réponse attendue
{
  "success": true,
  "message": "Configuration Firebase valide"
}
```

## 🚨 Problèmes Courants & Solutions

### Problème 1: "MissingPluginException: firebase_core"
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Problème 2: "Token FCM null"
**Cause:** Fichier `google-services.json` manquant
**Solution:**
1. Télécharger depuis Firebase Console
2. Placer dans `/android/app/google-services.json`
3. Rebuild l'app

### Problème 3: "Permissions refusées"
**Solution:**
1. Désinstaller l'app complètement
2. Réinstaller avec `flutter run`
3. Accepter toutes les permissions

### Problème 4: "Notifications en background seulement"
**Cause:** Configuration AndroidManifest
**Solution:** Modifier `android/app/src/main/AndroidManifest.xml`

### Problème 5: "Backend ne reçoit pas le token"
**Vérifier:**
1. URL correcte : `https://gestion-compagny.universaltechnologiesafrica.com/api`
2. Token d'authentification valide
3. Endpoint `/api/fcm/register-token` fonctionne

## 📱 Tests par Plateforme

### Android (Priorité)
- ✅ **Émulateur** : Tester avec l'émulateur Android
- ✅ **Appareil physique** : Tester avec votre téléphone
- ✅ **Logs ADB** : `adb logcat | grep Firebase`

### iOS (Optionnel)
- Nécessite certificat APNs
- Configuration plus complexe

## 🔍 Commandes de Debug

### 1. **Voir les logs complets**
```bash
flutter run --verbose
```

### 2. **Logs Android spécifiques**
```bash
adb logcat | grep -E "(Firebase|FCM|Notification)"
```

### 3. **Nettoyer complètement**
```bash
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
flutter run
```

## ✅ Checklist de Vérification

### Configuration App
- [ ] `pubspec.yaml` : dépendances Firebase ajoutées
- [ ] `main.dart` : NotificationService.initialize() appelé
- [ ] `google-services.json` : présent dans `/android/app/`
- [ ] `colors.xml` : créé avec couleur de notification

### Configuration Android
- [ ] `build.gradle.kts` : plugin Google Services ajouté
- [ ] `app/build.gradle.kts` : plugin et dépendances Firebase
- [ ] `AndroidManifest.xml` : permissions et service FCM
- [ ] App rebuild après changements

### Tests Fonctionnels
- [ ] Notification locale fonctionne (bouton test)
- [ ] Token FCM généré et affiché dans logs
- [ ] Token enregistré sur le serveur (log "✅ Token enregistré")
- [ ] Notification depuis Firebase Console reçue

### Backend Laravel
- [ ] Endpoint `/api/notifications/test-config` répond OK
- [ ] Firebase configuré côté serveur avec service account JSON
- [ ] Variables d'environnement Firebase correctes

## 🎯 Action Immédiate Recommandée

**Exécuter dans l'ordre :**

1. **Créer colors.xml**
2. **Faire flutter clean && flutter pub get**
3. **Lancer flutter run avec logs**
4. **Chercher dans la console : "Token FCM: ..."**
5. **Tester le bouton "Tester les Notifications" dans l'app**
6. **Si ça marche localement → Tester depuis Firebase Console**

La plupart des problèmes de notifications viennent de :
1. **Configuration Firebase manquante** (80%)
2. **Permissions non accordées** (15%) 
3. **Backend mal configuré** (5%)

Suivez ce guide étape par étape et les notifications devraient fonctionner ! 🚀
