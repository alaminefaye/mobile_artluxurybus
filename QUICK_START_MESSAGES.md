# 🚀 Quick Start : Messages & Annonces

## ⚡ Installation Rapide

### 1. Installer les dépendances

```bash
flutter pub get
```

Le package `device_info_plus: ^9.0.3` a été ajouté au `pubspec.yaml`.

---

## 📱 Ajouter l'écran dans votre app

### Option 1 : Avec go_router

Dans votre fichier de routes :

```dart
import 'package:artluxurybus/screens/messages_screen.dart';

// Ajouter cette route
GoRoute(
  path: '/messages',
  builder: (context, state) => const MessagesScreen(),
),
```

### Option 2 : Navigation simple

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MessagesScreen(),
  ),
);
```

---

## 🎯 Ajouter un bouton d'accès

### Dans votre menu/drawer :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:artluxurybus/providers/message_provider.dart';

ListTile(
  leading: const Icon(Icons.message, color: Color(0xFFD4AF37)),
  title: const Text('Messages & Annonces'),
  trailing: Consumer(
    builder: (context, ref, child) {
      final count = ref.watch(unreadMessagesCountProvider);
      if (count > 0) {
        return Badge(
          label: Text('$count'),
          backgroundColor: Colors.red,
          child: const Icon(Icons.chevron_right),
        );
      }
      return const Icon(Icons.chevron_right);
    },
  ),
  onTap: () {
    Navigator.pop(context); // Fermer le drawer
    context.push('/messages'); // ou Navigator.push(...)
  },
),
```

### Dans votre AppBar :

```dart
Consumer(
  builder: (context, ref, child) {
    final hasNew = ref.watch(hasNewMessagesProvider);
    
    return IconButton(
      icon: Badge(
        isLabelVisible: hasNew,
        backgroundColor: Colors.red,
        child: const Icon(Icons.notifications),
      ),
      onPressed: () => context.push('/messages'),
    );
  },
),
```

---

## 🧪 Tester l'intégration

### 1. Créer un message de test depuis Laravel

Accédez au backoffice Laravel et créez un message :

**Notification (pour tous les utilisateurs)** :
- Titre : "Bienvenue sur Art Luxury Bus"
- Contenu : "Profitez de nos services de transport de luxe"
- Type : `notification`
- Appareil : `mobile`
- Actif : ✅

**Annonce (ciblée)** :
- Titre : "Promotion du week-end"
- Contenu : "20% de réduction sur tous les trajets ce samedi et dimanche"
- Type : `annonce`
- Appareil : `mobile`
- Gare : (optionnel) Sélectionnez une gare
- Date début : Aujourd'hui
- Date fin : Dans 7 jours
- Actif : ✅

### 2. Lancer l'app et vérifier

```bash
flutter run
```

**Vérifier dans les logs** :
```
📱 Android Device ID: abc123def456
📱 Type d'appareil: android
✅ Token FCM enregistré avec succès sur le serveur
🔍 Récupération des messages: https://artluxurybus.ci/api/messages/active?appareil=mobile&current=true
✅ 2 messages récupérés
```

### 3. Naviguer vers l'écran Messages

Vous devriez voir :
- ✅ Onglet "Notifications" avec vos notifications
- ✅ Onglet "Annonces" avec vos annonces
- ✅ Cartes élégantes avec badges colorés
- ✅ Pull-to-refresh fonctionnel

---

## 🔔 Tester les Notifications Push

### 1. Créer une notification depuis Laravel

Le système enverra automatiquement une notification push à tous les appareils.

### 2. Vérifier la réception

**App en premier plan** :
- Notification locale affichée automatiquement
- Message ajouté à la liste

**App en arrière-plan** :
- Notification système affichée
- Tap sur la notification ouvre l'app

**Logs attendus** :
```
🔔 Notification reçue en premier plan
📱 Titre: Nouvelle notification
📱 Corps: Contenu de la notification
```

---

## 🎨 Personnalisation Rapide

### Changer la couleur principale

Dans `lib/screens/messages_screen.dart`, remplacez :

```dart
const Color(0xFFD4AF37) // Doré actuel
```

Par votre couleur :

```dart
const Color(0xFFYOURCOLOR)
```

### Modifier le nombre d'onglets

Actuellement : 2 onglets (Notifications / Annonces)

Pour ajouter un onglet "Tous" :

```dart
TabController(length: 3, vsync: this) // Au lieu de 2

// Ajouter dans les tabs
Tab(icon: Icon(Icons.all_inbox), text: 'Tous'),

// Ajouter dans TabBarView
_buildAllMessagesList(messages),
```

---

## 📊 Utiliser les Providers

### Récupérer les messages actifs

```dart
Consumer(
  builder: (context, ref, child) {
    final messagesAsync = ref.watch(messagesNotifierProvider);
    
    return messagesAsync.when(
      data: (messages) => Text('${messages.length} messages'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Erreur: $err'),
    );
  },
),
```

### Rafraîchir manuellement

```dart
ElevatedButton(
  onPressed: () {
    ref.read(messagesNotifierProvider.notifier).refresh();
  },
  child: Text('Rafraîchir'),
),
```

### Filtrer par type

```dart
final notifier = ref.read(messagesNotifierProvider.notifier);

// Uniquement les notifications
final notifications = notifier.notifications;

// Uniquement les annonces
final annonces = notifier.annonces;
```

---

## 🐛 Dépannage Rapide

### Erreur : "Package device_info_plus not found"

```bash
flutter clean
flutter pub get
```

### Les messages ne s'affichent pas

1. Vérifier le token d'authentification :
```dart
final token = await AuthService().getToken();
print('Token: $token');
```

2. Vérifier l'URL de l'API dans `message_api_service.dart` :
```dart
static const String baseUrl = 'https://artluxurybus.ci/api';
```

3. Vérifier les logs :
```
📡 Status Code: 200 ✅
📡 Status Code: 401 ❌ (Problème d'authentification)
📡 Status Code: 404 ❌ (Route introuvable)
```

### Le device_id n'est pas enregistré

Vérifier les logs :
```dart
await DeviceInfoService().printDeviceInfo();
```

Si vous voyez `device_id: unknown`, redémarrez l'app.

---

## ✅ Checklist de Démarrage

- [ ] `flutter pub get` exécuté
- [ ] Route `/messages` ajoutée
- [ ] Bouton d'accès ajouté dans le menu
- [ ] Message de test créé dans Laravel
- [ ] App lancée et testée
- [ ] Messages visibles dans l'écran
- [ ] Notification push testée
- [ ] Device ID enregistré (vérifier les logs)

---

## 📚 Documentation Complète

Pour plus de détails, consultez :
- `INTEGRATION_MESSAGES_DOCUMENTATION.md` : Documentation complète
- `lib/models/message_model.dart` : Modèle de données
- `lib/services/message_api_service.dart` : Service API
- `lib/providers/message_provider.dart` : Providers Riverpod
- `lib/screens/messages_screen.dart` : Écran d'affichage

---

## 🎉 C'est Prêt !

Votre application peut maintenant :
- ✅ Recevoir des messages ciblés par appareil
- ✅ Afficher les notifications et annonces
- ✅ Identifier l'appareil avec device_id
- ✅ Recevoir des notifications push
- ✅ Afficher un écran moderne et élégant

**Bon développement ! 🚀**
