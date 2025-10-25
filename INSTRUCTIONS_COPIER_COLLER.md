# 🚀 INSTRUCTIONS RAPIDES - COPIER-COLLER

## Étape 1 : Ouvrir BusApiController.php

Fichier : `app/Http/Controllers/Api/BusApiController.php`

## Étape 2 : Remplacer les méthodes de pannes

### Cherchez `public function storeBreakdown` et remplacez TOUTE la méthode par :

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
    $validated['created_by'] = auth()->id();
    
    $breakdown = BusBreakdown::create($validated);

    return response()->json($breakdown, 201);
}
```

### Cherchez `public function updateBreakdown` et remplacez TOUTE la méthode par :

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

## Étape 3 : Ouvrir BusBreakdown.php

Fichier : `app/Models/BusBreakdown.php`

### Remplacez le `$fillable` par :

```php
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
```

## Étape 4 : Sauvegarder et tester

1. Sauvegarder les fichiers PHP
2. Relancer l'app Flutter
3. Bus → Pannes → [+]
4. Remplir et ajouter
5. ✅ Ça devrait fonctionner !

## ⚡ RACCOURCI

Les fichiers complets sont dans :
- `METHODES_PANNES_CORRIGEES.php` - Méthodes du contrôleur
- `MODELE_BUSBREAKDOWN_CORRIGE.php` - Modèle complet

Copiez-collez directement ! 🚀
