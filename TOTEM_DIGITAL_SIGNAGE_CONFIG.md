## 📺 Configuration Totem Digital Signage - Android 11

### Caractéristiques du Totem d'Affichage

Basé sur vos images, votre totem a les caractéristiques suivantes :
- **Format :** Portrait (Vertical)
- **Android :** Version 11 (API 30)
- **Type :** Digital Signage / Totem d'affichage
- **Application :** ETV Cloud Platform (Content Management System)

### ✅ Modifications Appliquées pour Totems

#### 1. **AndroidManifest.xml**
- ✅ `android:keepScreenOn="true"` - Écran toujours allumé
- ✅ `android:screenOrientation="portrait"` - Verrouillage en portrait
- ✅ `android:launchMode="singleTask"` - Une seule instance de l'app
- ✅ Permissions DISABLE_KEYGUARD, WAKE_LOCK
- ✅ Support pour `android.hardware.type.television`

#### 2. **MainActivity.kt - Mode Kiosque**
- ✅ Mode plein écran immersif (cache barres système)
- ✅ Écran toujours allumé (FLAG_KEEP_SCREEN_ON)
- ✅ Compatible Android 11+ avec WindowInsetsController
- ✅ Rétablit le mode plein écran automatiquement

#### 3. **Optimisations Performances**
- ✅ Hardware acceleration activée
- ✅ Large Heap pour contenus lourds (vidéos, images HD)
- ✅ MultiDex pour éviter la limite de 64k méthodes

### 🔧 Problèmes Courants Totems Android 11

#### Problème 1 : L'écran se met en veille
**Cause :** FLAG_KEEP_SCREEN_ON non configuré
**Solution :** ✅ Corrigé dans MainActivity.kt

#### Problème 2 : Les barres système apparaissent
**Cause :** Mode immersif non configuré pour Android 11
**Solution :** ✅ Utilisation de WindowInsetsController

#### Problème 3 : Crash au démarrage sur totem
**Causes possibles :**
1. Google Play Services manquant (certains totems n'ont pas GMS)
2. Firebase nécessite Google Play Services
3. Permissions non accordées

**Solutions appliquées :**
- ✅ Gestion d'erreur Firebase (l'app continue sans Firebase)
- ✅ Try-catch sur toutes les initialisations critiques
- ✅ Stream controller initialisé même en cas d'erreur

#### Problème 4 : L'orientation change
**Cause :** Pas de verrouillage d'orientation
**Solution :** ✅ `android:screenOrientation="portrait"`

### 🚀 Build pour Totem

```bash
# Nettoyer
flutter clean

# Récupérer les dépendances
flutter pub get

# Build APK optimisé pour totem
flutter build apk --release --split-per-abi

# OU build universel
flutter build apk --release
```

### 📱 Installation sur Totem

1. **Copier l'APK sur une clé USB**
2. **Brancher la clé sur le totem**
3. **Utiliser un gestionnaire de fichiers pour installer l'APK**
4. **Ou via ADB :**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

### ⚙️ Configuration Post-Installation

#### Mode Kiosque Complet (optionnel)
Pour verrouiller le totem sur votre app uniquement :

1. **Activer le mode développeur** sur le totem
2. **Utiliser une application Kiosk Launcher** comme :
   - Fully Kiosk Browser
   - SureLock
   - KioWare

3. **OU configurer en Device Owner** (nécessite ADB) :
   ```bash
   adb shell dpm set-device-owner com.example.artluxurybus/.DeviceAdminReceiver
   ```

### 🔍 Diagnostic des Crashs Totem

Si l'app crash sur le totem :

1. **Activer le débogage USB** sur le totem
2. **Connecter via ADB** :
   ```bash
   adb connect [IP_DU_TOTEM]:5555
   ```

3. **Capturer les logs** :
   ```bash
   ./capture_crash_logs.sh
   ```

4. **Vérifier les erreurs spécifiques** :
   - `FATAL EXCEPTION` - Erreur critique
   - `UnsatisfiedLinkError` - Bibliothèque native manquante
   - `ClassNotFoundException` - Classe Android manquante
   - `SecurityException` - Permission refusée

### 📊 Optimisations Spécifiques Totem

#### Réduire la Taille de l'APK
```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
```

#### Désactiver les Fonctionnalités Non Nécessaires
Dans votre cas, si le totem n'a pas besoin de :
- **Notifications Push** → Retirer Firebase
- **Géolocalisation** → Retirer geolocator
- **Caméra/QR** → Retirer mobile_scanner

#### APK Sans Google Play Services
Si votre totem n'a pas Google Play Services :

1. Commenter Firebase dans `main.dart`
2. Retirer `google-services.json`
3. Retirer le plugin `com.google.gms.google-services` du build.gradle

### 🎯 Checklist Déploiement Totem

- [ ] APK buildé en release mode
- [ ] Mode portrait verrouillé
- [ ] Écran reste allumé
- [ ] Mode plein écran actif
- [ ] Pas de crash au démarrage
- [ ] Connexion internet fonctionnelle
- [ ] Application démarre au boot (si nécessaire)
- [ ] Testé pendant 24h minimum

### 🔐 Sécurité Totem

- ✅ Désactiver la barre de navigation (fait)
- ✅ Désactiver la barre de statut (fait)
- ⚠️ Considérer un launcher kiosque pour empêcher la sortie de l'app
- ⚠️ Configurer un MDM (Mobile Device Management) pour gestion à distance

### 📞 Support Technique

**Si le crash persiste :**
1. Capturez les logs avec `./capture_crash_logs.sh`
2. Vérifiez que le totem a :
   - Internet fonctionnel
   - Assez de RAM (minimum 2GB recommandé)
   - Android 11 à jour
3. Testez d'abord sur un téléphone Android 11 classique
4. Comparez les logs entre téléphone et totem

**Informations à collecter :**
- Marque et modèle du totem
- Version exacte d'Android
- RAM disponible
- Présence de Google Play Services (`adb shell pm list packages | grep gms`)
