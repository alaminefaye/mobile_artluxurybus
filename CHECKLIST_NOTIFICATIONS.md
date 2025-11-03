# ✅ Checklist Complète pour Recevoir les Notifications

## 🎯 Problème: "Je ne reçois pas de notifications"

Voici **TOUT** ce qu'il faut vérifier pour que les notifications fonctionnent.

---

## 1️⃣ Backend Laravel (Serveur)

### ✅ Firebase configuré
```bash
# Sur le serveur, vérifier le fichier .env
cat /path/to/gestion-compagny/.env | grep FIREBASE
```

**Doit contenir:**
```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CREDENTIALS=/path/to/serviceAccountKey.json
```

**Vérifier que le fichier existe:**
```bash
ls -la /path/to/serviceAccountKey.json
```

### ✅ Code déployé
```bash
cd /path/to/gestion-compagny
git pull
php artisan config:clear
php artisan cache:clear
php artisan optimize
```

### ✅ Tester l'envoi de notification
Créer un ticket manuellement et vérifier les logs:
```bash
tail -f /path/to/gestion-compagny/storage/logs/laravel.log | grep "Notification"
```

**Logs attendus:**
```
[2024-11-03 00:30:00] local.INFO: Notification nouveau ticket envoyée {"user_id":123,"ticket_id":456,...}
[2024-11-03 00:30:01] local.INFO: Notification point de fidélité envoyée {"user_id":123,...}
```

---

## 2️⃣ Base de Données

### ✅ Vérifier que le client a un compte utilisateur

**Requête SQL:**
```sql
-- Vérifier ClientProfile
SELECT * FROM client_profiles WHERE telephone = '0705316506';

-- Vérifier User lié
SELECT * FROM users WHERE phone = '0705316506' OR email = 'email@example.com';

-- Vérifier tokens FCM
SELECT * FROM fcm_tokens WHERE user_id = 123 AND is_active = 1;
```

**Résultat attendu:**
- ✅ ClientProfile existe
- ✅ User existe avec même téléphone ou email
- ✅ Au moins 1 token FCM actif

---

## 3️⃣ Application Flutter

### ✅ Navigation configurée (FAIT ✅)
Le code a été ajouté dans `main.dart`:
- ✅ Navigation vers "Mes Trajets" pour notifications de tickets
- ✅ Navigation vers "Fidélité" pour notifications de points

### ✅ Vérifier les index des onglets HomePage

**IMPORTANT:** Vérifier que les index correspondent:
```dart
// Dans HomePage
const HomePage(initialTabIndex: 2)  // Index 2 = Mes Trajets ?
const HomePage(initialTabIndex: 3)  // Index 3 = Fidélité ?
```

**Si les index sont différents, modifier dans main.dart:**
```dart
// Ligne 180: Pour tickets
const HomePage(initialTabIndex: X) // Mettre le bon index de "Mes Trajets"

// Ligne 194: Pour points
const HomePage(initialTabIndex: Y) // Mettre le bon index de "Fidélité"
```

### ✅ Token FCM enregistré

**Vérifier dans les logs Flutter:**
```
flutter run
```

**Logs attendus au démarrage:**
```
🔔 [NotificationService] Début initialisation...
✅ [NotificationService] Firebase initialisé
📱 [NotificationService] Device ID: AP3A.240905.015.A2
✅ [NotificationService] Firebase Messaging initialisé
✅ [NotificationService] Notifications locales initialisées
🎫 FCM Token: eABCDEF...XYZ
✅ Token FCM enregistré avec succès sur le serveur
```

**Si vous ne voyez PAS "Token FCM enregistré":**
- ❌ Le token n'est pas envoyé au serveur
- ❌ Les notifications ne peuvent PAS être reçues

---

## 4️⃣ Tests Complets

### Test 1: Vérifier que le token est bien enregistré

**Étape 1:** Lancer l'app Flutter
```bash
flutter run
```

**Étape 2:** Copier le token FCM dans les logs
```
🎫 FCM Token: eABCDEF1234567890XYZ...
```

**Étape 3:** Vérifier en BDD
```sql
SELECT * FROM fcm_tokens WHERE token LIKE 'eABCDEF%';
```

**Résultat attendu:**
```
| id | user_id | token           | is_active | device_type | device_id          |
|----|---------|-----------------|-----------|-------------|---------------------|
| 42 | 123     | eABCDEF...XYZ   | 1         | android     | AP3A.240905.015.A2 |
```

### Test 2: Créer un ticket et vérifier

**Étape 1:** Créer un ticket via l'app mobile OU au guichet

**Étape 2:** Vérifier les logs backend
```bash
tail -f storage/logs/laravel.log | grep "Notification"
```

**Logs attendus:**
```
INFO: Notification nouveau ticket envoyée {"user_id":123,"ticket_id":789,"result":true}
INFO: Notification point de fidélité envoyée {"user_id":123,"client_profile_id":456,"points_earned":1}
```

**Étape 3:** Vérifier en BDD
```sql
SELECT * FROM notifications WHERE user_id = 123 ORDER BY created_at DESC LIMIT 2;
```

**Résultat attendu:**
```
| id  | user_id | type          | title                         | message                    | read_at |
|-----|---------|---------------|-------------------------------|----------------------------|---------|
| 101 | 123     | loyalty_point | 🎁 Point de fidélité gagné ! | Félicitations ! Vous...    | NULL    |
| 100 | 123     | new_ticket    | 🎫 Nouveau ticket créé !     | Votre ticket pour Dakar... | NULL    |
```

### Test 3: Notification reçue sur le téléphone

**Vérifier:**
- ✅ Notification apparaît dans le tiroir Android
- ✅ Titre: "🎫 Nouveau ticket créé !"
- ✅ Message contient le trajet
- ✅ Cliquer ouvre l'app sur "Mes Trajets"

---

## 5️⃣ Problèmes Courants

### ❌ "Notification non envoyée: Client sans compte utilisateur"

**Cause:** Le client n'a pas de compte User lié à son ClientProfile

**Solution:**
```sql
-- Créer un compte utilisateur pour le client
INSERT INTO users (name, email, phone, password, created_at, updated_at)
VALUES ('Faye Mohamed', 'faye@example.com', '0705316506', '$2y$10$...', NOW(), NOW());

-- OU mettre à jour le ClientProfile avec l'email du User
UPDATE client_profiles SET email = 'faye@example.com' WHERE telephone = '0705316506';
```

### ❌ "Pas de token FCM pour l'utilisateur"

**Cause:** Le token FCM n'est pas enregistré pour cet utilisateur

**Solution:**
1. **Côté Flutter:** S'assurer que le token est bien envoyé
   ```dart
   // Vérifier dans NotificationService.initialize()
   await _getAndRegisterToken();
   ```

2. **Côté Backend:** Vérifier l'endpoint `/api/fcm/register-token`
   ```php
   // Routes: api.php
   Route::post('/fcm/register-token', [FcmTokenController::class, 'registerToken']);
   ```

3. **Tester manuellement:**
   ```bash
   curl -X POST https://skf-artluxurybus.com/api/fcm/register-token \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "fcm_token": "eABCDEF...XYZ",
       "device_type": "android",
       "device_id": "AP3A.240905.015.A2"
     }'
   ```

### ❌ "Firebase not configured"

**Cause:** `.env` ne contient pas la config Firebase

**Solution:**
```bash
# Ajouter dans .env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CREDENTIALS=/var/www/gestion-compagny/storage/firebase/serviceAccountKey.json

# Puis
php artisan config:clear
php artisan cache:clear
```

### ❌ Notification reçue mais ne navigue pas

**Cause:** Les index des onglets HomePage sont incorrects

**Solution:**
```dart
// Dans main.dart, modifier les index:
// Ligne 180 et 194

// Trouver le bon index en comptant les onglets de HomePage:
// 0 = Home
// 1 = Notifications
// 2 = Mes Trajets
// 3 = Profil/Fidélité
```

---

## 6️⃣ Debug Avancé

### Activer les logs détaillés

**Backend (Laravel):**
```php
// Dans NotificationService.php
Log::debug('Token FCM: ' . $token);
Log::debug('Notification payload: ' . json_encode($notification));
Log::debug('FCM Response: ' . $response->body());
```

**Flutter:**
```dart
// Dans NotificationService
debugPrint('🔔 Notification reçue: ${message.notification?.title}');
debugPrint('📦 Data: ${message.data}');
```

### Tester avec notification de test

**Depuis Firebase Console:**
1. Aller sur https://console.firebase.google.com
2. Sélectionner votre projet
3. Cloud Messaging → Send test message
4. Coller votre FCM token
5. Envoyer

**Si ça marche:**
✅ Firebase config OK  
✅ Token FCM valide  
❌ Problème côté backend Laravel

**Si ça ne marche pas:**
❌ Problème Firebase ou token invalide

---

## ✅ Checklist Finale

### Backend:
- [ ] `.env` contient `FIREBASE_PROJECT_ID` et `FIREBASE_CREDENTIALS`
- [ ] Fichier `serviceAccountKey.json` existe
- [ ] Code déployé (`git pull` + `php artisan optimize`)
- [ ] Logs montrent "Notification...envoyée"

### Base de données:
- [ ] `client_profiles` existe avec téléphone
- [ ] `users` existe avec même téléphone ou email
- [ ] `fcm_tokens` contient un token actif pour ce user
- [ ] `notifications` table existe

### Flutter:
- [ ] Navigation ajoutée dans `main.dart` ✅
- [ ] Index des onglets corrects (2 = Trajets, 3 = Fidélité)
- [ ] Token FCM enregistré (logs "Token FCM enregistré avec succès")
- [ ] Firebase initialisé sans erreur

### Tests:
- [ ] Créer un ticket → Notification reçue
- [ ] Cliquer notification → Navigation vers bonne page
- [ ] 2 notifications reçues (ticket + point)

---

## 🎯 Test Rapide Complet

```bash
# 1. Backend déployé
cd gestion-compagny && git pull && php artisan optimize

# 2. App Flutter redémarrée
flutter clean && flutter run

# 3. Créer un ticket pour un client avec compte

# 4. Vérifier réception notification

# 5. Cliquer notification

# 6. Vérifier navigation vers "Mes Trajets"
```

**Si tout est ✅ → Notifications fonctionnent !** 🎉

**Si ❌ → Suivre cette checklist point par point**
