# 🔊 Documentation : Annonces Vocales Automatiques

## 🎯 Vue d'ensemble

Les **annonces vocales** permettent de lire automatiquement les messages de type "annonce" et de les répéter jusqu'à ce qu'ils ne soient plus actifs.

---

## 📦 Packages Ajoutés

### 1. `flutter_tts: ^3.8.0`
Text-to-Speech pour lire les annonces vocalement.

### 2. `android_alarm_manager_plus: ^3.0.3`
Gestion des tâches en arrière-plan (pour les répétitions).

---

## 🏗️ Architecture

### 1. **Service Principal**
**Fichier** : `lib/services/voice_announcement_service.dart`

**Fonctionnalités** :
- ✅ Lecture vocale des annonces
- ✅ Répétition automatique configurable
- ✅ Gestion de plusieurs annonces simultanées
- ✅ Configuration TTS (langue, volume, pitch, vitesse)
- ✅ Sauvegarde des préférences

**Méthodes principales** :
```dart
// Initialiser le service
await VoiceAnnouncementService().initialize();

// Démarrer une annonce répétée
await service.startAnnouncement(messageModel);

// Arrêter une annonce
await service.stopAnnouncement(messageId);

// Arrêter toutes les annonces
await service.stopAllAnnouncements();

// Lire un texte une seule fois
await service.speakOnce("Texte à lire");

// Configuration
await service.setEnabled(true);
await service.setRepeatInterval(5); // 5 minutes
await service.setLanguage('fr-FR');
await service.setVolume(1.0);
await service.setPitch(1.0);
await service.setRate(0.5);
```

---

### 2. **Gestionnaire d'Annonces**
**Fichier** : `lib/services/announcement_manager.dart`

**Rôle** : Synchroniser automatiquement les annonces vocales avec les messages actifs de l'API.

**Fonctionnalités** :
- ✅ Récupère les annonces actives depuis l'API
- ✅ Démarre automatiquement les nouvelles annonces
- ✅ Arrête les annonces expirées
- ✅ Gère les notifications push

**Utilisation** :
```dart
// Démarrer le gestionnaire
await AnnouncementManager().start();

// Rafraîchir les annonces
await AnnouncementManager().refresh();

// Traiter un nouveau message push
await AnnouncementManager().handleNewMessage(messageModel);

// Arrêter tout
await AnnouncementManager().stop();
```

---

### 3. **Providers Riverpod**
**Fichier** : `lib/providers/voice_announcement_provider.dart`

```dart
// Service
final voiceAnnouncementServiceProvider

// État activé/désactivé
final voiceAnnouncementsEnabledProvider

// Intervalle de répétition
final voiceRepeatIntervalProvider

// Liste des annonces actives
final activeVoiceAnnouncementsProvider

// Notifier pour actions
final voiceAnnouncementNotifierProvider
```

---

### 4. **Écran de Paramètres**
**Fichier** : `lib/screens/voice_settings_screen.dart`

**Fonctionnalités** :
- ✅ Activer/Désactiver les annonces vocales
- ✅ Configurer l'intervalle de répétition (1-30 minutes)
- ✅ Régler le volume (0-100%)
- ✅ Régler la tonalité (0.5-2.0)
- ✅ Régler la vitesse (0.0-1.0)
- ✅ Tester la voix
- ✅ Arrêter toutes les annonces
- ✅ Voir les annonces actives

---

## 🚀 Intégration dans l'Application

### Étape 1 : Initialiser au démarrage

Dans votre `main.dart` ou `home_page.dart` :

```dart
import 'package:artluxurybus/services/announcement_manager.dart';

@override
void initState() {
  super.initState();
  _initializeVoiceAnnouncements();
}

Future<void> _initializeVoiceAnnouncements() async {
  try {
    // Démarrer le gestionnaire d'annonces
    await AnnouncementManager().start();
    debugPrint('✅ Gestionnaire d\'annonces démarré');
  } catch (e) {
    debugPrint('❌ Erreur initialisation annonces: $e');
  }
}
```

---

### Étape 2 : Gérer les nouveaux messages push

Dans votre `NotificationService` :

```dart
import 'package:artluxurybus/services/announcement_manager.dart';
import 'package:artluxurybus/services/message_api_service.dart';

// Quand une notification push est reçue
FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  // Vérifier si c'est un message de type "annonce"
  if (message.data['message_type'] == 'annonce') {
    final messageId = int.parse(message.data['message_id']);
    
    // Récupérer les détails du message
    final messageModel = await MessageApiService().getMessage(messageId);
    
    if (messageModel != null) {
      // Démarrer l'annonce vocale
      await AnnouncementManager().handleNewMessage(messageModel);
    }
  }
});
```

---

### Étape 3 : Ajouter le bouton de paramètres

Dans votre menu ou page de paramètres :

```dart
import 'package:artluxurybus/screens/voice_settings_screen.dart';

ListTile(
  leading: const Icon(Icons.volume_up, color: Color(0xFFD4AF37)),
  title: const Text('Annonces Vocales'),
  subtitle: const Text('Configurer les annonces vocales'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoiceSettingsScreen(),
      ),
    );
  },
),
```

---

### Étape 4 : Ajouter un indicateur d'annonce active

Dans votre page d'accueil :

```dart
import 'package:artluxurybus/providers/voice_announcement_provider.dart';

Consumer(
  builder: (context, ref, child) {
    final activeAnnouncements = ref.watch(activeVoiceAnnouncementsProvider);
    
    if (activeAnnouncements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${activeAnnouncements.length} annonce(s) vocale(s) en cours',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle, color: Colors.red),
            onPressed: () async {
              await ref.read(voiceAnnouncementNotifierProvider.notifier)
                  .stopAllAnnouncements();
            },
          ),
        ],
      ),
    );
  },
),
```

---

## 📱 Configuration Android

### 1. Permissions dans `AndroidManifest.xml`

Ajoutez dans `android/app/src/main/AndroidManifest.xml` :

```xml
<manifest>
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    
    <application>
        <!-- Service pour les tâches en arrière-plan -->
        <service
            android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmService"
            android:permission="android.permission.BIND_JOB_SERVICE"
            android:exported="false"/>
        
        <receiver
            android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmBroadcastReceiver"
            android:exported="false"/>
        
        <receiver
            android:name="dev.fluttercommunity.plus.androidalarmmanager.RebootBroadcastReceiver"
            android:enabled="false"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

---

## 🍎 Configuration iOS

### 1. Permissions dans `Info.plist`

Ajoutez dans `ios/Runner/Info.plist` :

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Cette application utilise la synthèse vocale pour lire les annonces</string>
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>fetch</string>
</array>
```

---

## 🎛️ Configuration par Défaut

### Préférences SharedPreferences

| Clé | Valeur par défaut | Description |
|-----|-------------------|-------------|
| `voice_announcements_enabled` | `true` | Annonces activées |
| `voice_repeat_interval` | `5` | Intervalle (minutes) |
| `voice_language` | `'fr-FR'` | Langue |
| `voice_volume` | `1.0` | Volume (0.0-1.0) |
| `voice_pitch` | `1.0` | Tonalité (0.5-2.0) |
| `voice_rate` | `0.5` | Vitesse (0.0-1.0) |

---

## 🔄 Flux de Fonctionnement

### 1. Démarrage de l'application

```
1. App démarre
2. AnnouncementManager.start()
3. Récupère les annonces actives depuis l'API
4. Filtre les messages de type "annonce"
5. Démarre VoiceAnnouncementService pour chaque annonce
6. Programme les répétitions selon l'intervalle
```

### 2. Réception d'une nouvelle annonce (Push)

```
1. Notification push reçue
2. Vérifier type = "annonce"
3. AnnouncementManager.handleNewMessage()
4. Démarre l'annonce vocale immédiatement
5. Programme les répétitions
```

### 3. Répétition automatique

```
1. Timer déclenché (ex: toutes les 5 minutes)
2. Vérifier si l'annonce est toujours active
3. Vérifier si les annonces vocales sont activées
4. Lire l'annonce vocalement
5. Attendre le prochain intervalle
```

### 4. Arrêt d'une annonce

```
1. Annonce expire (date_fin dépassée)
2. AnnouncementManager détecte l'expiration
3. Arrête le timer de répétition
4. Supprime l'annonce de la liste active
```

---

## 🧪 Tests

### Test 1 : Créer une annonce depuis Laravel

1. Accéder au backoffice Laravel
2. Créer un message :
   - Titre : "Test annonce vocale"
   - Contenu : "Ceci est un test des annonces vocales automatiques"
   - Type : `annonce`
   - Appareil : `mobile`
   - Date début : Maintenant
   - Date fin : Dans 1 heure
   - Actif : ✅

3. L'app mobile devrait :
   - Recevoir une notification push
   - Lire l'annonce immédiatement
   - Répéter toutes les 5 minutes

### Test 2 : Vérifier les logs

```
🔊 [VoiceService] Initialisation...
✅ [VoiceService] Initialisé avec succès
   Langue: fr-FR, Volume: 1.0, Pitch: 1.0, Rate: 0.5
🎙️ [AnnouncementManager] Démarrage...
🔍 [AnnouncementManager] Récupération des annonces actives...
📢 [AnnouncementManager] 1 annonce(s) active(s) trouvée(s)
🎙️ [AnnouncementManager] Démarrage annonce #1: "Test annonce vocale"
🔊 [VoiceService] Démarrage annonce #1: "Test annonce vocale"
🔊 [VoiceService] Lecture: "Annonce importante. Test annonce vocale. Ceci est un test..."
✅ [VoiceService] Annonce programmée (répétition: 5 min)
🔊 [VoiceService] Début de l'annonce vocale
✅ [VoiceService] Annonce vocale terminée
```

### Test 3 : Tester les paramètres

1. Ouvrir l'écran de paramètres vocaux
2. Modifier l'intervalle de répétition : 2 minutes
3. Modifier le volume : 80%
4. Cliquer sur "Tester la voix"
5. Vérifier que la voix est audible

### Test 4 : Arrêter une annonce

1. Depuis le backoffice, désactiver l'annonce
2. Ou modifier la date de fin pour qu'elle soit passée
3. L'app devrait arrêter automatiquement l'annonce vocale

---

## 🎨 Personnalisation

### Modifier le texte lu

Dans `voice_announcement_service.dart`, méthode `_speakAnnouncement()` :

```dart
String textToSpeak = '';

// Personnaliser le préfixe
textToSpeak += 'Attention, annonce importante. ';

// Ajouter le titre
textToSpeak += '${message.titre}. ';

// Ajouter le contenu
textToSpeak += message.contenu;

// Ajouter des informations supplémentaires
if (message.gare != null) {
  textToSpeak += '. Cette annonce concerne la gare de ${message.gare!.nom}';
}

// Ajouter la période
if (message.formattedPeriod.isNotEmpty) {
  textToSpeak += '. Période de validité : ${message.formattedPeriod}';
}
```

### Modifier l'intervalle par défaut

Dans `voice_announcement_service.dart` :

```dart
static const int defaultRepeatIntervalMinutes = 10; // Au lieu de 5
```

### Changer la langue par défaut

Dans `voice_announcement_service.dart`, méthode `initialize()` :

```dart
final language = prefs.getString(prefKeyLanguage) ?? 'en-US'; // Anglais
```

---

## 🔧 Dépannage

### Problème : Aucun son

**Solutions** :
1. Vérifier que le volume du téléphone n'est pas à 0
2. Vérifier que les annonces vocales sont activées dans les paramètres
3. Vérifier les permissions audio dans les paramètres du téléphone
4. Tester avec le bouton "Tester la voix"

### Problème : Annonces ne se répètent pas

**Solutions** :
1. Vérifier que l'annonce est toujours active (date_fin non dépassée)
2. Vérifier l'intervalle de répétition (minimum 1 minute)
3. Vérifier les logs pour voir si le timer est actif
4. Redémarrer l'app

### Problème : Plusieurs annonces se chevauchent

**Solution** : Le service arrête automatiquement l'annonce en cours avant d'en démarrer une nouvelle. Si le problème persiste, arrêter toutes les annonces depuis les paramètres.

### Problème : Annonces continuent après désactivation

**Solution** :
1. Aller dans les paramètres vocaux
2. Cliquer sur "Arrêter toutes les annonces"
3. Désactiver les annonces vocales

---

## 📊 Statistiques et Monitoring

### Obtenir le nombre d'annonces actives

```dart
final count = AnnouncementManager().activeAnnouncementsCount;
debugPrint('Nombre d\'annonces actives: $count');
```

### Vérifier si une annonce est active

```dart
final isActive = VoiceAnnouncementService().isAnnouncementActive(messageId);
```

### Obtenir la liste des annonces actives

```dart
final announcements = VoiceAnnouncementService().getActiveAnnouncements();
for (var announcement in announcements) {
  debugPrint('Annonce active: ${announcement.titre}');
}
```

---

## 🎯 Bonnes Pratiques

### 1. Limiter la durée des annonces
- Garder les messages courts (max 2-3 phrases)
- Éviter les textes trop longs qui fatiguent l'utilisateur

### 2. Intervalle de répétition raisonnable
- Minimum recommandé : 5 minutes
- Maximum recommandé : 15 minutes
- Laisser l'utilisateur configurer selon ses préférences

### 3. Gestion de la batterie
- Les annonces vocales consomment de la batterie
- Permettre à l'utilisateur de désactiver facilement
- Arrêter automatiquement les annonces expirées

### 4. Respect de l'utilisateur
- Toujours permettre de désactiver les annonces
- Fournir des paramètres de volume
- Ne pas forcer l'activation

---

## ✅ Checklist d'Intégration

- [ ] Packages ajoutés au `pubspec.yaml`
- [ ] `flutter pub get` exécuté
- [ ] Permissions Android ajoutées
- [ ] Permissions iOS ajoutées (si applicable)
- [ ] `AnnouncementManager` initialisé au démarrage
- [ ] Gestion des notifications push intégrée
- [ ] Écran de paramètres ajouté à la navigation
- [ ] Bouton de paramètres ajouté au menu
- [ ] Tests effectués avec une annonce réelle
- [ ] Logs vérifiés

---

## 🎉 Résultat Final

Votre application peut maintenant :

✅ **Lire automatiquement** les annonces vocalement
✅ **Répéter les annonces** jusqu'à expiration
✅ **Gérer plusieurs annonces** simultanément
✅ **Configurer la voix** (langue, volume, pitch, vitesse)
✅ **Démarrer automatiquement** les nouvelles annonces push
✅ **Arrêter automatiquement** les annonces expirées
✅ **Permettre à l'utilisateur** de contrôler les paramètres

---

**Documentation créée le 23 octobre 2025**
**Version : 1.0.0**
