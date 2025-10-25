# ❌ ERREUR 422 - Backend Laravel à corriger

## Problème

L'application Flutter envoie les **bons champs** mais le backend Laravel attend encore les **anciens champs** !

### Erreur reçue
```
Erreur 422: {
  "errors": {
    "description": ["The description field is required."],
    "breakdown_date": ["The breakdown date field is required."],
    "severity": ["The severity field is required."],
    "status": ["The status field is required."]
  }
}
```

### Ce que Flutter envoie (✅ CORRECT)
```dart
{
  'reparation_effectuee': '...',
  'date_panne': '2025-01-25',
  'description_probleme': '...',
  'diagnostic_mecanicien': '...',
  'statut_reparation': 'en_cours',
  'kilometrage': 12000,
  'piece_remplacee': '...',
  'prix_piece': 50000,
  'notes_complementaires': '...'
}
```

### Ce que Laravel attend (❌ ANCIEN)
```php
$request->validate([
    'description' => 'required',      // ❌ N'existe plus
    'breakdown_date' => 'required',   // ❌ Devrait être date_panne
    'severity' => 'required',         // ❌ N'existe plus
    'status' => 'required',           // ❌ N'existe plus
]);
```

## Solution : Corriger le contrôleur Laravel

### Fichier à modifier
`app/Http/Controllers/Api/BusApiController.php`

### Méthode `storeBreakdown()` - AVANT (❌)
```php
public function storeBreakdown(Request $request, $busId)
{
    $validated = $request->validate([
        'description' => 'required|string',
        'breakdown_date' => 'required|date',
        'severity' => 'required|in:low,medium,high',
        'status' => 'required|in:reported,in_progress,resolved',
        'repair_cost' => 'nullable|numeric',
        'notes' => 'nullable|string',
    ]);

    $validated['bus_id'] = $busId;
    $breakdown = BusBreakdown::create($validated);

    return response()->json($breakdown, 201);
}
```

### Méthode `storeBreakdown()` - APRÈS (✅)
```php
public function storeBreakdown(Request $request, $busId)
{
    $validated = $request->validate([
        'reparation_effectuee' => 'required|string',
        'date_panne' => 'required|date',
        'description_probleme' => 'required|string',
        'diagnostic_mecanicien' => 'required|string',
        'statut_reparation' => 'required|in:en_cours,terminee,en_attente_pieces',
        'kilometrage' => 'nullable|integer',
        'piece_remplacee' => 'nullable|string',
        'prix_piece' => 'nullable|numeric',
        'facture_photo' => 'nullable|string',
        'notes_complementaires' => 'nullable|string',
    ]);

    $validated['bus_id'] = $busId;
    $validated['created_by'] = auth()->id(); // ID de l'utilisateur connecté
    
    $breakdown = BusBreakdown::create($validated);

    return response()->json($breakdown, 201);
}
```

### Méthode `updateBreakdown()` - AVANT (❌)
```php
public function updateBreakdown(Request $request, $busId, $breakdownId)
{
    $breakdown = BusBreakdown::where('bus_id', $busId)
        ->findOrFail($breakdownId);

    $validated = $request->validate([
        'description' => 'sometimes|required|string',
        'breakdown_date' => 'sometimes|required|date',
        'severity' => 'sometimes|required|in:low,medium,high',
        'status' => 'sometimes|required|in:reported,in_progress,resolved',
        'repair_cost' => 'nullable|numeric',
        'notes' => 'nullable|string',
    ]);

    $breakdown->update($validated);

    return response()->json($breakdown);
}
```

### Méthode `updateBreakdown()` - APRÈS (✅)
```php
public function updateBreakdown(Request $request, $busId, $breakdownId)
{
    $breakdown = BusBreakdown::where('bus_id', $busId)
        ->findOrFail($breakdownId);

    $validated = $request->validate([
        'reparation_effectuee' => 'sometimes|required|string',
        'date_panne' => 'sometimes|required|date',
        'description_probleme' => 'sometimes|required|string',
        'diagnostic_mecanicien' => 'sometimes|required|string',
        'statut_reparation' => 'sometimes|required|in:en_cours,terminee,en_attente_pieces',
        'kilometrage' => 'nullable|integer',
        'piece_remplacee' => 'nullable|string',
        'prix_piece' => 'nullable|numeric',
        'facture_photo' => 'nullable|string',
        'notes_complementaires' => 'nullable|string',
    ]);

    $breakdown->update($validated);

    return response()->json($breakdown);
}
```

## Champs de la migration

Pour référence, voici les champs de la table `bus_breakdowns` :

```php
$table->id();
$table->foreignId('bus_id')->constrained('buses')->onDelete('cascade');
$table->integer('kilometrage')->nullable();
$table->text('reparation_effectuee');          // NON NULL
$table->date('date_panne');                     // NON NULL
$table->text('description_probleme');           // NON NULL
$table->text('diagnostic_mecanicien');          // NON NULL
$table->string('piece_remplacee')->nullable();
$table->decimal('prix_piece', 10, 2)->nullable();
$table->string('facture_photo')->nullable();
$table->text('notes_complementaires')->nullable();
$table->enum('statut_reparation', ['en_cours', 'terminee', 'en_attente_pieces'])->default('en_cours');
$table->foreignId('created_by')->constrained('users')->onDelete('cascade');
$table->timestamps();
```

## Modèle Laravel

Vérifier aussi que le modèle `BusBreakdown` a les bons `$fillable` :

```php
// app/Models/BusBreakdown.php
class BusBreakdown extends Model
{
    protected $fillable = [
        'bus_id',
        'kilometrage',
        'reparation_effectuee',
        'date_panne',
        'description_probleme',
        'diagnostic_mecanicien',
        'piece_remplacee',
        'prix_piece',
        'facture_photo',
        'notes_complementaires',
        'statut_reparation',
        'created_by',
    ];

    protected $casts = [
        'date_panne' => 'date',
        'prix_piece' => 'decimal:2',
    ];

    public function bus()
    {
        return $this->belongsTo(Bus::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
```

## Test après correction

Une fois le backend corrigé :

1. Relancer le serveur Laravel
2. Dans l'app Flutter : Bus → Pannes → [+]
3. Remplir le formulaire
4. Cliquer "Ajouter"
5. ✅ La panne devrait être créée sans erreur

## Résumé

- ✅ **Flutter** : Envoie les bons champs
- ❌ **Laravel** : Attend les anciens champs
- 🔧 **Solution** : Mettre à jour la validation dans `BusApiController.php`

Après cette correction, l'ajout et la modification de pannes fonctionneront parfaitement ! 🚀
