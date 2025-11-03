# 🎯 Configuration Navigation - Notification vers Trajets

## Ce qui reste à faire côté Flutter

### 📍 Étape finale: Gérer la navigation au clic

Le backend envoie déjà les notifications avec `action: 'view_trips'`.  
Il faut maintenant gérer cette action côté Flutter.

---

## 🔧 Modification dans main.dart

### Localisation
Le `NotificationService` envoie déjà les données via un Stream.  
Il faut écouter ce stream dans `main.dart` et naviguer vers l'écran des trajets.

### Code à ajouter dans main.dart

Dans la méthode `initState()` du widget principal:

```dart
@override
void initState() {
  super.initState();
  
  // Écouter les notifications et gérer la navigation
  NotificationService.notificationStream?.listen((notificationData) {
    _handleNotificationNavigation(notificationData);
  });
}

void _handleNotificationNavigation(Map<String, dynamic> notificationData) {
  // Vérifier le type de notification
  final type = notificationData['data']?['type'] ?? '';
  final action = notificationData['data']?['action'] ?? '';
  
  if (type == 'new_ticket' && action == 'view_trips') {
    // Naviguer vers l'écran des trajets
    // Utiliser le router ou Navigator selon votre setup
    
    // Option 1: Avec GoRouter
    context.go('/trips');
    
    // Option 2: Avec Navigator classique
    Navigator.pushNamed(context, '/trips');
    
    // Option 3: Avec pushReplacement pour remplacer l'écran actuel
    Navigator.pushReplacementNamed(context, '/trips');
  }
}
```

---

## 📱 Alternative: Utiliser un GlobalKey

Si vous utilisez GoRouter, vous pouvez utiliser un GlobalKey pour la navigation:

```dart
// Dans main.dart, au niveau global
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,  // ← Ajouter cette ligne
      // ... reste du code
    );
  }
}

// Dans la gestion des notifications
void _handleNotificationNavigation(Map<String, dynamic> notificationData) {
  final type = notificationData['data']?['type'] ?? '';
  final action = notificationData['data']?['action'] ?? '';
  
  if (type == 'new_ticket' && action == 'view_trips') {
    // Utiliser le navigatorKey global
    navigatorKey.currentState?.pushNamed('/trips');
  }
}
```

---

## 🎨 Avec votre setup GoRouter actuel

Vu que vous utilisez `go_router`, voici la configuration recommandée:

```dart
// Dans main.dart
class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        // ... vos routes existantes
        GoRoute(
          path: '/trips',
          name: 'trips',
          builder: (context, state) => const MyTripsScreen(),
        ),
      ],
    );

    // Écouter les notifications
    NotificationService.notificationStream?.listen((notificationData) {
      _handleNotificationClick(notificationData);
    });
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    final type = data['data']?['type'] ?? '';
    final action = data['data']?['action'] ?? '';
    
    if (type == 'new_ticket' && action == 'view_trips') {
      // Navigation avec GoRouter
      _router.go('/trips');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      // ... reste de la configuration
    );
  }
}
```

---

## 🚨 Important: Gérer le contexte

### Problème courant
Si vous appelez la navigation en dehors du build tree, vous aurez une erreur:
```
Navigator operation requested with a context that does not include a Navigator
```

### Solution 1: Utiliser un GlobalKey (recommandé)
```dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Utiliser partout
navigatorKey.currentState?.pushNamed('/trips');
```

### Solution 2: Délai pour assurer que le contexte est prêt
```dart
Future.delayed(Duration(milliseconds: 500), () {
  if (mounted) {
    Navigator.pushNamed(context, '/trips');
  }
});
```

---

## 📲 Notification avec bouton d'action (Android)

Pour ajouter un bouton "Voir ticket" directement dans la notification Android:

```dart
// Dans notification_service.dart, méthode _showLocalNotification

const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'art_luxury_bus_channel',
      'Art Luxury Bus Notifications',
      // ... autres paramètres
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'view_ticket',           // ID de l'action
          'Voir ticket',           // Texte du bouton
          icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          showsUserInterface: true,
        ),
      ],
    );
```

---

## ✅ Checklist de test

### Test 1: Notification en premier plan (app ouverte)
- [ ] Créer un ticket
- [ ] Notification apparaît en haut de l'écran
- [ ] Cliquer sur la notification
- [ ] L'écran "Mes trajets" s'ouvre
- [ ] Le nouveau ticket est visible

### Test 2: Notification en arrière-plan (app minimisée)
- [ ] Minimiser l'app
- [ ] Créer un ticket
- [ ] Notification apparaît dans le tiroir Android
- [ ] Cliquer sur la notification
- [ ] L'app s'ouvre sur "Mes trajets"

### Test 3: Notification avec app fermée
- [ ] Fermer complètement l'app
- [ ] Créer un ticket
- [ ] Notification apparaît
- [ ] Cliquer sur la notification
- [ ] L'app démarre et ouvre "Mes trajets"

---

## 🐛 Debug

### Voir les données de notification
```dart
NotificationService.notificationStream?.listen((data) {
  print('🔔 Notification reçue:');
  print('   Type: ${data['data']?['type']}');
  print('   Action: ${data['data']?['action']}');
  print('   Ticket ID: ${data['data']?['ticket_id']}');
  print('   Toutes les données: $data');
});
```

### Logs attendus
```
🔔 Notification reçue:
   Type: new_ticket
   Action: view_trips
   Ticket ID: 123
   Toutes les données: {type: notification, data: {type: new_ticket, ...}}
```

---

## 🎯 Résultat final

### Comportement attendu:

1. **Ticket créé** (mobile ou guichet)
2. **Notification push envoyée** au client
3. **Client reçoit:** "🎫 Nouveau ticket créé !"
4. **Client clique** sur la notification
5. **App ouvre** l'écran "Mes trajets"
6. **Ticket visible** dans la liste

---

## 💡 Bonus: Navigation vers le détail spécifique

Pour ouvrir directement le détail du ticket (et non la liste):

```dart
void _handleNotificationClick(Map<String, dynamic> data) {
  final type = data['data']?['type'] ?? '';
  final action = data['data']?['action'] ?? '';
  final ticketId = data['data']?['ticket_id'];
  
  if (type == 'new_ticket' && action == 'view_trips') {
    if (ticketId != null) {
      // Navigation vers le détail du ticket spécifique
      _router.go('/trips/$ticketId');
    } else {
      // Navigation vers la liste
      _router.go('/trips');
    }
  }
}
```

---

Cette configuration permettra une expérience utilisateur fluide avec navigation automatique vers les trajets lors du clic sur la notification ! 🚀
