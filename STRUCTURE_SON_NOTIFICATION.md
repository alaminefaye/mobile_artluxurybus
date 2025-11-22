# 🏗️ Structure du Son de Notification

## 📁 Organisation des fichiers

```
artluxurybus/
│
├── 📄 notification.mp3                    ← Vous placez le fichier téléchargé ICI
│
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── res/
│                   └── raw/
│                       └── 🔊 notification.mp3  ← Copié automatiquement par le script
│
├── assets/
│   └── sounds/
│       └── 🔊 notification.mp3            ← Copié automatiquement par le script
│
├── ios/
│   └── Runner/
│       └── 🔊 notification.mp3            ← À ajouter manuellement via Xcode (optionnel)
│
└── lib/
    └── services/
        └── notification_service.dart      ← ✅ Déjà configuré pour utiliser le son
```

---

## 🔄 Flux d'utilisation du son

```
┌─────────────────────────────────────────────────────────┐
│  1️⃣ Notification reçue (Firebase Cloud Messaging)       │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  2️⃣ notification_service.dart détecte la notification   │
│     - Type: notification ou annonce                     │
│     - Titre et corps du message                         │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  3️⃣ Affichage avec _showLocalNotification()            │
│                                                         │
│  Android:                                               │
│  - Utilise: RawResourceAndroidNotificationSound(        │
│             'notification')                             │
│  - Fichier: android/app/src/main/res/raw/              │
│             notification.mp3                            │
│                                                         │
│  iOS:                                                   │
│  - Utilise: sound: 'notification.mp3'                  │
│  - Fichier: ios/Runner/notification.mp3                │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  4️⃣ L'utilisateur entend le son personnalisé ! 🔊       │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ Configuration dans le code

### 1. Canal de notification Android

```dart
// lib/services/notification_service.dart - Ligne ~179
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'art_luxury_bus_channel',
  'Art Luxury Bus Notifications',
  description: 'Notifications de l\'application Art Luxury Bus',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('notification'), // ← Son personnalisé
  enableVibration: true,
  showBadge: true,
);
```

### 2. Détails de notification Android

```dart
// lib/services/notification_service.dart - Ligne ~640
const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
  'art_luxury_bus_channel',
  'Art Luxury Bus Notifications',
  channelDescription: 'Notifications de l\'application Art Luxury Bus',
  importance: Importance.max,
  priority: Priority.high,
  showWhen: true,
  icon: '@mipmap/ic_launcher',
  playSound: true,
  sound: RawResourceAndroidNotificationSound('notification'), // ← Son personnalisé
  enableVibration: true,
  enableLights: true,
);
```

### 3. Configuration iOS

```dart
// lib/services/notification_service.dart - Ligne ~658
const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
  sound: 'notification.mp3', // ← Son personnalisé iOS
);
```

---

## ✅ Vérifications

### Vérifier que le son Android est bien installé :

```bash
ls -la android/app/src/main/res/raw/notification.mp3
```

**Résultat attendu :**
```
-rw-r--r--  1 user  staff  XXXXX Nov 21 10:00 notification.mp3
```

### Vérifier que le son est dans assets :

```bash
ls -la assets/sounds/notification.mp3
```

**Résultat attendu :**
```
-rw-r--r--  1 user  staff  XXXXX Nov 21 10:00 notification.mp3
```

---

## 🎯 Types de notifications qui utilisent ce son

| Type | Description | Son personnalisé |
|------|-------------|------------------|
| **Notification push** | Messages du serveur | ✅ Oui |
| **Annonce vocale** | Annonces lues à voix haute | ✅ Oui |
| **Notification locale** | Notifications générées par l'app | ✅ Oui |
| **Test notification** | Notifications de test (debug) | ✅ Oui |

---

## 📱 Plateformes supportées

| Plateforme | Statut | Emplacement du fichier |
|------------|--------|------------------------|
| **Android** | ✅ Configuré | `android/app/src/main/res/raw/notification.mp3` |
| **iOS** | ⚠️ Configuration manuelle requise | `ios/Runner/notification.mp3` (via Xcode) |

---

## 🔍 Débogage

Si le son ne fonctionne pas, vérifiez :

1. **Le fichier existe** :
   ```bash
   ls android/app/src/main/res/raw/notification.mp3
   ```

2. **Permissions Android** :
   - Paramètres → Apps → Art Luxury Bus → Notifications → Activées

3. **Mode Ne Pas Déranger** :
   - Désactivé ou l'app est en exception

4. **Rebuild complet** :
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Logs de debug** :
   ```bash
   flutter run --verbose
   ```
   Cherchez : `✅ [NotificationService] Canal Android créé`
