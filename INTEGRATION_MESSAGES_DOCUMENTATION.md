# 📱 Documentation : Intégration Messages & Annonces dans l'App Mobile

## 🎯 Vue d'ensemble

L'application mobile Art Luxury Bus peut maintenant recevoir et afficher deux types de messages depuis l'API Laravel :

1. **Notifications** : Messages importants pour tous les utilisateurs
2. **Annonces** : Messages ciblés par gare et/ou type d'appareil

---

## 📦 Packages Ajoutés

### `device_info_plus: ^9.0.3`

Permet d'identifier l'appareil de manière unique pour :
- Enregistrer le `device_id` avec le token FCM
- Différencier les appareils d'un même utilisateur
- Permettre le ciblage précis des notifications

---

## 🏗️ Architecture Implémentée

### 1. **Modèle de Données**

**Fichier** : `lib/models/message_model.dart`

```dart
class MessageModel {
  final int id;
  final String titre;
  final String contenu;
  final String type; // 'notification' ou 'annonce'
  final int? gareId;
  final GareInfo? gare;
  final String? appareil; // 'mobile', 'ecran_tv', 'ecran_led', 'tous'
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final bool active;
  final bool isExpired;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Propriétés calculées** :
- `isNotification` : Vérifie si c'est une notification
- `isAnnonce` : Vérifie si c'est une annonce
- `isCurrentlyActive` : Vérifie si le message est actif et dans sa période de validité
- `formattedPeriod` : Retourne la période formatée (ex: "Du 23/10/2025 au 30/10/2025")

---

### 2. **Service API**

**Fichier** : `lib/services/message_api_service.dart`

#### Méthodes principales :

```dart
// Récupérer les messages actifs pour l'app mobile
Future<List<MessageModel>> getActiveMessages({int? gareId})

// Récupérer uniquement les notifications
Future<List<MessageModel>> getNotifications()

// Récupérer uniquement les annonces
Future<List<MessageModel>> getAnnonces({int? gareId})

// Récupérer un message spécifique
Future<MessageModel?> getMessage(int id)

// Récupérer avec pagination et filtres
Future<Map<String, dynamic>> getMessages({
  String? type,
  bool? active,
  int? gareId,
  String? appareil,
  int page = 1,
  int perPage = 15,
})
```

#### Filtrage automatique :

L'API filtre automatiquement les messages pour l'application mobile :
- `appareil=mobile` : Uniquement les messages destinés aux mobiles
- `current=true` : Uniquement les messages actifs et non expirés

---

### 3. **Service Device Info**

**Fichier** : `lib/services/device_info_service.dart`

```dart
class DeviceInfoService {
  // Obtenir l'ID unique de l'appareil
  Future<String> getDeviceId()
  
  // Obtenir le type d'appareil (android/ios)
  Future<String> getDeviceType()
  
  // Obtenir le modèle de l'appareil
  Future<String> getDeviceModel()
  
  // Obtenir toutes les informations
  Future<Map<String, dynamic>> getDeviceInfo()
  
  // Afficher les infos dans les logs
  Future<void> printDeviceInfo()
}
```

**Informations récupérées** :

**Android** :
- `device_id` : Android ID unique
- `model` : Modèle de l'appareil (ex: "SM-G998B")
- `brand` : Marque (ex: "Samsung")
- `manufacturer` : Fabricant
- `android_version` : Version Android (ex: "13")
- `sdk_int` : Niveau SDK

**iOS** :
- `device_id` : identifierForVendor
- `model` : Modèle (ex: "iPhone")
- `name` : Nom de l'appareil (ex: "iPhone de John")
- `system_name` : "iOS"
- `system_version` : Version iOS (ex: "17.0")

---

### 4. **Providers (Riverpod)**

**Fichier** : `lib/providers/message_provider.dart`

```dart
// Provider pour les messages actifs
final activeMessagesProvider = FutureProvider.autoDispose<List<MessageModel>>

// Provider pour les messages d'une gare spécifique
final activeMessagesByGareProvider = FutureProvider.autoDispose.family<List<MessageModel>, int?>

// Provider pour les notifications uniquement
final notificationsProvider = FutureProvider.autoDispose<List<MessageModel>>

// Provider pour les annonces uniquement
final annoncesProvider = FutureProvider.autoDispose<List<MessageModel>>

// State Notifier avec refresh manuel
final messagesNotifierProvider = StateNotifierProvider<MessagesNotifier, AsyncValue<List<MessageModel>>>

// Compteur de messages non lus
final unreadMessagesCountProvider = Provider.autoDispose<int>

// Vérifier s'il y a de nouveaux messages
final hasNewMessagesProvider = Provider.autoDispose<bool>
```

---

### 5. **Écran d'Affichage**

**Fichier** : `lib/screens/messages_screen.dart`

#### Fonctionnalités :

✅ **Onglets séparés** : Notifications / Annonces
✅ **Pull-to-refresh** : Rafraîchir les messages
✅ **Cartes modernes** : Design élégant avec badges colorés
✅ **Détails complets** : Bottom sheet avec toutes les informations
✅ **Gestion des états** : Loading, erreur, liste vide
✅ **Dates relatives** : "Il y a 2h", "Hier", etc.
✅ **Informations contextuelles** : Gare, période de validité

#### Design :

- **Notifications** : Badge doré (couleur Art Luxury Bus)
- **Annonces** : Badge bleu
- **Icônes** : Notifications (🔔), Annonces (📢)
- **Cartes** : Elevation, border-radius, tap effect

---

## 🔄 Intégration avec NotificationService

### Mise à jour du NotificationService

**Fichier** : `lib/services/notification_service.dart`

#### Changements apportés :

1. **Import du DeviceInfoService** :
```dart
import '../services/device_info_service.dart';
```

2. **Enregistrement du device_id avec le token FCM** :
```dart
static Future<void> _registerTokenWithServer(String token) async {
  final deviceInfoService = DeviceInfoService();
  
  // Obtenir les informations réelles de l'appareil
  final deviceType = await deviceInfoService.getDeviceType();
  final deviceId = await deviceInfoService.getDeviceId();
  
  debugPrint('📱 Enregistrement FCM Token avec device_id: $deviceId');
  
  final result = await FeedbackApiService.registerFcmToken(
    token,
    deviceType: deviceType,
    deviceId: deviceId,
  );
}
```

#### Logs de débogage :

```
📱 Enregistrement FCM Token avec device_id: abc123def456
📱 Type d'appareil: android
✅ Token FCM enregistré avec succès sur le serveur
```

---

## 📡 Communication avec l'API Laravel

### Endpoints utilisés :

#### 1. Récupérer les messages actifs pour mobile
```
GET /api/messages/active?appareil=mobile&current=true
```

**Réponse** :
```json
{
  "data": [
    {
      "id": 1,
      "titre": "Nouvelle promotion",
      "contenu": "Bénéficiez de 20% de réduction ce week-end",
      "type": "annonce",
      "gare_id": null,
      "gare": null,
      "appareil": "mobile",
      "date_debut": "2025-10-23 00:00:00",
      "date_fin": "2025-10-27 23:59:59",
      "active": true,
      "is_expired": false,
      "created_at": "2025-10-23 10:00:00",
      "updated_at": "2025-10-23 10:00:00"
    }
  ]
}
```

#### 2. Enregistrer le token FCM avec device_id
```
POST /api/fcm-tokens
Authorization: Bearer {token}
Content-Type: application/json

{
  "token": "fcm_token_here",
  "device_type": "android",
  "device_id": "abc123def456"
}
```

**Réponse** :
```json
{
  "success": true,
  "message": "Token FCM enregistré avec succès"
}
```

---

## 🔔 Notifications Push pour les Messages

### Événements Laravel déclenchant les notifications :

**Fichier Laravel** : `app/Events/MessageCreated.php`

Quand un message est créé via l'API ou le backoffice, l'événement `MessageCreated` est déclenché.

**Listener** : `app/Listeners/SendMessageNotification.php`

```php
public function handle(MessageCreated $event): void
{
    $message = $event->message;

    // Envoyer notification uniquement si c'est une notification et qu'elle est active
    if ($message->type === 'notification' && $message->active) {
        $this->notificationService->sendMessageNotification($message);
    }
}
```

### Réception dans l'app mobile :

Le `NotificationService` Flutter écoute les notifications Firebase et les affiche automatiquement.

**Types de données envoyées** :
```json
{
  "notification": {
    "title": "Nouvelle notification",
    "body": "Contenu de la notification"
  },
  "data": {
    "type": "message",
    "message_id": "123",
    "message_type": "notification"
  }
}
```

---

## 🚀 Utilisation dans l'Application

### 1. Ajouter l'écran dans la navigation

```dart
// Dans votre router (go_router)
GoRoute(
  path: '/messages',
  builder: (context, state) => const MessagesScreen(),
),
```

### 2. Ajouter un bouton dans le menu

```dart
ListTile(
  leading: const Icon(Icons.message),
  title: const Text('Messages & Annonces'),
  trailing: Consumer(
    builder: (context, ref, child) {
      final count = ref.watch(unreadMessagesCountProvider);
      if (count > 0) {
        return Badge(
          label: Text('$count'),
          child: const Icon(Icons.chevron_right),
        );
      }
      return const Icon(Icons.chevron_right);
    },
  ),
  onTap: () => context.push('/messages'),
),
```

### 3. Afficher un badge de notification

```dart
Consumer(
  builder: (context, ref, child) {
    final hasNew = ref.watch(hasNewMessagesProvider);
    
    return IconButton(
      icon: Badge(
        isLabelVisible: hasNew,
        child: const Icon(Icons.notifications),
      ),
      onPressed: () => context.push('/messages'),
    );
  },
),
```

### 4. Rafraîchir manuellement

```dart
ref.read(messagesNotifierProvider.notifier).refresh();
```

### 5. Filtrer par type

```dart
// Dans votre widget
final notifier = ref.read(messagesNotifierProvider.notifier);
final notifications = notifier.notifications; // Uniquement les notifications
final annonces = notifier.annonces; // Uniquement les annonces
```

---

## 🎨 Personnalisation

### Changer les couleurs

Dans `messages_screen.dart`, modifiez :

```dart
// Couleur principale (actuellement doré)
const Color(0xFFD4AF37)

// Couleur des annonces (actuellement bleu)
Colors.blue
```

### Modifier le format des dates

Dans la méthode `_formatDate()` :

```dart
String _formatDate(DateTime date) {
  // Votre logique personnalisée
  return DateFormat('dd/MM/yyyy').format(date);
}
```

---

## 🧪 Tests

### Tester l'affichage des messages

1. Créer un message depuis le backoffice Laravel :
   - Type : `notification`
   - Appareil : `mobile`
   - Actif : `true`

2. Ouvrir l'app mobile et naviguer vers l'écran Messages

3. Vérifier que le message s'affiche correctement

### Tester les notifications push

1. Créer une notification depuis le backoffice

2. Vérifier dans les logs Laravel :
```
[2025-10-23 12:00:00] Envoi de notification push pour le message
[2025-10-23 12:00:00] Résultat de l'envoi de notification: true
```

3. Vérifier dans les logs Flutter :
```
🔔 Notification reçue en premier plan
📱 Titre: Nouvelle notification
📱 Corps: Contenu de la notification
```

### Tester le device_id

1. Lancer l'app et vérifier les logs :
```
📱 Android Device ID: abc123def456
📱 Model: SM-G998B
📱 Enregistrement FCM Token avec device_id: abc123def456
✅ Token FCM enregistré avec succès sur le serveur
```

2. Vérifier dans la base de données Laravel :
```sql
SELECT * FROM fcm_tokens WHERE device_id = 'abc123def456';
```

---

## 📊 Tableau de Bord (Optionnel)

### Créer un widget de résumé

```dart
class MessagesSummaryWidget extends ConsumerWidget {
  const MessagesSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesNotifierProvider);

    return messagesAsync.when(
      data: (messages) {
        final notifications = messages.where((m) => m.isNotification).length;
        final annonces = messages.where((m) => m.isAnnonce).length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCounter('Notifications', notifications, Icons.notifications),
                    _buildCounter('Annonces', annonces, Icons.campaign),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/messages'),
                  child: const Text('Voir tous les messages'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Erreur de chargement'),
    );
  }

  Widget _buildCounter(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: const Color(0xFFD4AF37)),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }
}
```

---

## 🔧 Dépannage

### Les messages ne s'affichent pas

1. **Vérifier l'authentification** :
```dart
final token = await AuthService().getToken();
debugPrint('Token: $token');
```

2. **Vérifier le filtrage API** :
```dart
// Dans message_api_service.dart, ligne 30
debugPrint('🔍 Récupération des messages: $uri');
```

3. **Vérifier la réponse API** :
```dart
debugPrint('📡 Status Code: ${response.statusCode}');
debugPrint('📡 Response Body: ${response.body}');
```

### Le device_id n'est pas enregistré

1. **Vérifier les permissions** :
   - Android : Aucune permission spéciale requise
   - iOS : Vérifier que l'app a les permissions nécessaires

2. **Vérifier les logs** :
```dart
await DeviceInfoService().printDeviceInfo();
```

3. **Tester manuellement** :
```dart
final deviceId = await DeviceInfoService().getDeviceId();
debugPrint('Device ID: $deviceId');
```

### Les notifications push ne fonctionnent pas

1. **Vérifier Firebase** :
   - Token FCM obtenu : ✅
   - Token enregistré sur le serveur : ✅
   - Certificat APNs configuré (iOS) : ✅

2. **Vérifier les événements Laravel** :
```php
// Dans EventServiceProvider.php
protected $listen = [
    MessageCreated::class => [
        SendMessageNotification::class,
    ],
];
```

3. **Tester depuis Firebase Console** :
   - Cloud Messaging > Send test message
   - Coller le token FCM
   - Envoyer

---

## 📝 Checklist d'Intégration

- [x] Package `device_info_plus` ajouté au `pubspec.yaml`
- [x] Modèle `MessageModel` créé
- [x] Service `MessageApiService` créé
- [x] Service `DeviceInfoService` créé
- [x] Providers Riverpod créés
- [x] `NotificationService` mis à jour pour enregistrer le `device_id`
- [x] Écran `MessagesScreen` créé
- [ ] Écran ajouté à la navigation
- [ ] Bouton d'accès ajouté dans le menu
- [ ] Badge de notification ajouté
- [ ] Tests effectués
- [ ] Documentation lue et comprise

---

## 🎉 Résultat Final

Votre application mobile peut maintenant :

✅ **Recevoir des messages ciblés** selon le type d'appareil (mobile)
✅ **Afficher les notifications** pour tous les utilisateurs
✅ **Afficher les annonces** filtrées par gare si nécessaire
✅ **Identifier l'appareil** avec un device_id unique
✅ **Enregistrer le device_id** avec le token FCM sur le serveur
✅ **Recevoir des notifications push** pour les nouveaux messages
✅ **Afficher un écran moderne** avec onglets et détails
✅ **Rafraîchir manuellement** les messages
✅ **Gérer les états** (loading, erreur, vide)

---

## 📞 Support

Pour toute question ou problème, vérifiez :
1. Les logs de l'application Flutter
2. Les logs du serveur Laravel
3. La base de données (tables `messages` et `fcm_tokens`)
4. La console Firebase

Bonne intégration ! 🚀
