# 🧪 Guide de Test - Notifications de Tickets

## ✅ État actuel de la configuration

D'après les logs, tout est bien configuré :
- ✅ Canal Android créé : `art_luxury_bus_channel`
- ✅ Importance : `Importance.max`
- ✅ Son activé : `true`
- ✅ Vibration activée : `true`
- ✅ Token FCM enregistré avec succès (ID: 50)

## 🧪 Tests à effectuer

### Test 1 : Vérifier le token FCM en base de données

**Sur le backend Laravel**, vérifier que le token est bien enregistré :

```sql
SELECT id, user_id, token, device_type, is_active, created_at 
FROM fcm_tokens 
WHERE user_id = [VOTRE_USER_ID]
ORDER BY created_at DESC;
```

**Vérifier :**
- ✅ Le token existe
- ✅ `is_active = 1`
- ✅ Le `device_type` correspond (`android` ou `ios`)
- ✅ Le `user_id` correspond à votre compte

### Test 2 : Créer un ticket depuis le guichet

1. **Connectez-vous au backoffice** (guichet)
2. **Créez un ticket** pour votre numéro de téléphone (celui associé à votre compte utilisateur)
3. **Vérifiez les logs Laravel** pour voir si la notification est envoyée :
   ```
   [INFO] Notification nouveau ticket envoyée
   ```

### Test 3 : Créer un ticket depuis l'API mobile

1. **Connectez-vous à l'app mobile**
2. **Faites une réservation** (création de ticket)
3. **Vérifiez les logs Laravel** pour voir si la notification est envoyée

### Test 4 : Vérifier la réception de la notification

**Avec l'app EN ARRIÈRE-PLAN (app minimisée) :**

1. Minimisez l'app (pas fermée complètement)
2. Créez un ticket depuis le backend
3. **Vous devriez voir :**
   - 📱 Notification système Android/iOS
   - 🔊 Son de notification
   - 📳 Vibration
   - 📲 Badge sur l'icône de l'app

**Vérifiez les logs Flutter :**
```
📱 [NotificationService] Message reçu en arrière-plan:
   - Titre: 🎫 Nouveau ticket créé !
   - Corps: Votre ticket pour...
```

**Avec l'app FERMÉE complètement :**

1. Fermez complètement l'app (swipe away)
2. Créez un ticket depuis le backend
3. **Vous devriez voir :**
   - 📱 Notification système Android/iOS
   - 🔊 Son de notification
   - 📳 Vibration

### Test 5 : Vérifier le payload de la notification

**Dans les logs Laravel**, vérifier que le payload contient :

```json
{
  "token": "[FCM_TOKEN]",
  "notification": {
    "title": "🎫 Nouveau ticket créé !",
    "body": "Votre ticket pour..."
  },
  "android": {
    "priority": "high",
    "notification": {
      "sound": "default",
      "channel_id": "art_luxury_bus_channel",
      "priority": "high"
    }
  },
  "apns": {
    "headers": {
      "apns-priority": "10"
    },
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  },
  "data": {
    "type": "new_ticket",
    "ticket_id": "...",
    "action": "view_trips"
  }
}
```

## 🔍 Points de vérification

### 1. Vérifier les permissions Android

**Paramètres Android :**
1. Paramètres → Applications → Art Luxury Bus
2. Notifications → **Activées** ✅
3. Canal "Art Luxury Bus Notifications" :
   - Importance : **Élevée** ✅
   - Son : **Activé** ✅
   - Vibration : **Activée** ✅

### 2. Vérifier les logs backend

**Fichier :** `storage/logs/laravel.log`

Chercher les lignes :
```
[INFO] Notification nouveau ticket envoyée
```

Si vous voyez :
```
[INFO] Pas de token FCM pour l'utilisateur
```
→ Le token n'est pas enregistré pour cet utilisateur

Si vous voyez :
```
[INFO] Client sans compte utilisateur - Notification non envoyée
```
→ Le client n'a pas de compte utilisateur associé

### 3. Vérifier les logs Flutter

**Chercher dans les logs :**
- `📱 [NotificationService] Message reçu en arrière-plan:` → Notification reçue ✅
- `✅ [NotificationService] Notification locale affichée` → Notification affichée ✅

## 🐛 Diagnostic si ça ne fonctionne pas

### Problème 1 : Pas de notification reçue

**Vérifier :**
1. ✅ Token FCM existe en BDD
2. ✅ Token est actif (`is_active = 1`)
3. ✅ User ID correspond
4. ✅ ClientProfile a un compte utilisateur (`hasAccount()` retourne `true`)

**Solution :**
- Vérifier que le téléphone du ticket correspond au téléphone du ClientProfile
- Vérifier que le ClientProfile a bien un compte utilisateur

### Problème 2 : Notification reçue mais silencieuse

**Vérifier :**
1. ✅ Canal Android a importance maximale
2. ✅ Son activé dans le canal
3. ✅ Permissions Android accordées
4. ✅ Backend envoie `priority: 'high'`

**Solution :**
- Vérifier les paramètres de notification Android
- Redémarrer l'app
- Réinstaller l'app pour recréer le canal

### Problème 3 : Notification reçue mais pas de son

**Vérifier :**
1. ✅ Le téléphone n'est pas en mode silencieux
2. ✅ Le volume de notification est activé
3. ✅ Le canal Android a `playSound: true`

## 📝 Commandes utiles

### Vérifier le token FCM depuis l'app

Ajoutez temporairement ce bouton dans votre app pour afficher le token :

```dart
ElevatedButton(
  onPressed: () async {
    final token = await NotificationService.getCurrentToken();
    print('🔑 Token FCM: $token');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Token: ${token?.substring(0, 20)}...')),
    );
  },
  child: Text('Afficher Token FCM'),
)
```

### Test manuel depuis Firebase Console

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. Cloud Messaging → **Send test message**
4. Collez votre token FCM
5. Titre : `🎫 Test Notification`
6. Texte : `Ceci est un test`
7. Cliquez sur **Test**

**Résultat attendu :** Notification reçue avec son ✅

## ✅ Checklist finale

- [ ] Token FCM enregistré en BDD
- [ ] Token est actif (`is_active = 1`)
- [ ] ClientProfile a un compte utilisateur
- [ ] Canal Android créé avec importance maximale
- [ ] Permissions Android accordées
- [ ] Backend envoie avec `priority: 'high'`
- [ ] Notification reçue en arrière-plan
- [ ] Notification reçue avec son ✅
- [ ] Notification reçue avec vibration ✅










