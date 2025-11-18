# 📢 Documentation : Envoi de Messages pour les Annonces

## 🎯 Vue d'ensemble

Le système d'envoi de messages pour les annonces fonctionne en deux parties :
1. **Backend Laravel** : Création et envoi des messages/annonces avec notifications push
2. **Application Flutter** : Réception et affichage des annonces vocales avec overlay visuel

---

## 🔄 Flux complet du système

### 1. **Création du Message/Annonce (Backend Laravel)**

#### A. Interface Admin
- **Fichier** : `app/Http/Controllers/Admin/MessageController.php`
- **Méthode** : `store()` (lignes 73-146)

**Processus :**
1. L'administrateur crée un message via l'interface admin (`/admin/messages/create`)
2. Le formulaire contient :
   - **Titre** : Titre du message/annonce
   - **Contenu** : Texte du message
   - **Type** : `notification` ou `annonce`
   - **Gare** : Gare associée (optionnel)
   - **Appareil** : Cible (`mobile`, `tous`, ou un `device_id` spécifique)
   - **Date début/fin** : Période de validité
   - **Active** : Statut actif/inactif
   - **Image** : Image pour les notifications (optionnel)

3. Validation et normalisation :
   ```php
   // Normalise le type (announcement → annonce)
   $type = $request->input('type');
   if ($type === 'announcement') {
       $type = 'annonce';
   }
   ```

4. Création du message en base de données :
   ```php
   $message = Message::create($messageData);
   ```

5. **Déclenchement de l'événement** :
   ```php
   event(new \App\Events\MessageCreated($message));
   ```

---

### 2. **Envoi des Notifications Push (Backend Laravel)**

#### A. Événement `MessageCreated`
- **Fichier** : `app/Events/MessageCreated.php`

L'événement est créé avec le message et stocke son ID :
```php
public function __construct(Message $message)
{
    $this->message = $message;
    $this->messageId = $message->id;
}
```

#### B. Listener `SendMessageNotification`
- **Fichier** : `app/Listeners/SendMessageNotification.php`
- **Queue** : `default` (traitement en arrière-plan)
- **Tentatives** : 3
- **Timeout** : 120 secondes

**Processus :**
1. Le listener est déclenché automatiquement quand un `MessageCreated` est émis
2. Vérifie que le message est éligible :
   ```php
   if (in_array($message->type, ['notification', 'annonce']) && $message->active) {
       // Envoyer notification
   }
   ```
3. Appelle `NotificationService::sendMessageNotification($message)`

#### C. Service de Notification
- **Fichier** : `app/Services/NotificationService.php`
- **Méthode** : `sendMessageNotification()` (lignes 580-822)

**Processus détaillé :**

1. **Vérifications initiales** :
   - Message actif ? ✅
   - Type éligible (`notification` ou `annonce`) ? ✅

2. **Construction du payload** :
   ```php
   $title = '📢 ' . $message->titre;
   $body = Str::limit($message->contenu, 150);
   
   $data = [
       'type' => 'message_notification',
       'message_id' => (string) $message->id,
       'msg_type' => $message->type,
       'titre' => $message->titre,
       'appareil' => $message->appareil ?? 'tous',
   ];
   ```

3. **Récupération des utilisateurs cibles** :
   ```php
   $usersWithTokens = FcmToken::where('is_active', true)
       ->with('user')
       ->get()
       ->pluck('user')
       ->unique('id')
       ->filter();
   ```

4. **Collecte des tokens FCM** :
   - Récupère tous les tokens FCM actifs de tous les utilisateurs
   - Combine tous les tokens dans un tableau

5. **Envoi des notifications push** :
   ```php
   $this->sendPushNotification($allFcmTokens, $title, $body, $data);
   ```

6. **Sauvegarde en base de données** :
   - Crée une entrée dans la table `notifications` pour chaque utilisateur
   - Permet l'historique des notifications

7. **Envoi par lots (queue)** :
   - Les notifications sont envoyées via la queue Laravel pour éviter les timeouts
   - Traitement asynchrone pour les grandes échelles

---

### 3. **Réception dans l'Application Flutter**

#### A. Réception de la Notification Push
- **Fichier** : `lib/services/notification_service.dart`
- **Service** : Firebase Cloud Messaging (FCM)

Quand une notification push arrive :
1. Firebase Messaging reçoit la notification
2. Le service de notification Flutter la traite
3. Si type = `message_notification`, le message est sauvegardé localement

#### B. Récupération des Messages Actifs (Polling)
- **Fichier** : `lib/services/message_api_service.dart`
- **Méthode** : `getActiveMessages()`

**Processus :**
1. L'application fait une requête GET vers `/api/messages/active`
2. Paramètres :
   - `appareil` : `mobile` (pour tous les mobiles) OU `device_id` spécifique
   - `current` : `true` (uniquement les messages actifs et non expirés)

3. L'API retourne les messages actifs pour cet appareil

4. L'application filtre :
   - Messages actifs (`active = true`)
   - Non expirés (`date_fin >= maintenant`)
   - Pour cet appareil (`appareil = 'mobile'` OU `appareil = device_id`)

#### C. Gestion des Annonces Vocales
- **Fichier** : `lib/services/announcement_manager.dart`

**Processus :**

1. **Démarrage du gestionnaire** (au démarrage de l'app) :
   ```dart
   await AnnouncementManager().start();
   ```

2. **Vérification périodique** :
   - Toutes les **120 secondes** (2 minutes)
   - Appelle `getActiveMessages()` via `MessageApiService`
   - Filtre les messages de type `annonce`

3. **Filtrage par appareil** :
   ```dart
   bool _isForThisDevice(MessageModel message) {
       // Si appareil = "tous" → toutes les annonces
       // Si appareil = "mobile" → ignoré pour les annonces (doit être device_id spécifique)
       // Si appareil = device_id spécifique → match avec device_id local
   }
   ```

4. **Démarrage des nouvelles annonces** :
   - Pour chaque nouvelle annonce détectée :
     ```dart
     _voiceService.startAnnouncement(message, _context);
     ```

5. **Arrêt des annonces expirées** :
   - Vérifie si les annonces en cours sont toujours actives
   - Arrête celles qui ne le sont plus

#### D. Service d'Annonces Vocales
- **Fichier** : `lib/services/voice_announcement_service.dart`
- **Méthode** : `startAnnouncement()`

**Processus :**

1. **Initialisation** :
   - Vérifie que les annonces vocales sont activées
   - Vérifie que le message est une annonce active

2. **Affichage visuel** (overlay) :
   - Si un `BuildContext` est fourni, affiche un overlay avec :
     - Titre de l'annonce
     - Contenu
     - Bouton pour fermer/snooze

3. **Lecture vocale** :
   - Utilise `flutter_tts` pour lire le texte de l'annonce
   - Boucle de lecture : Lire → Pause 5 secondes → Re-lire
   - Continue jusqu'à ce que l'annonce expire ou soit arrêtée

4. **Gestion audio** :
   - Met en pause les vidéos en cours (via `AudioFocusManager`)
   - Gère le focus audio pour éviter les conflits

---

## 🔑 Points clés à retenir

### 1. **Types de Messages**

- **`notification`** :
  - Notification push unique
  - Affichée dans la liste des notifications
  - Peut contenir une image
  - Apparaît une fois, puis archivée

- **`annonce`** :
  - Notification push + annonce vocale répétée
  - Lue en boucle jusqu'à expiration
  - Affiche un overlay visuel pendant la lecture
  - Vérifiée toutes les 2 minutes

### 2. **Ciblage par Appareil**

- **`appareil = "tous"`** :
  - Message envoyé à tous les appareils (mobile + totems)
  - Pour les annonces, tous les appareils la recevront

- **`appareil = "mobile"`** :
  - Pour les **notifications** : tous les appareils mobiles
  - Pour les **annonces** : IGNORÉ (les annonces doivent cibler un device_id spécifique)

- **`appareil = "DAKAR-TOTEM-01"`** (device_id spécifique) :
  - Message envoyé uniquement à cet appareil
  - Pour les annonces, seuls les appareils correspondants les recevront

### 3. **Filtrage dans Flutter**

L'application Flutter fait deux types de requêtes :

1. **Messages génériques** :
   ```
   GET /api/messages/active?appareil=mobile&current=true
   ```
   - Récupère les messages pour tous les mobiles

2. **Messages spécifiques** :
   ```
   GET /api/messages/active?appareil={device_id}&current=true
   ```
   - Récupère les messages pour cet appareil spécifique
   - Le `device_id` est généré au démarrage et stocké localement

### 4. **Queue et Performance**

- Les notifications push sont envoyées via **queue Laravel** pour éviter les timeouts
- Traitement asynchrone : `SendMessageNotification` implémente `ShouldQueue`
- Envoi par lots pour gérer des milliers d'utilisateurs

### 5. **Polling et Rate Limiting**

- Le `AnnouncementManager` vérifie les annonces toutes les **2 minutes** (120s)
- Throttling intégré : minimum 60s entre chaque appel API
- Backoff exponentiel en cas de rate limiting (429)

---

## 📊 Diagramme de flux

```
┌─────────────────┐
│  Admin crée     │
│  Message/Annonce│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Message::create │
└────────┬────────┘
         │
         ▼
┌──────────────────────┐
│ MessageCreated Event │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ SendMessageNotification│
│   (Queue Listener)   │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ NotificationService  │
│ sendMessageNotification│
└────────┬─────────────┘
         │
         ├──────────────────────────┐
         │                          │
         ▼                          ▼
┌──────────────────┐      ┌──────────────────┐
│ Collecte tokens  │      │ Envoi Push FCM   │
│ FCM utilisateurs │      │ via Firebase     │
└────────┬─────────┘      └────────┬─────────┘
         │                         │
         └──────────────┬──────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │ App Flutter reçoit  │
              │ Notification Push   │
              └──────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │ AnnouncementManager │
              │ vérifie toutes les  │
              │ 2 minutes via API   │
              └──────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │ Pour annonces:      │
              │ - Filtre par device │
              │ - Démarre lecture   │
              │   vocale + overlay  │
              └─────────────────────┘
```

---

## 🛠️ Fichiers principaux

### Backend Laravel
- `app/Http/Controllers/Admin/MessageController.php` - CRUD des messages
- `app/Events/MessageCreated.php` - Événement de création
- `app/Listeners/SendMessageNotification.php` - Listener pour notifications
- `app/Services/NotificationService.php` - Service d'envoi de notifications
- `app/Models/Message.php` - Modèle Message

### Application Flutter
- `lib/services/message_api_service.dart` - API de récupération des messages
- `lib/services/announcement_manager.dart` - Gestionnaire d'annonces
- `lib/services/voice_announcement_service.dart` - Service d'annonces vocales
- `lib/services/notification_service.dart` - Réception des notifications push
- `lib/models/message_model.dart` - Modèle Message Flutter

---

## ✅ Résumé

Le système fonctionne ainsi :

1. **Backend** : L'admin crée un message/annonce → Événement → Queue → NotificationService → Push FCM
2. **Flutter** : Reçoit la notification push → Polling périodique via API → Filtrage par device → Lecture vocale + overlay pour les annonces

Les **annonces** sont spéciales car elles :
- Sont lues en boucle jusqu'à expiration
- Affichent un overlay visuel
- Doivent cibler un `device_id` spécifique (pas juste "mobile")
- Sont vérifiées toutes les 2 minutes par l'app

Les **notifications** sont plus simples :
- Affichage unique
- Peuvent cibler "mobile" ou un device spécifique
- Sauvegardées dans l'historique des notifications


