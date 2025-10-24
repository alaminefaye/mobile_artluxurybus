# 🚀 Quick Start : Annonces Vocales

## ⚡ Installation Rapide (3 étapes)

### 1. Installer les dépendances

```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter pub get
```

Les packages suivants ont été ajoutés :
- ✅ `flutter_tts: ^3.8.0`
- ✅ `android_alarm_manager_plus: ^3.0.3`

---

### 2. Configurer Android

Ouvrez `android/app/src/main/AndroidManifest.xml` et ajoutez :

```xml
<manifest>
    <!-- AJOUTER CES PERMISSIONS -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    
    <application>
        <!-- AJOUTER CES SERVICES (avant </application>) -->
        <service
            android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmService"
            android:permission="android.permission.BIND_JOB_SERVICE"
            android:exported="false"/>
        
        <receiver
            android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmBroadcastReceiver"
            android:exported="false"/>
    </application>
</manifest>
```

---

### 3. Initialiser dans votre app

Dans `lib/main.dart` ou `lib/screens/home_page.dart`, ajoutez :

```dart
import 'package:artluxurybus/services/announcement_manager.dart';

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeVoiceAnnouncements();
  }

  Future<void> _initializeVoiceAnnouncements() async {
    try {
      await AnnouncementManager().start();
      debugPrint('✅ Annonces vocales initialisées');
    } catch (e) {
      debugPrint('❌ Erreur annonces vocales: $e');
    }
  }
  
  // ... reste du code
}
```

---

## 🎯 Utilisation Basique

### Ajouter le bouton de paramètres

Dans votre menu/drawer :

```dart
import 'package:artluxurybus/screens/voice_settings_screen.dart';

ListTile(
  leading: const Icon(Icons.volume_up, color: Color(0xFFD4AF37)),
  title: const Text('Annonces Vocales'),
  subtitle: const Text('Configurer les annonces'),
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

## 🧪 Tester

### 1. Créer une annonce de test

Dans votre backoffice Laravel :
- **Titre** : "Test annonce vocale"
- **Contenu** : "Ceci est un test des annonces vocales automatiques"
- **Type** : `annonce`
- **Appareil** : `mobile`
- **Date début** : Maintenant
- **Date fin** : Dans 1 heure
- **Actif** : ✅

### 2. Lancer l'app

```bash
flutter run
```

### 3. Vérifier les logs

Vous devriez voir :
```
🔊 [VoiceService] Initialisation...
✅ [VoiceService] Initialisé avec succès
🎙️ [AnnouncementManager] Démarrage...
📢 [AnnouncementManager] 1 annonce(s) active(s) trouvée(s)
🔊 [VoiceService] Lecture: "Annonce importante. Test annonce vocale..."
```

### 4. Écouter

L'annonce devrait être lue immédiatement, puis répétée toutes les 5 minutes.

---

## ⚙️ Configuration Rapide

### Changer l'intervalle de répétition

Dans l'écran de paramètres vocaux :
1. Ouvrir "Annonces Vocales"
2. Ajuster "Intervalle de répétition" (1-30 minutes)
3. L'intervalle est sauvegardé automatiquement

### Désactiver temporairement

Dans l'écran de paramètres vocaux :
1. Désactiver le switch "Activer les annonces vocales"
2. Toutes les annonces en cours sont arrêtées

---

## 🔧 Intégration avec Notifications Push

Dans votre `NotificationService`, ajoutez :

```dart
import 'package:artluxurybus/services/announcement_manager.dart';
import 'package:artluxurybus/services/message_api_service.dart';

FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  // Si c'est une annonce
  if (message.data['message_type'] == 'annonce') {
    final messageId = int.parse(message.data['message_id']);
    
    // Récupérer les détails
    final messageModel = await MessageApiService().getMessage(messageId);
    
    if (messageModel != null) {
      // Démarrer l'annonce vocale
      await AnnouncementManager().handleNewMessage(messageModel);
    }
  }
  
  // ... reste du code
});
```

---

## 📊 Afficher les annonces actives

Dans votre page d'accueil :

```dart
import 'package:artluxurybus/providers/voice_announcement_provider.dart';

Consumer(
  builder: (context, ref, child) {
    final announcements = ref.watch(activeVoiceAnnouncementsProvider);
    
    if (announcements.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.green.shade50,
      child: ListTile(
        leading: const Icon(Icons.campaign, color: Colors.green),
        title: Text('${announcements.length} annonce(s) vocale(s)'),
        trailing: IconButton(
          icon: const Icon(Icons.stop, color: Colors.red),
          onPressed: () {
            ref.read(voiceAnnouncementNotifierProvider.notifier)
                .stopAllAnnouncements();
          },
        ),
      ),
    );
  },
),
```

---

## 🎛️ Paramètres par Défaut

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| Activé | ✅ Oui | Annonces activées par défaut |
| Intervalle | 5 min | Répétition toutes les 5 minutes |
| Langue | fr-FR | Français |
| Volume | 100% | Volume maximum |
| Tonalité | 1.0 | Tonalité normale |
| Vitesse | 0.5 | Vitesse moyenne |

---

## 📝 Checklist

- [ ] `flutter pub get` exécuté
- [ ] Permissions Android ajoutées
- [ ] `AnnouncementManager` initialisé dans `initState()`
- [ ] Bouton de paramètres ajouté au menu
- [ ] Annonce de test créée dans Laravel
- [ ] App lancée et testée
- [ ] Annonce vocale entendue
- [ ] Logs vérifiés

---

## 🎉 C'est Prêt !

Votre application peut maintenant :
- ✅ Lire automatiquement les annonces
- ✅ Répéter jusqu'à expiration
- ✅ Gérer plusieurs annonces
- ✅ Permettre la configuration

**Pour plus de détails, consultez `ANNONCES_VOCALES_DOCUMENTATION.md`**
