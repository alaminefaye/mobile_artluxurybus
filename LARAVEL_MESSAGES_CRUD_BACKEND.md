# 🔧 BACKEND LARAVEL - CRUD Messages pour Application Mobile

## 📋 ROUTES À AJOUTER

### Fichier : `routes/api.php`

Ajoutez ces routes dans le groupe `auth:sanctum` :

```php
Route::middleware('auth:sanctum')->group(function () {
    
    // ===== MESSAGES =====
    // Récupérer tous les messages (avec pagination et filtres)
    Route::get('messages', [MessageController::class, 'index']);
    
    // Récupérer les messages actifs (pour mobile)
    Route::get('messages/active', [MessageController::class, 'active']);
    
    // Récupérer un message spécifique
    Route::get('messages/{id}', [MessageController::class, 'show']);
    
    // Créer un nouveau message
    Route::post('messages', [MessageController::class, 'store']);
    
    // Mettre à jour un message
    Route::put('messages/{id}', [MessageController::class, 'update']);
    
    // Supprimer un message
    Route::delete('messages/{id}', [MessageController::class, 'destroy']);
});
```

---

## 📝 MÉTHODES À AJOUTER/MODIFIER DANS MessageController

### Fichier : `app/Http/Controllers/Api/MessageController.php`

Si le contrôleur n'existe pas, créez-le :

```bash
php artisan make:controller Api/MessageController
```

### Méthodes complètes :

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use Illuminate\Http\Request;
use App\Events\MessageCreated; // Pour les notifications push

class MessageController extends Controller
{
    /**
     * Récupérer tous les messages avec pagination et filtres
     * GET /api/messages?page=1&per_page=15&type=notification&active=true&gare_id=1&appareil=mobile
     */
    public function index(Request $request)
    {
        $query = Message::query();

        // Filtres
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('active')) {
            $query->where('active', $request->boolean('active'));
        }

        if ($request->has('gare_id')) {
            $query->where('gare_id', $request->gare_id);
        }

        if ($request->has('appareil')) {
            $appareil = $request->appareil;
            if ($appareil === 'tous') {
                // Pas de filtre
            } else {
                $query->where(function($q) use ($appareil) {
                    $q->where('appareil', $appareil)
                      ->orWhere('appareil', 'tous');
                });
            }
        }

        // Pagination
        $perPage = $request->get('per_page', 15);
        $messages = $query->with('gare')
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return response()->json([
            'data' => $messages->items(),
            'meta' => [
                'current_page' => $messages->currentPage(),
                'last_page' => $messages->lastPage(),
                'per_page' => $messages->perPage(),
                'total' => $messages->total(),
            ],
        ]);
    }

    /**
     * Récupérer les messages actifs pour l'application mobile
     * GET /api/messages/active?appareil=mobile&current=true&gare_id=1&uuid=xxx
     */
    public function active(Request $request)
    {
        $query = Message::where('active', true);

        // Filtrer par appareil
        if ($request->has('appareil')) {
            $appareil = $request->appareil;
            $query->where(function($q) use ($appareil) {
                $q->where('appareil', $appareil)
                  ->orWhere('appareil', 'tous');
            });
        }

        // Filtrer par UUID (si fourni)
        if ($request->has('uuid') && $request->uuid) {
            $uuid = $request->uuid;
            $query->where(function($q) use ($uuid) {
                $q->where('uuid', $uuid)
                  ->orWhereNull('uuid');
            });
        }

        // Filtrer par gare
        if ($request->has('gare_id')) {
            $query->where(function($q) use ($request) {
                $q->where('gare_id', $request->gare_id)
                  ->orWhereNull('gare_id');
            });
        }

        // Filtrer les messages actifs et non expirés
        if ($request->boolean('current', true)) {
            $now = now();
            $query->where(function($q) use ($now) {
                $q->whereNull('date_debut')
                  ->orWhere('date_debut', '<=', $now);
            })
            ->where(function($q) use ($now) {
                $q->whereNull('date_fin')
                  ->orWhere('date_fin', '>=', $now);
            });
        }

        $messages = $query->with('gare')
            ->orderBy('created_at', 'desc')
            ->get();

        // Ajouter le flag is_expired
        $messages = $messages->map(function($message) {
            $message->is_expired = $this->isExpired($message);
            return $message;
        });

        return response()->json($messages);
    }

    /**
     * Récupérer un message spécifique
     * GET /api/messages/{id}
     */
    public function show($id)
    {
        $message = Message::with('gare')->findOrFail($id);
        $message->is_expired = $this->isExpired($message);
        
        return response()->json([
            'data' => $message,
        ]);
    }

    /**
     * Créer un nouveau message
     * POST /api/messages
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'titre' => 'required|string|max:255',
            'contenu' => 'required|string',
            'type' => 'required|string|in:notification,annonce',
            'image' => 'nullable|string|url',
            'gare_id' => 'nullable|integer|exists:gares,id',
            'appareil' => 'nullable|string|in:mobile,ecran_tv,ecran_led,tous',
            'uuid' => 'nullable|string|max:255',
            'date_debut' => 'nullable|date',
            'date_fin' => 'nullable|date|after_or_equal:date_debut',
            'active' => 'nullable|boolean',
        ]);

        $message = Message::create([
            'titre' => $validated['titre'],
            'contenu' => $validated['contenu'],
            'type' => $validated['type'],
            'image' => $validated['image'] ?? null,
            'gare_id' => $validated['gare_id'] ?? null,
            'appareil' => $validated['appareil'] ?? 'mobile',
            'uuid' => $validated['uuid'] ?? null,
            'date_debut' => isset($validated['date_debut']) ? $validated['date_debut'] : null,
            'date_fin' => isset($validated['date_fin']) ? $validated['date_fin'] : null,
            'active' => $validated['active'] ?? true,
        ]);

        // Charger la relation gare
        $message->load('gare');
        $message->is_expired = $this->isExpired($message);

        // 🔥 DÉCLENCHER L'ÉVÉNEMENT pour les notifications push
        event(new MessageCreated($message));

        return response()->json([
            'success' => true,
            'message' => 'Message créé avec succès',
            'data' => $message,
        ], 201);
    }

    /**
     * Mettre à jour un message
     * PUT /api/messages/{id}
     */
    public function update(Request $request, $id)
    {
        $message = Message::findOrFail($id);

        $validated = $request->validate([
            'titre' => 'sometimes|required|string|max:255',
            'contenu' => 'sometimes|required|string',
            'type' => 'sometimes|required|string|in:notification,annonce',
            'image' => 'nullable|string|url',
            'gare_id' => 'nullable|integer|exists:gares,id',
            'appareil' => 'nullable|string|in:mobile,ecran_tv,ecran_led,tous',
            'uuid' => 'nullable|string|max:255',
            'date_debut' => 'nullable|date',
            'date_fin' => 'nullable|date|after_or_equal:date_debut',
            'active' => 'nullable|boolean',
        ]);

        $message->update($validated);

        // Charger la relation gare
        $message->load('gare');
        $message->is_expired = $this->isExpired($message);

        return response()->json([
            'success' => true,
            'message' => 'Message mis à jour avec succès',
            'data' => $message,
        ]);
    }

    /**
     * Supprimer un message
     * DELETE /api/messages/{id}
     */
    public function destroy($id)
    {
        $message = Message::findOrFail($id);
        $message->delete();

        return response()->json([
            'success' => true,
            'message' => 'Message supprimé avec succès',
        ], 200);
    }

    /**
     * Vérifier si un message est expiré
     */
    private function isExpired($message)
    {
        if (!$message->active) {
            return true;
        }

        $now = now();

        if ($message->date_debut && $now->lt($message->date_debut)) {
            return false; // Pas encore commencé
        }

        if ($message->date_fin && $now->gt($message->date_fin)) {
            return true; // Expiré
        }

        return false;
    }
}
```

---

## 🔐 VÉRIFICATION DES PERMISSIONS (Optionnel mais recommandé)

Si vous voulez restreindre l'accès aux rôles Super Admin, Admin et Accueil, ajoutez un middleware ou vérifiez dans le contrôleur :

```php
public function store(Request $request)
{
    // Vérifier les permissions
    $user = auth()->user();
    $userRole = strtolower($user->role ?? '');
    
    $allowedRoles = ['super admin', 'super_admin', 'admin', 'administrateur', 'accueil'];
    $hasPermission = false;
    
    foreach ($allowedRoles as $role) {
        if (str_contains($userRole, $role)) {
            $hasPermission = true;
            break;
        }
    }
    
    if (!$hasPermission) {
        return response()->json([
            'success' => false,
            'message' => 'Vous n\'avez pas les permissions nécessaires',
        ], 403);
    }

    // ... reste du code ...
}
```

---

## ✅ VÉRIFICATION

### Tester avec Postman ou cURL :

**1. Créer un message :**
```bash
POST /api/messages
Authorization: Bearer {token}
Content-Type: application/json

{
  "titre": "Test Message",
  "contenu": "Contenu du message",
  "type": "notification",
  "appareil": "mobile",
  "active": true
}
```

**2. Mettre à jour un message :**
```bash
PUT /api/messages/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "titre": "Message modifié",
  "active": false
}
```

**3. Supprimer un message :**
```bash
DELETE /api/messages/{id}
Authorization: Bearer {token}
```

---

## 📝 NOTES IMPORTANTES

1. **Événement MessageCreated** : Assurez-vous que l'événement `MessageCreated` existe et est enregistré dans `EventServiceProvider` pour déclencher les notifications push.

2. **Relations** : Le modèle `Message` doit avoir une relation `gare()` définie dans le modèle.

3. **Validation** : Les validations peuvent être ajustées selon vos besoins spécifiques.

4. **Permissions** : La vérification des permissions est optionnelle mais recommandée pour la sécurité.

