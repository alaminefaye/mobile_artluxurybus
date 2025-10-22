# 🔔 Navigation vers le Détail de la Notification

## ✅ Fonctionnalité Implémentée

Quand un utilisateur clique sur une **notification push**, l'application :
1. ✅ S'ouvre sur l'onglet Notifications
2. ✅ **Ouvre automatiquement le détail de la notification**

---

## 🎯 Flux de Navigation

### **Étape 1 : Onglet Notifications**
```
Clic notification → HomePage (onglet Notifications)
```

### **Étape 2 : Détail de la Notification**
```
HomePage → NotificationDetailScreen (détail du message)
```

**Délai total :** 1.5 secondes (500ms + 1000ms)

---

## 🔧 Code Implémenté

### **Navigation en Deux Étapes**

```dart
void _handleNotificationNavigation(Map<String, dynamic> notification) {
  // Étape 1 : Naviguer vers HomePage (onglet Notifications)
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) => const HomePage(initialTabIndex: 1),
    ),
    (route) => false,
  );
  
  // Étape 2 : Ouvrir le détail si on a un ID
  final data = notification['data'] as Map<String, dynamic>?;
  if (data != null && data['notification_id'] != null) {
    Future.delayed(const Duration(milliseconds: 1000), () {
      // Créer NotificationModel
      final notificationModel = NotificationModel(
        id: int.tryParse(data['notification_id'].toString()) ?? 0,
        title: notification['title']?.toString() ?? '',
        message: notification['body']?.toString() ?? '',
        type: data['type']?.toString() ?? '',
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      // Naviguer vers le détail
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NotificationDetailScreen(
            notification: notificationModel,
          ),
        ),
      );
    });
  }
}
```

---

## 📦 Données Requises dans la Notification

### **Structure Attendue**

La notification Firebase doit contenir :

```json
{
  "notification": {
    "title": "Nouvelle suggestion",
    "body": "Un utilisateur a soumis une nouvelle suggestion"
  },
  "data": {
    "type": "feedback",
    "notification_id": "123",  // ✅ IMPORTANT !
    "feedback_id": "456",
    "user_id": "1"
  }
}
```

### **Champ Critique : `notification_id`**

Le champ `data.notification_id` est **obligatoire** pour ouvrir le détail.

---

## 🔧 Configuration Laravel

### **Vérifier que Laravel envoie `notification_id`**

Fichier : `app/Services/NotificationService.php`

```php
public static function sendToUser($userId, $title, $body, $data = [])
{
    // S'assurer que notification_id est inclus
    $notificationData = array_merge($data, [
        'notification_id' => $data['notification_id'] ?? null,
        'type' => $data['type'] ?? 'general',
        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
    ]);
    
    $message = [
        'token' => $fcmToken,
        'notification' => [
            'title' => $title,
            'body' => $body,
        ],
        'data' => $notificationData,  // ✅ Inclut notification_id
    ];
    
    // Envoyer via Firebase
}
```

### **Exemple dans FeedbackController**

```php
// Créer la notification en BDD
$notification = Notification::create([
    'user_id' => $adminId,
    'title' => 'Nouvelle suggestion',
    'message' => 'Un utilisateur a soumis une suggestion',
    'type' => 'feedback',
    'data' => json_encode(['feedback_id' => $feedback->id]),
]);

// Envoyer push notification avec l'ID
NotificationService::sendToUser(
    $adminId,
    'Nouvelle suggestion',
    'Un utilisateur a soumis une suggestion',
    [
        'type' => 'feedback',
        'notification_id' => $notification->id,  // ✅ ID de la notification
        'feedback_id' => $feedback->id,
    ]
);
```

---

## 🧪 Tests

### **Test 1 : Avec `notification_id`**

**Données notification :**
```json
{
  "data": {
    "notification_id": "123",
    "type": "feedback"
  }
}
```

**Résultat attendu :**
1. ✅ App s'ouvre sur onglet Notifications
2. ✅ Détail de la notification s'ouvre automatiquement
3. ✅ Affichage du titre et message

**Logs :**
```
✅ [MAIN] Navigation vers onglet Notifications effectuée
✅ [MAIN] Navigation vers détail de la notification effectuée
```

---

### **Test 2 : Sans `notification_id`**

**Données notification :**
```json
{
  "data": {
    "type": "feedback"
  }
}
```

**Résultat attendu :**
1. ✅ App s'ouvre sur onglet Notifications
2. ❌ Pas d'ouverture automatique du détail
3. ✅ Utilisateur voit la liste des notifications

**Logs :**
```
✅ [MAIN] Navigation vers onglet Notifications effectuée
(Pas de log de navigation vers détail)
```

---

## ⏱️ Délais de Navigation

### **Délai 1 : 500ms**
```dart
Future.delayed(const Duration(milliseconds: 500), () {
  // Navigation vers HomePage
});
```
- Permet au contexte de navigation d'être prêt

### **Délai 2 : 1000ms**
```dart
Future.delayed(const Duration(milliseconds: 1000), () {
  // Navigation vers détail
});
```
- Permet à HomePage d'être complètement montée

**Total :** 1.5 secondes entre le clic et l'ouverture du détail

---

## 🔍 Debugging

### **Vérifier les Données de la Notification**

```dart
debugPrint('📦 [MAIN] Données notification: ${notification['data']}');
```

**Exemple de sortie :**
```
📦 [MAIN] Données notification: {type: feedback, notification_id: 123, feedback_id: 456}
```

### **Vérifier si l'ID est Présent**

```dart
final data = notification['data'] as Map<String, dynamic>?;
debugPrint('🆔 [MAIN] Notification ID: ${data?['notification_id']}');
```

**Si null :**
```
🆔 [MAIN] Notification ID: null
⚠️ [MAIN] Pas d'ID, navigation vers détail ignorée
```

---

## 🐛 Problèmes Potentiels

### **Problème 1 : Détail ne s'ouvre pas**

**Cause :** `notification_id` manquant dans les données.

**Solution :**
1. Vérifier les logs : `📦 [MAIN] Données notification:`
2. Modifier Laravel pour inclure `notification_id`
3. Tester avec Firebase Console en ajoutant manuellement l'ID

**Test Firebase Console :**
```json
{
  "notification": {
    "title": "Test",
    "body": "Message de test"
  },
  "data": {
    "type": "test",
    "notification_id": "999"
  }
}
```

---

### **Problème 2 : Erreur "NotificationModel not found"**

**Cause :** Import manquant.

**Solution :**
```dart
import 'models/notification_model.dart';
```

---

### **Problème 3 : Navigation trop rapide**

**Cause :** HomePage pas encore montée.

**Solution :** Augmenter le délai
```dart
Future.delayed(const Duration(milliseconds: 1500), () {
  // Navigation vers détail
});
```

---

## 🎨 Améliorations Futures

### **1. Animation de Transition**
```dart
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => 
      NotificationDetailScreen(notification: notificationModel),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
  ),
);
```

### **2. Indicateur de Chargement**
```dart
// Afficher un loader pendant la navigation
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => const Center(
    child: CircularProgressIndicator(),
  ),
);
```

### **3. Gestion des Erreurs**
```dart
try {
  final notificationModel = NotificationModel(...);
  Navigator.of(context).push(...);
} catch (e) {
  debugPrint('❌ [MAIN] Erreur navigation détail: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Impossible d\'ouvrir la notification')),
  );
}
```

---

## 📝 Résumé

### **Avant**
- ✅ Navigation vers onglet Notifications
- ❌ Utilisateur doit cliquer manuellement sur la notification
- ❌ Pas d'ouverture automatique du détail

### **Après**
- ✅ Navigation vers onglet Notifications
- ✅ **Ouverture automatique du détail**
- ✅ Expérience utilisateur fluide
- ✅ Moins de clics nécessaires

---

## 🎯 Cas d'Usage

| Scénario | `notification_id` | Comportement |
|----------|-------------------|--------------|
| Nouvelle suggestion | ✅ Présent | Ouvre le détail automatiquement |
| Notification système | ❌ Absent | Affiche la liste seulement |
| Message admin | ✅ Présent | Ouvre le détail automatiquement |

---

**Date d'implémentation :** 22 octobre 2025  
**Statut :** ✅ IMPLÉMENTÉ
