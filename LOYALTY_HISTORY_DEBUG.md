# 🔍 Diagnostic: Historique Fidélité Vide

## Problème Identifié
L'application affiche "Aucun historique trouvé pour ce numéro" alors que des tickets/courriers existent dans la base de données.

## Architecture Vérifiée

### ✅ Flutter (Mobile)
- **Service**: `/lib/services/loyalty_service.dart`
  - Endpoint: `POST /loyalty/profile`
  - Envoie: `{ "phone": "..." }`
  - Attend: `{ success, message, client, history }`

- **Provider**: `/lib/providers/loyalty_provider.dart`
  - Méthode: `getClientProfile()`
  - Gère l'état et appelle le service

- **Screen**: `/lib/screens/loyalty_home_screen.dart`
  - Affiche l'historique via `_buildTransactionHistory()`
  - Condition d'erreur: `snapshot.data!.history == null`

- **Models**: `/lib/models/simple_loyalty_models.dart`
  - `LoyaltyProfileResponse` avec `LoyaltyHistory?`
  - `LoyaltyHistory` contient `recentTickets` et `recentMails`

### ✅ Laravel (Backend)
- **Controller**: `/app/Http/Controllers/Api/LoyaltyApiController.php`
  - Méthode: `getClientProfile(Request $request)`
  - Lignes 183-211: Récupération des tickets
  - Lignes 213-235: Récupération des courriers
  - Ligne 257-262: Structure `history` dans la réponse

## Points de Vérification

### 1. Relations Eloquent (Laravel)
Vérifier que le modèle `ClientProfile` a les relations:
```php
// Dans app/Models/ClientProfile.php
public function tickets()
{
    return $this->hasMany(Ticket::class, 'client_profile_id');
}

public function mails()
{
    return $this->hasMany(Mail::class, 'client_profile_id');
}
```

### 2. Clés Étrangères (Base de données)
Vérifier que les tables ont les bonnes colonnes:
```sql
-- Table tickets
SELECT * FROM tickets WHERE client_profile_id = [ID_CLIENT] LIMIT 5;

-- Table mails (ou courriers)
SELECT * FROM mails WHERE client_profile_id = [ID_CLIENT] LIMIT 5;
-- OU
SELECT * FROM courriers WHERE client_profile_id = [ID_CLIENT] LIMIT 5;
```

### 3. Nom de la Table Mails
Le contrôleur utilise `$client->mails()`. Vérifier:
- Soit la table s'appelle `mails`
- Soit le modèle `Mail` définit `protected $table = 'courriers';`

### 4. Structure de la Réponse API
Tester directement l'API:
```bash
curl -X POST https://votre-domaine.com/api/loyalty/profile \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"phone":"77XXXXXXX"}'
```

La réponse doit contenir:
```json
{
  "success": true,
  "message": "Profil client récupéré",
  "client": { ... },
  "history": {
    "recent_tickets": [...],
    "recent_mails": [...],
    "total_tickets_count": X,
    "total_mails_count": Y
  }
}
```

## Logs de Debug Ajoutés

### Côté Flutter
Logs ajoutés dans `/lib/services/loyalty_service.dart`:
- ✅ Structure de la réponse
- ✅ Présence de `history`
- ✅ Nombre de tickets/mails
- ✅ Premier élément de chaque liste

Logs ajoutés dans `/lib/screens/loyalty_home_screen.dart`:
- ✅ État de l'erreur
- ✅ Données reçues
- ✅ Type de carte sélectionné
- ✅ Nombre d'items à afficher

### Comment Voir les Logs
```bash
# Lancer l'app en mode debug
flutter run

# Filtrer les logs loyalty
flutter logs | grep -i loyalty
# OU
flutter logs | grep "🔍\|📊\|🎫\|📧\|🔴\|✅"
```

## Solutions Possibles

### Solution 1: Vérifier les Relations
```php
// Dans app/Models/ClientProfile.php
public function tickets()
{
    return $this->hasMany(Ticket::class, 'client_profile_id');
}

public function mails()
{
    // Si la table s'appelle 'courriers'
    return $this->hasMany(Mail::class, 'client_profile_id');
}
```

### Solution 2: Vérifier le Modèle Mail
```php
// Dans app/Models/Mail.php
class Mail extends Model
{
    protected $table = 'courriers'; // Si la table s'appelle courriers
    // OU
    protected $table = 'mails'; // Si la table s'appelle mails
}
```

### Solution 3: Ajouter des Logs Laravel
```php
// Dans LoyaltyApiController.php, ligne ~183
\Log::info('Fetching tickets for client', [
    'client_id' => $client->id,
    'phone' => $client->telephone
]);

$recentTickets = $client->tickets()
    ->with(['depart.trajet'])
    ->orderBy('created_at', 'desc')
    ->limit(10)
    ->get();

\Log::info('Tickets found', [
    'count' => $recentTickets->count(),
    'tickets' => $recentTickets->toArray()
]);
```

### Solution 4: Vérifier la Colonne client_profile_id
```sql
-- Vérifier si la colonne existe
DESCRIBE tickets;
DESCRIBE mails;
-- OU
DESCRIBE courriers;

-- Vérifier les données
SELECT id, client_profile_id, created_at FROM tickets LIMIT 5;
SELECT id, client_profile_id, created_at FROM mails LIMIT 5;
```

## Prochaines Étapes

1. **Lancer l'app** avec les nouveaux logs
2. **Naviguer** vers l'écran Fidélité
3. **Observer** les logs dans la console
4. **Identifier** où le problème se situe:
   - ❌ `history` est `null` dans la réponse → Problème Laravel
   - ❌ `recent_tickets` est vide → Problème de relation tickets
   - ❌ `recent_mails` est vide → Problème de relation mails
   - ✅ Tout est présent mais ne s'affiche pas → Problème UI Flutter

5. **Partager** les logs pour diagnostic précis

## Commandes Utiles

```bash
# Nettoyer et relancer
flutter clean
flutter pub get
flutter run

# Voir les logs en temps réel
flutter logs

# Tester l'API directement
curl -X POST http://localhost:8000/api/loyalty/profile \
  -H "Content-Type: application/json" \
  -d '{"phone":"77XXXXXXX"}'
```

## Contact
Une fois les logs générés, partagez-les pour un diagnostic précis du problème.
