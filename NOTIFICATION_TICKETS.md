# 🔔 Notifications Push pour Nouveaux Tickets - Documentation

## ✅ Fonctionnalités implémentées

### Backend Laravel (gestion-compagny)

#### 1. **Service de Notification** ✅
**Fichier:** `app/Services/NotificationService.php`

Nouvelle méthode créée: `sendNewTicketNotification($ticket)`

**Logique:**
1. Recherche le `ClientProfile` via le numéro de téléphone du ticket
2. Vérifie si le client a un compte utilisateur (`User`)
3. Récupère les tokens FCM actifs de l'utilisateur
4. Envoie une notification push avec les données du ticket
5. Sauvegarde la notification en base de données

**Données envoyées dans la notification:**
```php
'data' => [
    'type' => 'new_ticket',
    'ticket_id' => (string)$ticket->id,
    'action' => 'view_trips',  // Action pour navigation
    'depart_id' => (string)$ticket->depart_id,
    'seat_number' => (string)$ticket->siege_number,
]
```

#### 2. **API Mobile - ReservationController** ✅
**Fichier:** `app/Http/Controllers/Api/ReservationController.php`  
**Ligne:** ~491-498

Notification envoyée automatiquement après création de ticket (mode test mobile).

#### 3. **Guichet - TicketController** ✅
**Fichier:** `app/Http/Controllers/Admin/TicketController.php`  
**Ligne:** ~508-515

Notification envoyée automatiquement quand un agent crée un ticket au guichet.

---

## 📱 Application Mobile (Flutter)

### Structure de notification

Quand un ticket est créé, le client reçoit:

**Titre:** 🎫 Nouveau ticket créé !

**Message:** 
```
Votre ticket pour [Embarquement] → [Destination] a été créé avec succès.
Siège: [Numéro]
```

**Bouton d'action:** "Voir ticket"

### Gestion de la notification

Le `NotificationService` Flutter est déjà configuré pour:
1. ✅ Recevoir les notifications push (FCM)
2. ✅ Afficher les notifications locales
3. ✅ Gérer les clics sur les notifications

---

## 🔧 Configuration requise

### 1. Backend - Firebase

Vérifier que Firebase est bien configuré dans `.env`:
```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CREDENTIALS=/path/to/serviceAccountKey.json
```

### 2. Base de données - Table notifications

Assurez-vous que la table `notifications` existe:
```sql
CREATE TABLE notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSON,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### 3. Relation User ↔ ClientProfile

Pour que les notifications fonctionnent, le client doit:
1. ✅ Avoir un profil `ClientProfile` avec son numéro de téléphone
2. ✅ Avoir créé un compte utilisateur (`User`)
3. ✅ Le compte doit être lié via `email` ou `phone`
4. ✅ L'application mobile doit avoir un token FCM enregistré

---

## 🎯 Scénarios d'utilisation

### Scénario 1: Ticket créé via app mobile
```
1. Client sélectionne siège(s) dans l'app
2. Client valide ses informations
3. Ticket créé → Notification envoyée AUTOMATIQUEMENT
4. Client reçoit: "🎫 Nouveau ticket créé !"
5. Client clique → Ouverture écran "Mes trajets"
```

### Scénario 2: Ticket créé au guichet
```
1. Agent crée ticket au guichet (backoffice Laravel)
2. Ticket créé → Notification envoyée AUTOMATIQUEMENT
3. Client (s'il a l'app) reçoit: "🎫 Nouveau ticket créé !"
4. Client clique → Ouverture écran "Mes trajets"
```

### Scénario 3: Client sans compte
```
1. Ticket créé pour un numéro de téléphone
2. Système cherche si ClientProfile existe
3. Système cherche si User existe
4. Si aucun User → Notification NON envoyée (normal)
5. Log: "Client sans compte utilisateur - Notification non envoyée"
```

---

## 🧪 Tests

### Test 1: Créer ticket via API mobile
```bash
# Scénario avec client qui a un compte
POST https://skf-artluxurybus.com/api/reservations/{reservation_id}/confirm
```

**Résultat attendu:**
- ✅ Ticket créé
- ✅ Notification push envoyée
- ✅ Notification sauvegardée en BDD
- ✅ Log: "Notification nouveau ticket envoyée"

### Test 2: Créer ticket au guichet
```
1. Se connecter au backoffice Laravel
2. Aller dans "Vente de tickets"
3. Créer un ticket pour un client qui a un compte
```

**Résultat attendu:**
- ✅ Ticket créé
- ✅ Client reçoit notification sur son téléphone
- ✅ Message: "🎫 Nouveau ticket créé !"

### Test 3: Vérifier les logs
```bash
# Sur le serveur Laravel
tail -f storage/logs/laravel.log | grep "Notification nouveau ticket"
```

---

## 📊 Logs et Debugging

### Logs Backend (Laravel)
```php
// Si notification envoyée avec succès
Log::info("Notification nouveau ticket envoyée", [
    'user_id' => $user->id,
    'ticket_id' => $ticket->id,
    'result' => true
]);

// Si client sans profil
Log::info("Client sans profil créé - Notification non envoyée", [
    'telephone' => $ticket->telephone,
    'ticket_id' => $ticket->id
]);

// Si client sans compte utilisateur
Log::info("Client sans compte utilisateur - Notification non envoyée", [
    'client_id' => $clientProfile->id,
    'ticket_id' => $ticket->id
]);

// Si pas de token FCM
Log::info("Pas de token FCM pour l'utilisateur", [
    'user_id' => $user->id,
    'ticket_id' => $ticket->id
]);
```

### Logs Flutter
```dart
// Dans la console Android Studio / VS Code
📱 [NotificationService] Message reçu en premier plan:
   - Titre: 🎫 Nouveau ticket créé !
   - Corps: Votre ticket pour Dakar → Thiès...
   - Type: new_ticket
```

---

## 🔐 Sécurité

### Vérifications implémentées:
1. ✅ Notification envoyée UNIQUEMENT au client propriétaire du ticket
2. ✅ Vérification que le téléphone correspond au ClientProfile
3. ✅ Vérification que le ClientProfile est lié à un User
4. ✅ Vérification des tokens FCM actifs uniquement
5. ✅ Gestion des erreurs sans bloquer la création du ticket

### Gestion des erreurs:
```php
try {
    $notificationService = app(\App\Services\NotificationService::class);
    $notificationService->sendNewTicketNotification($ticket);
} catch (\Exception $e) {
    // Ne pas bloquer la création du ticket si la notification échoue
    \Log::warning("Notification ticket non envoyée: " . $e->getMessage());
}
```

---

## 🚀 Déploiement

### 1. Backend
```bash
cd /path/to/gestion-compagny

# Vérifier les changements
git status

# Déployer sur le serveur
git add .
git commit -m "✨ Ajout notifications push pour nouveaux tickets"
git push origin main

# Sur le serveur
php artisan config:clear
php artisan cache:clear
php artisan optimize
```

### 2. Application mobile
```bash
cd /path/to/artluxurybus

# Rebuild l'application
flutter clean
flutter pub get
flutter build apk --release

# Ou tester en debug
flutter run
```

---

## ✅ Checklist de vérification

- [ ] Firebase configuré dans `.env`
- [ ] Table `notifications` existe en BDD
- [ ] Table `fcm_tokens` existe en BDD
- [ ] Les clients ont des comptes utilisateurs
- [ ] Les comptes sont liés aux ClientProfiles
- [ ] L'app mobile enregistre les tokens FCM
- [ ] Backend déployé sur le serveur
- [ ] Tests effectués (mobile + guichet)
- [ ] Notifications reçues sur le téléphone
- [ ] Clic sur notification ouvre "Mes trajets"

---

## 💡 Améliorations futures

1. **Bouton "Voir ticket" direct** - Navigation vers le détail du ticket spécifique
2. **Notification par SMS** - Envoyer aussi un SMS (pour clients sans app)
3. **Email de confirmation** - Email avec PDF du ticket
4. **Historique des notifications** - Écran dédié dans l'app
5. **Badge de notification** - Compteur de tickets non vus

---

## 📞 Support

En cas de problème:
1. Vérifier les logs Laravel: `storage/logs/laravel.log`
2. Vérifier les logs Flutter dans la console
3. Vérifier que Firebase est bien configuré
4. Vérifier que les tokens FCM sont enregistrés en BDD
