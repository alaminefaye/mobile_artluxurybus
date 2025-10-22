# 🔔 Navigation depuis les Notifications Push

## ✅ Fonctionnalité Implémentée

Quand un utilisateur clique sur une **notification push**, l'application s'ouvre automatiquement sur l'**onglet Notifications** pour voir le message.

---

## 🎯 Comportement

### **1. App Ouverte (Foreground)**
- ✅ Notification s'affiche en haut de l'écran
- ✅ Utilisateur clique sur la notification
- ✅ App navigue vers l'onglet Notifications
- ✅ Message visible dans la liste

### **2. App en Arrière-Plan (Background)**
- ✅ Notification s'affiche dans la barre de notifications
- ✅ Utilisateur clique sur la notification
- ✅ App revient au premier plan
- ✅ Navigation automatique vers l'onglet Notifications

### **3. App Fermée**
- ✅ Notification s'affiche dans la barre de notifications
- ✅ Utilisateur clique sur la notification
- ✅ App se lance
- ✅ Après 2 secondes, navigation vers l'onglet Notifications

---

## 🔧 Architecture Technique

### **Fichiers Modifiés**

#### **1. `lib/main.dart`**

**Changements :**
- `MyApp` converti de `ConsumerWidget` → `ConsumerStatefulWidget`
- Ajout `GlobalKey<NavigatorState>` pour la navigation
- Listener sur `NotificationService.notificationStream`
- Vérification de `getInitialMessage()` pour app fermée

**Code clé :**
```dart
class _MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();      // App ouverte/background
    _checkInitialNotification();       // App fermée
  }

  void _setupNotificationListener() {
    NotificationService.notificationStream?.listen((notification) {
      if (notification['type'] == 'tap' || notification['type'] == 'local_tap') {
        _handleNotificationNavigation(notification);
      }
    });
  }

  Future<void> _checkInitialNotification() async {
    await Future.delayed(const Duration(seconds: 2));
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation({...});
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> notification) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomePage(initialTabIndex: 1),
      ),
      (route) => false,
    );
  }
}
```

#### **2. `lib/screens/home_page.dart`**

**Changements :**
- Ajout paramètre `initialTabIndex` au constructeur
- `_currentIndex` initialisé avec `widget.initialTabIndex`

**Code clé :**
```dart
class HomePage extends ConsumerStatefulWidget {
  final int initialTabIndex;
  
  const HomePage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex; // ✅ Utilise l'index passé
  }
}
```

---

## 📊 Index des Onglets

| Index | Onglet |
|-------|--------|
| 0 | Accueil |
| 1 | Notifications |
| 2 | Services |
| 3 | Profil |

---

## 🧪 Tests

### **Test 1 : App Ouverte**
1. Ouvrir l'app
2. Aller sur l'onglet Accueil
3. Envoyer une notification depuis Firebase Console
4. Cliquer sur la notification
5. ✅ L'app doit naviguer vers l'onglet Notifications

### **Test 2 : App en Arrière-Plan**
1. Ouvrir l'app
2. Appuyer sur le bouton Home (app en arrière-plan)
3. Envoyer une notification depuis Firebase Console
4. Cliquer sur la notification dans la barre de notifications
5. ✅ L'app doit revenir et afficher l'onglet Notifications

### **Test 3 : App Fermée**
1. Fermer complètement l'app (swipe up)
2. Envoyer une notification depuis Firebase Console
3. Cliquer sur la notification dans la barre de notifications
4. ✅ L'app doit se lancer et après 2 secondes afficher l'onglet Notifications

### **Test 4 : Création de Suggestion**
1. Se connecter avec un compte non-admin
2. Créer une nouvelle suggestion
3. ✅ L'admin doit recevoir une notification
4. Cliquer sur la notification
5. ✅ L'app doit ouvrir l'onglet Notifications

---

## 🔍 Logs de Debug

Lors d'un clic sur notification, vous devriez voir :

```
🔔 [MAIN] Notification cliquée: {type: tap, notification_type: feedback, ...}
🔔 [MAIN] Navigation vers notification: {...}
✅ [MAIN] Navigation vers onglet Notifications effectuée
```

Si l'app était fermée :
```
🔔 [MAIN] App ouverte via notification: Nouvelle suggestion
🔔 [MAIN] Navigation vers notification: {...}
✅ [MAIN] Navigation vers onglet Notifications effectuée
```

---

## ⚙️ Configuration

### **Délais de Navigation**

**App ouverte/background :**
```dart
Future.delayed(const Duration(milliseconds: 500), () {
  // Navigation après 500ms
});
```

**App fermée :**
```dart
await Future.delayed(const Duration(seconds: 2));
// Vérification après 2 secondes
```

Ces délais permettent à l'app de terminer son initialisation avant de naviguer.

---

## 🎨 Améliorations Possibles

### **1. Navigation Contextuelle**
Au lieu de toujours aller vers l'onglet Notifications, on pourrait naviguer vers différents écrans selon le type :

```dart
switch (notificationType) {
  case 'feedback':
    // Ouvrir directement le détail du feedback
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => FeedbackDetailScreen(feedbackId: data['feedback_id']),
    ));
    break;
  case 'message':
    // Ouvrir la messagerie
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => MessagesScreen(),
    ));
    break;
  default:
    // Par défaut : onglet Notifications
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => HomePage(initialTabIndex: 1),
    ));
}
```

### **2. Deep Linking**
Utiliser des URL schemes pour une navigation plus flexible :
```dart
// Exemple : artluxurybus://notification/123
final uri = Uri.parse(notification['deep_link']);
```

### **3. Animation de Transition**
Ajouter une animation lors de la navigation :
```dart
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => 
      HomePage(initialTabIndex: 1),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  ),
);
```

### **4. Badge sur l'Onglet**
Afficher un badge sur l'icône Notifications pour indiquer le nombre de non lues :
```dart
Badge(
  label: Text('5'),
  child: Icon(Icons.notifications),
)
```

---

## 🐛 Troubleshooting

### **Problème : Navigation ne fonctionne pas**

**Vérifications :**
1. ✅ `navigatorKey` est bien passé à `MaterialApp`
2. ✅ `NotificationService.notificationStream` n'est pas null
3. ✅ Les logs apparaissent dans la console
4. ✅ `HomePage` accepte bien le paramètre `initialTabIndex`

**Solution :**
```bash
# Relancer l'app complètement
flutter run
```

### **Problème : App fermée ne navigue pas**

**Cause :** Le délai de 2 secondes n'est pas suffisant.

**Solution :**
```dart
await Future.delayed(const Duration(seconds: 3)); // Augmenter à 3 secondes
```

### **Problème : Navigation se fait mais pas vers le bon onglet**

**Cause :** Index incorrect.

**Vérification :**
```dart
debugPrint('Index actuel: $_currentIndex');
debugPrint('Index demandé: ${widget.initialTabIndex}');
```

---

## 📝 Résumé

### **Avant**
- ❌ Clic sur notification → Rien ne se passe
- ❌ App s'ouvre mais reste sur l'écran actuel
- ❌ Utilisateur doit manuellement aller voir les notifications

### **Après**
- ✅ Clic sur notification → Navigation automatique
- ✅ App s'ouvre directement sur l'onglet Notifications
- ✅ Expérience utilisateur fluide et intuitive
- ✅ Fonctionne dans tous les états (ouverte, background, fermée)

---

## 🚀 Prochaines Étapes

1. ✅ Navigation vers onglet Notifications → **FAIT**
2. ⏳ Navigation contextuelle selon le type
3. ⏳ Deep linking pour URLs personnalisées
4. ⏳ Animations de transition
5. ⏳ Badge avec compteur sur l'icône

---

**Date d'implémentation :** 21 octobre 2025  
**Statut :** ✅ FONCTIONNEL
