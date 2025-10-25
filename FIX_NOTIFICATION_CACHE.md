# 🔧 Fix : Cache des notifications obsolètes

## 🐛 Problème identifié

L'app affiche des notifications qui n'existent plus dans la base de données car :

1. **Chargement unique** : Les notifications sont chargées UNE SEULE FOIS au démarrage
2. **Pas de rafraîchissement automatique** : Quand on revient sur l'onglet Notifications
3. **Cache persistant** : Les données restent en mémoire même si elles sont supprimées côté serveur

## 📍 Où se situe le problème

### Fichier : `lib/screens/home_page.dart`

**Ligne 59** : Chargement initial
```dart
ref.read(notificationProvider.notifier).loadNotifications(refresh: true);
```

**Problème** : Appelé UNE SEULE FOIS au démarrage, jamais rafraîchi après.

## ✅ Solutions

### Solution 1 : Rafraîchir quand on change d'onglet (RECOMMANDÉ)

Ajouter un listener pour détecter quand l'utilisateur revient sur l'onglet Notifications.

**Modification dans `home_page.dart`** :

```dart
// Dans la classe _HomePageState

int _currentIndex = 0;

void _onTabChanged(int index) {
  setState(() {
    _currentIndex = index;
  });
  
  // Si on va sur l'onglet Notifications (index 1), rafraîchir
  if (index == 1) {
    ref.read(notificationProvider.notifier).loadNotifications(refresh: true);
  }
}

// Dans le build(), modifier le BottomNavigationBar
BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: _onTabChanged,  // ← Utiliser la nouvelle fonction
  // ... reste du code
)
```

### Solution 2 : Pull-to-refresh (DÉJÀ IMPLÉMENTÉ)

L'utilisateur peut tirer vers le bas pour rafraîchir manuellement.

**Vérifier que c'est bien implémenté** dans l'onglet Notifications :

```dart
RefreshIndicator(
  onRefresh: () async {
    await ref.read(notificationProvider.notifier).loadNotifications(refresh: true);
  },
  child: ListView(...),
)
```

### Solution 3 : Rafraîchissement périodique (OPTIONNEL)

Rafraîchir automatiquement toutes les X minutes.

```dart
Timer? _notificationRefreshTimer;

@override
void initState() {
  super.initState();
  
  // Rafraîchir toutes les 2 minutes
  _notificationRefreshTimer = Timer.periodic(
    const Duration(minutes: 2),
    (_) {
      if (_currentIndex == 1) { // Seulement si on est sur l'onglet Notifications
        ref.read(notificationProvider.notifier).loadNotifications(refresh: true);
      }
    },
  );
}

@override
void dispose() {
  _notificationRefreshTimer?.cancel();
  super.dispose();
}
```

## 🔧 Correction du Provider (IMPORTANT)

### Fichier : `lib/providers/notification_provider.dart`

**Problème actuel (ligne 70-82)** :
```dart
if (response.success) {
  final newNotifications = refresh 
    ? response.notifications
    : [...state.notifications, ...response.notifications];

  state = state.copyWith(
    notifications: newNotifications,
    // ...
  );
}
```

**Problème** : Si `response.notifications` est vide, on garde l'ancienne liste !

**Solution** : Toujours remplacer la liste en mode refresh :

```dart
if (response.success) {
  final newNotifications = refresh 
    ? response.notifications  // ← Même si vide, on remplace !
    : [...state.notifications, ...response.notifications];

  state = state.copyWith(
    notifications: newNotifications,
    isLoading: false,
    unreadCount: response.unreadCount,
    hasMore: response.notifications.length >= 20,
    currentPage: refresh ? 2 : state.currentPage + 1,
    error: null,
  );
  
  // Log pour debug
  print('📋 [PROVIDER] ${newNotifications.length} notifications chargées');
  print('🔢 [PROVIDER] ${response.unreadCount} non lues');
}
```

## 🎯 Implémentation recommandée

### Étape 1 : Modifier `home_page.dart`

Ajouter le rafraîchissement automatique quand on change d'onglet :

```dart
class _HomePageState extends ConsumerStatefulWidget {
  // ... code existant
  
  int _currentIndex = 0;
  
  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Rafraîchir les notifications quand on va sur l'onglet
    if (index == 1) {
      print('🔄 [HomePage] Rafraîchissement des notifications...');
      ref.read(notificationProvider.notifier).loadNotifications(refresh: true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // ... code existant
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildNotificationsTab(),
          _buildServicesTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,  // ← IMPORTANT : Utiliser la nouvelle fonction
        items: [
          // ... items existants
        ],
      ),
    );
  }
}
```

### Étape 2 : Ajouter des logs dans le provider

Pour voir ce qui se passe :

```dart
Future<void> loadNotifications({bool refresh = false}) async {
  print('🔄 [PROVIDER] Chargement notifications (refresh: $refresh)');
  
  if (refresh) {
    print('🗑️ [PROVIDER] Vidage du cache...');
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 1,
      notifications: [],  // ← Vider le cache
    );
  }
  
  try {
    final response = await NotificationApiService.getNotifications(
      page: refresh ? 1 : state.currentPage,
      limit: 20,
    );
    
    print('📡 [PROVIDER] Réponse API: success=${response.success}');
    print('📋 [PROVIDER] Nombre de notifications: ${response.notifications.length}');
    
    if (response.success) {
      final newNotifications = refresh 
        ? response.notifications
        : [...state.notifications, ...response.notifications];
      
      print('✅ [PROVIDER] Mise à jour: ${newNotifications.length} notifications');
      
      state = state.copyWith(
        notifications: newNotifications,
        isLoading: false,
        unreadCount: response.unreadCount,
        hasMore: response.notifications.length >= 20,
        currentPage: refresh ? 2 : state.currentPage + 1,
        error: null,
      );
    }
  } catch (e) {
    print('❌ [PROVIDER] Erreur: $e');
    state = state.copyWith(
      isLoading: false,
      error: 'Erreur de connexion: $e',
    );
  }
}
```

## 🧪 Test après correction

### Scénario 1 : Notifications supprimées

1. **Supprimer toutes les notifications** dans la base de données
2. **Dans l'app** : Aller sur un autre onglet puis revenir sur Notifications
3. **Résultat attendu** : Liste vide avec message "Aucune notification"
4. **Logs attendus** :
   ```
   🔄 [HomePage] Rafraîchissement des notifications...
   🔄 [PROVIDER] Chargement notifications (refresh: true)
   🗑️ [PROVIDER] Vidage du cache...
   📡 [PROVIDER] Réponse API: success=true
   📋 [PROVIDER] Nombre de notifications: 0
   ✅ [PROVIDER] Mise à jour: 0 notifications
   ```

### Scénario 2 : Nouvelles notifications

1. **Créer des notifications** dans la base de données
2. **Dans l'app** : Changer d'onglet puis revenir sur Notifications
3. **Résultat attendu** : Nouvelles notifications apparaissent
4. **Logs attendus** :
   ```
   🔄 [HomePage] Rafraîchissement des notifications...
   📋 [PROVIDER] Nombre de notifications: 3
   ✅ [PROVIDER] Mise à jour: 3 notifications
   ```

## 📊 Résumé des changements

| Fichier | Modification | Objectif |
|---------|--------------|----------|
| `home_page.dart` | Ajouter `_onTabChanged()` | Rafraîchir quand on change d'onglet |
| `notification_provider.dart` | Ajouter logs | Voir ce qui se passe |
| `notification_provider.dart` | Vider cache en refresh | Supprimer les données obsolètes |

## 🎯 Avantages

- ✅ **Données toujours à jour** : Rafraîchissement automatique
- ✅ **Pas de cache obsolète** : Les notifications supprimées disparaissent
- ✅ **Meilleure UX** : L'utilisateur voit toujours les vraies données
- ✅ **Debug facile** : Logs pour comprendre ce qui se passe

## 🚀 Prochaines étapes

1. ✅ Implémenter `_onTabChanged()` dans `home_page.dart`
2. ✅ Ajouter les logs dans le provider
3. ✅ Tester avec des notifications réelles
4. ✅ Vérifier que le cache se vide correctement
5. ✅ Retirer les logs une fois que tout fonctionne

---

**Note** : Le pull-to-refresh fonctionne déjà, mais l'utilisateur doit le faire manuellement. Avec cette correction, le rafraîchissement sera automatique à chaque fois qu'il revient sur l'onglet Notifications.
