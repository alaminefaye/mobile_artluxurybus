# 🔔 Guide d'Implémentation : Notifications Push pour Messages (Laravel)

## ⚠️ PROBLÈME IDENTIFIÉ

Les notifications de type "notification" ne sont **PAS envoyées automatiquement** à tous les utilisateurs car la logique d'envoi n'est **pas implémentée côté serveur Laravel**.

L'application Flutter est **correctement configurée** pour recevoir les notifications, mais le serveur Laravel ne les envoie pas automatiquement lors de la création d'un message.

---

## 📋 Ce qui doit être implémenté côté Laravel

### 1. **Événement `MessageCreated`**

Créer le fichier : `app/Events/MessageCreated.php`

```php
<?php

namespace App\Events;

use App\Models\Message;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageCreated
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    /**
     * Create a new event instance.
     */
    public function __construct(Message $message)
    {
        $this->message = $message;
    }
}
```

---

### 2. **Listener `SendMessageNotification`**

Créer le fichier : `app/Listeners/SendMessageNotification.php`

```php
<?php

namespace App\Listeners;

use App\Events\MessageCreated;
use App\Services\NotificationService;
use Illuminate\Support\Facades\Log;

class SendMessageNotification
{
    protected $notificationService;

    /**
     * Create the event listener.
     */
    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Handle the event.
     */
    public function handle(MessageCreated $event): void
    {
        $message = $event->message;

        // Envoyer notification uniquement si c'est une notification et qu'elle est active
        if ($message->type === 'notification' && $message->active) {
            Log::info('📤 Envoi de notification push pour le message', [
                'message_id' => $message->id,
                'titre' => $message->titre,
                'type' => $message->type,
            ]);

            try {
                $result = $this->notificationService->sendMessageNotificationToAll($message);
                
                Log::info('✅ Résultat de l\'envoi de notification', [
                    'success' => $result,
                    'message_id' => $message->id,
                ]);
            } catch (\Exception $e) {
                Log::error('❌ Erreur lors de l\'envoi de notification', [
                    'message_id' => $message->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }
    }
}
```

---

### 3. **Méthode dans `NotificationService`**

Ajouter cette méthode dans : `app/Services/NotificationService.php`

```php
/**
 * Envoyer une notification de message à tous les utilisateurs mobiles
 */
public function sendMessageNotificationToAll($message)
{
    try {
        // Récupérer tous les tokens FCM des utilisateurs mobiles actifs
        $fcmTokens = \App\Models\FcmToken::where('device_type', 'mobile')
            ->where('active', true)
            ->pluck('token')
            ->toArray();

        if (empty($fcmTokens)) {
            Log::warning('⚠️ Aucun token FCM mobile trouvé pour l\'envoi de notification');
            return false;
        }

        Log::info('📱 Envoi de notification à ' . count($fcmTokens) . ' appareils mobiles');

        // Préparer le payload de notification
        $notification = [
            'title' => $message->titre,
            'body' => $message->contenu,
        ];

        $data = [
            'type' => 'message',
            'message_id' => (string) $message->id,
            'message_type' => $message->type,
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ];

        // Envoyer la notification à tous les tokens
        $successCount = 0;
        $failureCount = 0;

        // Envoyer par lots de 500 tokens (limite Firebase)
        $tokenChunks = array_chunk($fcmTokens, 500);

        foreach ($tokenChunks as $chunk) {
            try {
                $result = $this->sendToMultipleDevices($chunk, $notification, $data);
                
                if ($result) {
                    $successCount += count($chunk);
                } else {
                    $failureCount += count($chunk);
                }
            } catch (\Exception $e) {
                Log::error('❌ Erreur lors de l\'envoi à un lot de tokens', [
                    'error' => $e->getMessage(),
                    'chunk_size' => count($chunk),
                ]);
                $failureCount += count($chunk);
            }
        }

        Log::info('📊 Résultat de l\'envoi de notifications', [
            'total' => count($fcmTokens),
            'success' => $successCount,
            'failure' => $failureCount,
        ]);

        return $successCount > 0;

    } catch (\Exception $e) {
        Log::error('❌ Erreur dans sendMessageNotificationToAll', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
        ]);
        return false;
    }
}

/**
 * Envoyer une notification à plusieurs appareils
 */
private function sendToMultipleDevices(array $tokens, array $notification, array $data)
{
    try {
        $messaging = app('firebase.messaging');

        $message = [
            'notification' => $notification,
            'data' => $data,
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'sound' => 'default',
                    'channel_id' => 'art_luxury_bus_channel',
                ],
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'badge' => 1,
                    ],
                ],
            ],
        ];

        // Envoyer à tous les tokens
        $response = $messaging->sendMulticast($message, $tokens);

        Log::info('✅ Notification multicast envoyée', [
            'success_count' => $response->successes()->count(),
            'failure_count' => $response->failures()->count(),
        ]);

        return $response->successes()->count() > 0;

    } catch (\Exception $e) {
        Log::error('❌ Erreur sendToMultipleDevices', [
            'error' => $e->getMessage(),
        ]);
        return false;
    }
}
```

---

### 4. **Enregistrer l'événement et le listener**

Dans le fichier : `app/Providers/EventServiceProvider.php`

```php
<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;
use App\Events\MessageCreated;
use App\Listeners\SendMessageNotification;

class EventServiceProvider extends ServiceProvider
{
    /**
     * The event listener mappings for the application.
     *
     * @var array<class-string, array<int, class-string>>
     */
    protected $listen = [
        // ... autres événements existants

        MessageCreated::class => [
            SendMessageNotification::class,
        ],
    ];

    /**
     * Register any events for your application.
     */
    public function boot(): void
    {
        //
    }
}
```

---

### 5. **Déclencher l'événement lors de la création d'un message**

Dans le contrôleur qui crée les messages (probablement `app/Http/Controllers/Api/MessageController.php`), ajouter :

```php
use App\Events\MessageCreated;

public function store(Request $request)
{
    // Validation...
    
    $message = Message::create([
        'titre' => $request->titre,
        'contenu' => $request->contenu,
        'type' => $request->type,
        'gare_id' => $request->gare_id,
        'appareil' => $request->appareil,
        'date_debut' => $request->date_debut,
        'date_fin' => $request->date_fin,
        'active' => $request->active ?? true,
    ]);

    // 🔥 DÉCLENCHER L'ÉVÉNEMENT
    event(new MessageCreated($message));

    return response()->json([
        'success' => true,
        'message' => 'Message créé avec succès',
        'data' => $message,
    ], 201);
}
```

---

## 🔧 Vérification de la configuration Firebase

Assurez-vous que le fichier de credentials Firebase est bien configuré dans `config/services.php` :

```php
'firebase' => [
    'credentials' => storage_path('app/artluxurybus-d7a63-firebase-adminsdk-fbsvc-2adea67816.json'),
    'database_url' => env('FIREBASE_DATABASE_URL'),
],
```

---

## 📊 Vérifier que la table `fcm_tokens` existe

La table doit avoir cette structure :

```sql
CREATE TABLE `fcm_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `token` text NOT NULL,
  `device_type` varchar(50) DEFAULT 'android',
  `device_id` varchar(255) DEFAULT NULL,
  `active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fcm_tokens_user_id_foreign` (`user_id`),
  CONSTRAINT `fcm_tokens_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);
```

---

## 🧪 Tester l'implémentation

### 1. Créer un message de test via l'API

```bash
curl -X POST https://artluxurybus.ci/api/messages \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "titre": "Test Notification",
    "contenu": "Ceci est un test de notification pour tous les utilisateurs",
    "type": "notification",
    "appareil": "mobile",
    "active": true
  }'
```

### 2. Vérifier les logs Laravel

```bash
tail -f storage/logs/laravel.log
```

Vous devriez voir :
```
[2025-10-23 12:00:00] 📤 Envoi de notification push pour le message
[2025-10-23 12:00:00] 📱 Envoi de notification à X appareils mobiles
[2025-10-23 12:00:00] ✅ Notification multicast envoyée
[2025-10-23 12:00:00] 📊 Résultat de l'envoi de notifications
```

### 3. Vérifier sur l'app mobile

L'app devrait recevoir la notification automatiquement (même en arrière-plan).

---

## 🎯 Résumé des étapes

1. ✅ Créer l'événement `MessageCreated`
2. ✅ Créer le listener `SendMessageNotification`
3. ✅ Ajouter la méthode `sendMessageNotificationToAll` dans `NotificationService`
4. ✅ Enregistrer l'événement dans `EventServiceProvider`
5. ✅ Déclencher l'événement dans le contrôleur de création de messages
6. ✅ Tester la création d'un message
7. ✅ Vérifier que les notifications sont reçues sur mobile

---

## 🔍 Debugging

Si les notifications ne sont toujours pas reçues :

### Vérifier les tokens FCM en base de données

```sql
SELECT COUNT(*) as total_tokens, device_type 
FROM fcm_tokens 
WHERE active = 1 
GROUP BY device_type;
```

### Vérifier les logs Firebase

Dans la console Firebase : **Cloud Messaging > Rapports**

### Tester manuellement depuis Firebase Console

1. Aller dans **Cloud Messaging > Send test message**
2. Coller un token FCM depuis la base de données
3. Envoyer un message de test
4. Si ça fonctionne, le problème est dans le code Laravel
5. Si ça ne fonctionne pas, le problème est dans la configuration Firebase/App

---

## ✅ Résultat attendu

Une fois implémenté :

- ✅ Chaque fois qu'un message de type "notification" est créé, une notification push est envoyée à **tous les utilisateurs mobiles**
- ✅ Les notifications apparaissent même si l'app est fermée
- ✅ Les utilisateurs peuvent cliquer sur la notification pour ouvrir l'app
- ✅ Les logs Laravel montrent le nombre de notifications envoyées avec succès

---

## 📞 Support

Si vous avez besoin d'aide pour implémenter ces changements côté Laravel, vérifiez :

1. Que le package `kreait/firebase-php` est installé
2. Que le fichier de credentials Firebase existe et est accessible
3. Que la table `fcm_tokens` contient des tokens actifs
4. Les logs Laravel pour voir les erreurs éventuelles

Bonne implémentation ! 🚀
