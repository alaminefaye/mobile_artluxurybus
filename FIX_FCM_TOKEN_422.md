# 🔧 FIX: Erreur 422 lors de l'envoi du Token FCM

## 🔴 Problème Identifié

### Logs d'Erreur
```
[AUTH ERROR] ❌ Erreur envoi token: 422
[AUTH]    Détails: Erreur de validation
```

### Analyse
**Erreur 422** = Erreur de validation Laravel. Le serveur rejette les données envoyées car elles ne correspondent pas aux règles de validation.

---

## ✅ Corrections Appliquées

### 1. Changement du Nom du Champ
**Avant :**
```dart
body: jsonEncode({
  'token': token,  // ❌ Mauvais nom
  'device_type': 'mobile',
  'device_id': deviceId,
})
```

**Après :**
```dart
body: jsonEncode({
  'fcm_token': token,  // ✅ Bon nom (correspond à Laravel)
  'device_type': Platform.isAndroid ? 'android' : 'ios',
  'device_id': deviceId,
})
```

### 2. Ajout de Logs Détaillés
Ajout de logs pour voir exactement ce qui est envoyé et reçu :
- 📤 Données envoyées (URL, device_type, device_id, token)
- 📥 Réponse serveur (status code)
- ❌ Détails des erreurs de validation (champs manquants/invalides)

### 3. Gestion Spécifique de l'Erreur 422
Affichage détaillé des erreurs de validation Laravel :
```dart
if (response.statusCode == 422) {
  // Afficher chaque champ en erreur
  if (errorData['errors'] != null) {
    (errorData['errors'] as Map).forEach((key, value) {
      print('- $key: ${value.join(', ')}');
    });
  }
}
```

---

## 🧪 Test des Modifications

### Étape 1 : Hot Restart
```bash
# Dans le terminal où l'app tourne
R  # (R majuscule pour restart complet)
```

### Étape 2 : Vérifier les Nouveaux Logs
Après le restart, vous devriez voir dans les logs :

**✅ Si ça fonctionne :**
```
[AUTH] 📤 Envoi token au serveur:
[AUTH]    URL: .../fcm/register-token
[AUTH]    Device Type: android
[AUTH]    Device ID: xxxxx
[AUTH]    Token (début): crMfkZ7QQJq30jkFliot...
[AUTH] 📥 Réponse serveur: 200
[AUTH] ✅ Token FCM envoyé au serveur avec succès
```

**❌ Si erreur 422 persiste :**
```
[AUTH] 📤 Envoi token au serveur:
[AUTH]    ...
[AUTH] 📥 Réponse serveur: 422
[AUTH] ❌ Erreur de validation (422)
[AUTH]    Message: The given data was invalid
[AUTH]    Erreurs de validation:
[AUTH]       - fcm_token: The fcm token field is required
[AUTH]       - device_type: The device type must be android or ios
```

---

## 🔍 Diagnostic Selon les Logs

### Scénario A : Erreur "fcm_token is required"
**Cause :** Le token FCM est vide ou null

**Solution :**
```dart
// Vérifier que le token est bien obtenu
final token = await _firebaseMessaging.getToken();
if (token == null || token.isEmpty) {
  print('❌ Token FCM vide !');
  return;
}
```

### Scénario B : Erreur "device_type invalid"
**Cause :** Le device_type n'est pas 'android' ou 'ios'

**Solution :** Déjà corrigé avec `Platform.isAndroid ? 'android' : 'ios'`

### Scénario C : Erreur "device_id required"
**Cause :** Le device_id est vide

**Solution :**
```dart
// Vérifier _getDeviceId()
final deviceId = await _getDeviceId();
print('Device ID: $deviceId');
```

### Scénario D : Erreur "user_id required"
**Cause :** Le serveur Laravel attend un user_id

**Solution :** Ajouter le user_id dans le body :
```dart
body: jsonEncode({
  'fcm_token': token,
  'device_type': Platform.isAndroid ? 'android' : 'ios',
  'device_id': deviceId,
  'user_id': userId, // Ajouter si nécessaire
})
```

---

## 📋 Vérifications Côté Laravel

### Vérifier les Règles de Validation
Fichier : `app/Http/Controllers/Api/FcmTokenController.php`

Les règles de validation doivent accepter :
```php
$request->validate([
    'fcm_token' => 'required|string',
    'device_type' => 'required|in:android,ios',
    'device_id' => 'required|string',
]);
```

### Vérifier la Route
Fichier : `routes/api.php`

La route doit exister :
```php
Route::post('/fcm/register-token', [FcmTokenController::class, 'registerToken'])
    ->middleware('auth:sanctum');
```

---

## 🎯 Résultat Attendu

Après ces modifications, vous devriez avoir :

### Logs de Succès
```
[AUTH] 🔔 Initialisation FCM pour: Administrateur
[AUTH] ✅ Tous les tokens FCM nettoyés
[AUTH] 📤 Envoi token au serveur:
[AUTH]    URL: .../fcm/register-token
[AUTH]    Device Type: android
[AUTH]    Device ID: xxxxx
[AUTH]    Token (début): crMfkZ7QQJq30jkFliot...
[AUTH] 📥 Réponse serveur: 200
[AUTH] ✅ Token FCM envoyé au serveur avec succès
[AUTH] ✅ FCM Token initialisé pour utilisateur: 1
[AUTH] Token: crMfkZ7QQJq30jkFliot...
[AUTH] ✅ FCM initialisé avec succès
```

### Fonctionnalités Opérationnelles
- ✅ Token FCM enregistré sur le serveur
- ✅ Push notifications reçues depuis Laravel
- ✅ Notifications affichées dans l'app
- ✅ Badge de compteur fonctionnel

---

## 🆘 Si l'Erreur 422 Persiste

### Option 1 : Vérifier le Format du Token
```dart
print('Token length: ${token.length}');
print('Token format: ${token.substring(0, 50)}...');
```

Le token FCM doit faire environ 150-180 caractères.

### Option 2 : Tester avec Postman
Testez l'API directement :

**Request :**
```
POST https://gestion-compagny.universaltechnologiesafrica.com/api/fcm/register-token
Headers:
  Content-Type: application/json
  Authorization: Bearer YOUR_TOKEN
Body:
{
  "fcm_token": "crMfkZ7QQJq30jkFliot...",
  "device_type": "android",
  "device_id": "test_device_123"
}
```

**Expected Response :**
```json
{
  "success": true,
  "message": "Token FCM enregistré avec succès"
}
```

### Option 3 : Vérifier les Logs Laravel
Sur le serveur Laravel :
```bash
tail -f storage/logs/laravel.log
```

Cherchez les erreurs de validation pour voir exactement quel champ pose problème.

---

## 📞 Résumé des Changements

| Fichier | Ligne | Changement |
|---------|-------|------------|
| `fcm_service.dart` | 1 | Ajout `import 'dart:io';` |
| `fcm_service.dart` | 72 | `'token'` → `'fcm_token'` |
| `fcm_service.dart` | 73 | `'mobile'` → `Platform.isAndroid ? 'android' : 'ios'` |
| `fcm_service.dart` | 78-82 | Ajout logs détaillés envoi |
| `fcm_service.dart` | 111-127 | Gestion spécifique erreur 422 |

---

**Relancez l'app avec `R` (restart) et vérifiez les nouveaux logs !** 🚀
