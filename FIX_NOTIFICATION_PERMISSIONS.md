# Correction des Permissions de Gestion des Notifications

## Problème identifié

Les utilisateurs normaux (clients, employés) ne peuvent pas gérer leurs propres notifications (marquer comme lu, supprimer) car le backend Laravel vérifie probablement des permissions admin au lieu de vérifier que l'utilisateur gère SES PROPRES notifications.

## Solution Backend (Laravel)

### 1. Vérifier le contrôleur des notifications

**Fichier** : `app/Http/Controllers/Api/NotificationController.php`

#### ❌ Mauvaise implémentation (actuelle)

```php
public function markAsRead($id)
{
    // Vérifie si l'utilisateur est admin
    if (!auth()->user()->hasRole('admin')) {
        return response()->json([
            'success' => false,
            'message' => 'Non autorisé'
        ], 403);
    }
    
    $notification = Notification::findOrFail($id);
    $notification->update(['is_read' => true]);
    
    return response()->json(['success' => true]);
}
```

#### ✅ Bonne implémentation (à appliquer)

```php
public function markAsRead($id)
{
    $user = auth()->user();
    
    // Trouver la notification
    $notification = Notification::findOrFail($id);
    
    // Vérifier que la notification appartient à l'utilisateur connecté
    if ($notification->user_id !== $user->id) {
        return response()->json([
            'success' => false,
            'message' => 'Cette notification ne vous appartient pas'
        ], 403);
    }
    
    // Marquer comme lue
    $notification->update([
        'is_read' => true,
        'read_at' => now()
    ]);
    
    return response()->json([
        'success' => true,
        'message' => 'Notification marquée comme lue'
    ]);
}

public function destroy($id)
{
    $user = auth()->user();
    
    // Trouver la notification
    $notification = Notification::findOrFail($id);
    
    // Vérifier que la notification appartient à l'utilisateur connecté
    if ($notification->user_id !== $user->id) {
        return response()->json([
            'success' => false,
            'message' => 'Cette notification ne vous appartient pas'
        ], 403);
    }
    
    // Supprimer
    $notification->delete();
    
    return response()->json([
        'success' => true,
        'message' => 'Notification supprimée'
    ]);
}

public function markAllAsRead()
{
    $user = auth()->user();
    
    // Marquer toutes les notifications de l'utilisateur comme lues
    Notification::where('user_id', $user->id)
        ->where('is_read', false)
        ->update([
            'is_read' => true,
            'read_at' => now()
        ]);
    
    return response()->json([
        'success' => true,
        'message' => 'Toutes les notifications ont été marquées comme lues'
    ]);
}
```

### 2. Vérifier les routes API

**Fichier** : `routes/api.php`

```php
Route::middleware(['auth:sanctum'])->group(function () {
    // Routes de notifications - TOUS les utilisateurs authentifiés
    Route::prefix('notifications')->group(function () {
        // Récupérer les notifications de l'utilisateur
        Route::get('/', [NotificationController::class, 'index']);
        Route::get('/all', [NotificationController::class, 'index']);
        Route::get('/unread-count', [NotificationController::class, 'unreadCount']);
        
        // Gérer SES PROPRES notifications (pas besoin de permission admin)
        Route::post('/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::post('/mark-all-read', [NotificationController::class, 'markAllAsRead']);
        Route::delete('/{id}', [NotificationController::class, 'destroy']);
    });
});
```

**Important** : Ne PAS mettre de middleware `can:` ou `role:admin` sur ces routes !

### 3. Vérifier la méthode index()

```php
public function index(Request $request)
{
    $user = auth()->user();
    
    // Récupérer UNIQUEMENT les notifications de l'utilisateur connecté
    $query = Notification::where('user_id', $user->id)
        ->orderBy('created_at', 'desc');
    
    // Filtrer par non lues si demandé
    if ($request->has('unread_only') && $request->unread_only == '1') {
        $query->where('is_read', false);
    }
    
    // Pagination
    $page = $request->get('page', 1);
    $limit = $request->get('limit', 20);
    
    $notifications = $query->skip(($page - 1) * $limit)
        ->take($limit)
        ->get();
    
    $unreadCount = Notification::where('user_id', $user->id)
        ->where('is_read', false)
        ->count();
    
    return response()->json([
        'success' => true,
        'notifications' => $notifications,
        'unread_count' => $unreadCount,
        'current_page' => $page,
        'per_page' => $limit
    ]);
}
```

## Principe de sécurité

### ✅ Règle d'or

**Chaque utilisateur peut UNIQUEMENT gérer SES PROPRES notifications**

```php
// Toujours vérifier
if ($notification->user_id !== auth()->id()) {
    return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
}
```

### ❌ Ne PAS faire

```php
// Ne PAS vérifier le rôle admin pour gérer ses propres notifications
if (!auth()->user()->hasRole('admin')) {
    return response()->json(['success' => false], 403);
}
```

### ✅ À faire

```php
// Vérifier que la notification appartient à l'utilisateur
if ($notification->user_id !== auth()->id()) {
    return response()->json(['success' => false], 403);
}
```

## Test de la correction

### 1. Tester avec Postman/Insomnia

#### Marquer comme lu
```http
POST https://gestion-compagny.universaltechnologiesafrica.com/api/notifications/123/read
Authorization: Bearer {token_utilisateur_normal}
```

**Réponse attendue** :
```json
{
    "success": true,
    "message": "Notification marquée comme lue"
}
```

#### Supprimer
```http
DELETE https://gestion-compagny.universaltechnologiesafrica.com/api/notifications/123
Authorization: Bearer {token_utilisateur_normal}
```

**Réponse attendue** :
```json
{
    "success": true,
    "message": "Notification supprimée"
}
```

### 2. Tester dans l'app mobile

1. Se connecter avec un utilisateur **normal** (pas admin)
2. Recevoir une notification
3. Essayer de :
   - ✅ Cliquer sur la notification (doit marquer comme lu)
   - ✅ Swiper pour supprimer (doit supprimer)
   - ✅ Voir le badge de compteur diminuer

## Logs de débogage

Ajouter des logs dans le contrôleur pour déboguer :

```php
public function markAsRead($id)
{
    $user = auth()->user();
    $notification = Notification::findOrFail($id);
    
    \Log::info('Tentative de marquer notification comme lue', [
        'user_id' => $user->id,
        'notification_id' => $id,
        'notification_user_id' => $notification->user_id,
        'match' => $notification->user_id === $user->id
    ]);
    
    if ($notification->user_id !== $user->id) {
        \Log::warning('Tentative non autorisée', [
            'user_id' => $user->id,
            'notification_user_id' => $notification->user_id
        ]);
        
        return response()->json([
            'success' => false,
            'message' => 'Cette notification ne vous appartient pas'
        ], 403);
    }
    
    $notification->update([
        'is_read' => true,
        'read_at' => now()
    ]);
    
    \Log::info('Notification marquée comme lue avec succès');
    
    return response()->json([
        'success' => true,
        'message' => 'Notification marquée comme lue'
    ]);
}
```

Vérifier les logs : `storage/logs/laravel.log`

## Structure de la table notifications

Vérifier que la table a bien la colonne `user_id` :

```php
Schema::create('notifications', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade'); // IMPORTANT
    $table->string('type');
    $table->string('title');
    $table->text('message');
    $table->json('data')->nullable();
    $table->boolean('is_read')->default(false);
    $table->timestamp('read_at')->nullable();
    $table->timestamps();
});
```

## Résumé des changements backend

| Fichier | Changement | Raison |
|---------|-----------|--------|
| `NotificationController.php` | Vérifier `user_id` au lieu du rôle | Chaque utilisateur gère SES notifications |
| `routes/api.php` | Retirer middleware `role:admin` | Tous les utilisateurs authentifiés peuvent gérer leurs notifications |
| Logs | Ajouter logs de débogage | Identifier les problèmes de permissions |

## Côté mobile (déjà correct)

✅ Le code mobile est correct :
- `markAsRead()` est appelé au clic
- `deleteNotification()` est appelé au swipe
- Les erreurs sont gérées silencieusement
- L'UI se met à jour localement

## Conclusion

Le problème est **100% côté backend**. Il faut modifier le contrôleur Laravel pour :
1. ✅ Vérifier que `notification->user_id === auth()->id()`
2. ✅ Ne PAS vérifier le rôle admin
3. ✅ Permettre à TOUS les utilisateurs de gérer LEURS notifications

Après cette correction, tous les utilisateurs pourront gérer leurs notifications normalement.
