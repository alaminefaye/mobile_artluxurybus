# 🔥 Configuration Laravel pour Notifications Push - Art Luxury Bus

## 🎯 **Problème identifié**

✅ **Firebase côté app Flutter** : Fonctionne parfaitement  
❌ **Laravel côté serveur** : Infrastructure manquante pour notifications push

## 🚀 **Configuration Laravel à faire**

### **1. Installer les dépendances Composer**

```bash
cd /path/to/your/laravel/project
composer require kreait/firebase-php
composer require guzzlehttp/guzzle
```

### **2. Configuration Firebase dans Laravel**

#### A. **Télécharger le fichier de service Firebase**

1. **Firebase Console** → Paramètres du projet → Comptes de service
2. **Générer une nouvelle clé privée** → Télécharger le fichier JSON
3. **Placer** le fichier dans `storage/app/firebase/service-account.json`

#### B. **Configuration .env**

```env
FIREBASE_CREDENTIALS=storage/app/firebase/service-account.json
FIREBASE_PROJECT_ID=artluxurybus-d7a63
```

### **3. Créer le Service Firebase**

**Créer** `app/Services/FirebaseService.php` :

```php
<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class FirebaseService
{
    private $messaging;

    public function __construct()
    {
        $factory = (new Factory)
            ->withServiceAccount(storage_path('app/firebase/service-account.json'))
            ->withProjectId(env('FIREBASE_PROJECT_ID'));
        
        $this->messaging = $factory->createMessaging();
    }

    public function sendNotification($token, $title, $body, $data = [])
    {
        try {
            $notification = Notification::create($title, $body);
            
            $message = CloudMessage::withTarget('token', $token)
                ->withNotification($notification)
                ->withData($data);

            $result = $this->messaging->send($message);
            
            return ['success' => true, 'result' => $result];
        } catch (\Exception $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function sendToMultipleTokens($tokens, $title, $body, $data = [])
    {
        try {
            $notification = Notification::create($title, $body);
            
            $message = CloudMessage::new()
                ->withNotification($notification)
                ->withData($data);

            $result = $this->messaging->sendMulticast($message, $tokens);
            
            return ['success' => true, 'result' => $result];
        } catch (\Exception $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }
}
```

### **4. Créer le modèle FCM Token**

```bash
php artisan make:model FcmToken -m
```

**Migration** `database/migrations/create_fcm_tokens_table.php` :

```php
public function up()
{
    Schema::create('fcm_tokens', function (Blueprint $table) {
        $table->id();
        $table->unsignedBigInteger('user_id');
        $table->text('token');
        $table->string('device_type')->nullable();
        $table->string('device_id')->nullable();
        $table->timestamps();
        
        $table->foreign('user_id')->references('id')->on('users');
        $table->unique(['user_id', 'token']);
    });
}
```

### **5. Créer le Controller**

**Créer** `app/Http/Controllers/NotificationController.php` :

```php
<?php

namespace App\Http\Controllers;

use App\Services\FirebaseService;
use App\Models\FcmToken;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    private $firebaseService;

    public function __construct(FirebaseService $firebaseService)
    {
        $this->firebaseService = $firebaseService;
    }

    public function registerToken(Request $request)
    {
        $request->validate([
            'token' => 'required|string',
            'device_type' => 'nullable|string',
            'device_id' => 'nullable|string'
        ]);

        $user = auth()->user();
        
        FcmToken::updateOrCreate([
            'user_id' => $user->id,
            'token' => $request->token,
        ], [
            'device_type' => $request->device_type,
            'device_id' => $request->device_id,
        ]);

        return response()->json(['success' => true, 'message' => 'Token enregistré']);
    }

    public function sendTestNotification(Request $request)
    {
        $request->validate([
            'title' => 'required|string',
            'message' => 'required|string',
            'user_ids' => 'required|array'
        ]);

        $tokens = FcmToken::whereIn('user_id', $request->user_ids)
                          ->pluck('token')
                          ->toArray();

        if (empty($tokens)) {
            return response()->json(['success' => false, 'message' => 'Aucun token trouvé']);
        }

        $result = $this->firebaseService->sendToMultipleTokens(
            $tokens,
            $request->title,
            $request->message
        );

        return response()->json($result);
    }

    public function testConfig()
    {
        try {
            // Test si Firebase est configuré
            $factory = (new \Kreait\Firebase\Factory)
                ->withServiceAccount(storage_path('app/firebase/service-account.json'));
            
            return response()->json([
                'success' => true, 
                'message' => 'Configuration Firebase valide',
                'project_id' => env('FIREBASE_PROJECT_ID')
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false, 
                'error' => $e->getMessage()
            ]);
        }
    }
}
```

### **6. Routes API**

**Ajouter dans** `routes/api.php` :

```php
Route::middleware('auth:api')->group(function () {
    // Notifications
    Route::post('/fcm/register-token', [NotificationController::class, 'registerToken']);
    Route::get('/notifications/test-config', [NotificationController::class, 'testConfig']);
    Route::post('/notifications/send-test', [NotificationController::class, 'sendTestNotification']);
});
```

### **7. Event Listener pour nouvelles suggestions**

**Créer** un Event :
```bash
php artisan make:event SuggestionCreated
php artisan make:listener SendSuggestionNotification
```

**Dans** `app/Events/SuggestionCreated.php` :
```php
class SuggestionCreated
{
    public $suggestion;

    public function __construct($suggestion)
    {
        $this->suggestion = $suggestion;
    }
}
```

**Dans** `app/Listeners/SendSuggestionNotification.php` :
```php
public function handle(SuggestionCreated $event)
{
    $firebaseService = app(FirebaseService::class);
    
    // Récupérer tous les tokens des admins
    $tokens = FcmToken::whereHas('user', function($query) {
        $query->where('role', 'admin');
    })->pluck('token')->toArray();
    
    if (!empty($tokens)) {
        $firebaseService->sendToMultipleTokens(
            $tokens,
            'Nouvelle suggestion',
            'Une nouvelle suggestion a été créée',
            ['type' => 'new_suggestion', 'suggestion_id' => $event->suggestion->id]
        );
    }
}
```

### **8. Déclencher l'événement**

**Dans votre contrôleur de suggestions** :
```php
use App\Events\SuggestionCreated;

public function store(Request $request)
{
    // Créer la suggestion
    $suggestion = Suggestion::create($request->all());
    
    // Déclencher l'événement
    event(new SuggestionCreated($suggestion));
    
    return response()->json(['success' => true]);
}
```

## 🧪 **Tests**

### **1. Test configuration**
```bash
curl -X GET https://gestion-compagny.universaltechnologiesafrica.com/api/notifications/test-config \
  -H "Authorization: Bearer VOTRE_VRAI_TOKEN"
```

### **2. Test envoi**
```bash
curl -X POST https://gestion-compagny.universaltechnologiesafrica.com/api/notifications/send-test \
  -H "Authorization: Bearer VOTRE_VRAI_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","message":"Test notification","user_ids":[1]}'
```

## ✅ **Résultat attendu**

Une fois cette infrastructure en place :
- ✅ **App Flutter** enregistre automatiquement le token FCM
- ✅ **Laravel** stocke les tokens en base
- ✅ **Nouvelle suggestion** → Notification automatique envoyée
- ✅ **Notification reçue** sur tous les téléphones des admins

**IMPORTANT** : Il faut implémenter cette infrastructure Laravel pour que les notifications automatiques fonctionnent ! 🚀
