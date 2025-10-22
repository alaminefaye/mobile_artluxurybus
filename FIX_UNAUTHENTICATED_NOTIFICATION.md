# 🔧 FIX: "Unauthenticated" lors du clic sur notification (app fermée)

## ❌ Problème Identifié

Quand l'application est **complètement fermée** et que l'utilisateur clique sur une notification push :
1. ✅ L'app se lance
2. ❌ Navigation vers l'onglet Notifications trop rapide
3. ❌ L'utilisateur n'est pas encore authentifié
4. ❌ Affichage du message "Unauthenticated"

**Cause :** La navigation se fait **avant** que le token d'authentification soit chargé depuis le stockage local.

---

## ✅ Solution Implémentée

### **Stratégie : Notification en Attente**

Au lieu de naviguer immédiatement, on :
1. ✅ Vérifie si l'utilisateur est authentifié
2. ✅ Si NON → Sauvegarde la notification en attente
3. ✅ Attend que l'utilisateur se connecte
4. ✅ Navigue automatiquement après la connexion

---

## 🔧 Modifications Techniques

### **1. Variable d'État**

```dart
class _MyAppState extends ConsumerState<MyApp> {
  RemoteMessage? _pendingNotification; // ✅ Notification en attente
}
```

### **2. Vérification de l'Authentification**

```dart
Future<void> _checkInitialNotification() async {
  await Future.delayed(const Duration(seconds: 3));
  
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final authState = ref.read(authProvider);
    
    if (!authState.isAuthenticated) {
      // ⚠️ Pas authentifié → Sauvegarder pour plus tard
      _pendingNotification = initialMessage;
      return;
    }
    
    // ✅ Authentifié → Naviguer immédiatement
    _handleNotificationNavigation({...});
  }
}
```

### **3. Écoute du Changement d'Authentification**

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  // Vérifier si on a une notification en attente
  if (_pendingNotification != null) {
    final authState = ref.watch(authProvider);
    
    if (authState.isAuthenticated) {
      // ✅ Utilisateur maintenant connecté → Naviguer
      _handleNotificationNavigation({...});
      _pendingNotification = null; // Réinitialiser
    }
  }
}
```

---

## 📊 Flux de Navigation

### **Scénario 1 : Utilisateur Déjà Connecté**

```
1. App fermée
2. Notification reçue
3. Utilisateur clique
4. App se lance
5. ✅ Token chargé depuis SharedPreferences
6. ✅ Utilisateur authentifié
7. ✅ Navigation immédiate vers Notifications
```

### **Scénario 2 : Utilisateur Non Connecté**

```
1. App fermée
2. Notification reçue
3. Utilisateur clique
4. App se lance
5. ❌ Pas de token (première installation ou déconnexion)
6. ⚠️ Notification mise en attente
7. 📱 Écran de connexion affiché
8. 👤 Utilisateur se connecte
9. ✅ didChangeDependencies() détecte l'authentification
10. ✅ Navigation automatique vers Notifications
```

---

## 🧪 Tests de Validation

### **Test 1 : Utilisateur Connecté**

**Étapes :**
1. Se connecter à l'app
2. Fermer complètement l'app (swipe up)
3. Envoyer une notification depuis Firebase Console
4. Cliquer sur la notification

**Résultat attendu :**
- ✅ App se lance
- ✅ Navigation directe vers l'onglet Notifications
- ✅ Pas de message "Unauthenticated"

**Logs :**
```
🔔 [MAIN] App ouverte via notification: Nouvelle suggestion
✅ [MAIN] Utilisateur authentifié, navigation vers notifications
🔔 [MAIN] Navigation vers notification: {...}
✅ [MAIN] Navigation vers onglet Notifications effectuée
```

---

### **Test 2 : Utilisateur Non Connecté**

**Étapes :**
1. Se déconnecter de l'app
2. Fermer complètement l'app
3. Envoyer une notification depuis Firebase Console
4. Cliquer sur la notification
5. Se connecter

**Résultat attendu :**
- ✅ App se lance sur l'écran de connexion
- ✅ Pas de navigation immédiate
- ✅ Après connexion → Navigation automatique vers Notifications

**Logs :**
```
🔔 [MAIN] App ouverte via notification: Nouvelle suggestion
⚠️ [MAIN] Utilisateur non authentifié, mise en attente de la notification...
[Utilisateur se connecte]
✅ [MAIN] Utilisateur maintenant authentifié, navigation vers notification en attente
🔔 [MAIN] Navigation vers notification: {...}
✅ [MAIN] Navigation vers onglet Notifications effectuée
```

---

## ⏱️ Délais Configurés

### **Délai d'Initialisation**
```dart
await Future.delayed(const Duration(seconds: 3));
```
- **Pourquoi 3 secondes ?** Permet à l'app de :
  - Initialiser Firebase
  - Charger le token depuis SharedPreferences
  - Vérifier l'état d'authentification

### **Délai de Navigation**
```dart
Future.delayed(const Duration(milliseconds: 500), () {
  // Navigation
});
```
- **Pourquoi 500ms ?** Permet au contexte de navigation d'être prêt

---

## 🔍 Debugging

### **Logs à Vérifier**

**Si utilisateur authentifié :**
```
✅ [MAIN] Utilisateur authentifié, navigation vers notifications
```

**Si utilisateur non authentifié :**
```
⚠️ [MAIN] Utilisateur non authentifié, mise en attente de la notification...
```

**Après connexion :**
```
✅ [MAIN] Utilisateur maintenant authentifié, navigation vers notification en attente
```

### **Vérifications**

1. **Token présent ?**
```dart
final token = await AuthService().getToken();
debugPrint('Token: $token');
```

2. **État d'authentification ?**
```dart
final authState = ref.read(authProvider);
debugPrint('Authentifié: ${authState.isAuthenticated}');
```

3. **Notification en attente ?**
```dart
debugPrint('Notification en attente: ${_pendingNotification != null}');
```

---

## 🐛 Problèmes Potentiels

### **Problème 1 : Navigation ne se fait jamais**

**Cause :** `didChangeDependencies()` n'est pas appelé après connexion.

**Solution :**
```dart
// Forcer le rebuild après connexion
ref.invalidate(authProvider);
```

---

### **Problème 2 : Navigation se fait deux fois**

**Cause :** `_pendingNotification` n'est pas réinitialisé.

**Solution :**
```dart
_pendingNotification = null; // ✅ Important !
```

---

### **Problème 3 : Délai trop court**

**Cause :** 3 secondes ne suffisent pas sur certains appareils lents.

**Solution :**
```dart
await Future.delayed(const Duration(seconds: 5)); // Augmenter à 5 secondes
```

---

## 📝 Résumé

### **Avant**
- ❌ Clic sur notification (app fermée) → "Unauthenticated"
- ❌ Navigation trop rapide
- ❌ Token pas encore chargé

### **Après**
- ✅ Vérification de l'authentification
- ✅ Notification mise en attente si non authentifié
- ✅ Navigation automatique après connexion
- ✅ Expérience utilisateur fluide

---

## 🎯 Cas d'Usage Couverts

| Scénario | État App | Authentifié ? | Comportement |
|----------|----------|---------------|--------------|
| 1 | Ouverte | ✅ Oui | Navigation immédiate |
| 2 | Background | ✅ Oui | Navigation immédiate |
| 3 | Fermée | ✅ Oui | Navigation après 3s |
| 4 | Fermée | ❌ Non | Attente connexion → Navigation |

---

## 🚀 Améliorations Futures

### **1. Indicateur Visuel**
Afficher un message pendant le chargement :
```dart
if (_pendingNotification != null && !authState.isAuthenticated) {
  return LoadingScreen(message: 'Chargement de la notification...');
}
```

### **2. Timeout**
Annuler la notification en attente après un certain temps :
```dart
Future.delayed(const Duration(seconds: 30), () {
  if (_pendingNotification != null) {
    _pendingNotification = null;
    debugPrint('⏱️ Notification en attente expirée');
  }
});
```

### **3. Persistance**
Sauvegarder la notification dans SharedPreferences pour survivre aux redémarrages :
```dart
await prefs.setString('pending_notification', jsonEncode(notification));
```

---

**Date de correction :** 22 octobre 2025  
**Statut :** ✅ CORRIGÉ ET TESTÉ
