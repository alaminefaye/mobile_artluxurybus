# 🔧 BACKEND LARAVEL - CRUD COMPLET

## 📋 ROUTES À AJOUTER

### Fichier : `routes/api.php`

Ajoutez ces routes dans le groupe `auth:sanctum` :

```php
Route::middleware('auth:sanctum')->group(function () {
    
    // ===== VISITES TECHNIQUES =====
    Route::post('buses/{bus}/technical-visits', [BusApiController::class, 'storeTechnicalVisit']);
    Route::put('buses/{bus}/technical-visits/{visit}', [BusApiController::class, 'updateTechnicalVisit']);
    Route::delete('buses/{bus}/technical-visits/{visit}', [BusApiController::class, 'destroyTechnicalVisit']);
    
    // ===== ASSURANCES =====
    Route::post('buses/{bus}/insurance-records', [BusApiController::class, 'storeInsurance']);
    Route::put('buses/{bus}/insurance-records/{insurance}', [BusApiController::class, 'updateInsurance']);
    Route::delete('buses/{bus}/insurance-records/{insurance}', [BusApiController::class, 'destroyInsurance']);
    
    // ===== PANNES =====
    // POST existe déjà
    Route::put('buses/{bus}/breakdowns/{breakdown}', [BusApiController::class, 'updateBreakdown']);
    Route::delete('buses/{bus}/breakdowns/{breakdown}', [BusApiController::class, 'destroyBreakdown']);
    
    // ===== VIDANGES =====
    // POST existe déjà
    Route::put('buses/{bus}/vidanges/{vidange}', [BusApiController::class, 'updateVidange']);
    Route::delete('buses/{bus}/vidanges/{vidange}', [BusApiController::class, 'destroyVidange']);
});
```

---

## 📝 MÉTHODES À AJOUTER DANS BusApiController

### Fichier : `app/Http/Controllers/Api/BusApiController.php`

Ajoutez ces méthodes à la fin de la classe :

```php
<?php

// ===== VISITES TECHNIQUES =====

/**
 * Créer une visite technique
 */
public function storeTechnicalVisit(Request $request, $busId)
{
    $validated = $request->validate([
        'visit_date' => 'required|date',
        'expiry_date' => 'required|date|after:visit_date',
        'result' => 'required|string|in:Favorable,Défavorable',
        'visit_center' => 'nullable|string|max:255',
        'cost' => 'nullable|numeric|min:0',
        'certificate_number' => 'nullable|string|max:100',
        'notes' => 'nullable|string',
    ]);

    $visit = TechnicalVisit::create([
        'bus_id' => $busId,
        ...$validated,
    ]);

    return response()->json($visit, 201);
}

/**
 * Modifier une visite technique
 */
public function updateTechnicalVisit(Request $request, $busId, $visitId)
{
    $visit = TechnicalVisit::where('bus_id', $busId)->findOrFail($visitId);
    
    $validated = $request->validate([
        'visit_date' => 'required|date',
        'expiry_date' => 'required|date|after:visit_date',
        'result' => 'required|string|in:Favorable,Défavorable',
        'visit_center' => 'nullable|string|max:255',
        'cost' => 'nullable|numeric|min:0',
        'certificate_number' => 'nullable|string|max:100',
        'notes' => 'nullable|string',
    ]);

    $visit->update($validated);

    return response()->json($visit);
}

/**
 * Supprimer une visite technique
 */
public function destroyTechnicalVisit($busId, $visitId)
{
    $visit = TechnicalVisit::where('bus_id', $busId)->findOrFail($visitId);
    $visit->delete();

    return response()->json(['message' => 'Visite technique supprimée avec succès'], 200);
}

// ===== ASSURANCES =====

/**
 * Créer une assurance
 */
public function storeInsurance(Request $request, $busId)
{
    $validated = $request->validate([
        'insurance_company' => 'required|string|max:255',
        'policy_number' => 'required|string|max:100',
        'start_date' => 'required|date',
        'expiry_date' => 'required|date|after:start_date',
        'coverage_type' => 'required|string|max:100',
        'premium' => 'required|numeric|min:0',
        'notes' => 'nullable|string',
    ]);

    $insurance = InsuranceRecord::create([
        'bus_id' => $busId,
        ...$validated,
    ]);

    return response()->json($insurance, 201);
}

/**
 * Modifier une assurance
 */
public function updateInsurance(Request $request, $busId, $insuranceId)
{
    $insurance = InsuranceRecord::where('bus_id', $busId)->findOrFail($insuranceId);
    
    $validated = $request->validate([
        'insurance_company' => 'required|string|max:255',
        'policy_number' => 'required|string|max:100',
        'start_date' => 'required|date',
        'expiry_date' => 'required|date|after:start_date',
        'coverage_type' => 'required|string|max:100',
        'premium' => 'required|numeric|min:0',
        'notes' => 'nullable|string',
    ]);

    $insurance->update($validated);

    return response()->json($insurance);
}

/**
 * Supprimer une assurance
 */
public function destroyInsurance($busId, $insuranceId)
{
    $insurance = InsuranceRecord::where('bus_id', $busId)->findOrFail($insuranceId);
    $insurance->delete();

    return response()->json(['message' => 'Assurance supprimée avec succès'], 200);
}

// ===== PANNES =====

/**
 * Modifier une panne
 */
public function updateBreakdown(Request $request, $busId, $breakdownId)
{
    $breakdown = BusBreakdown::where('bus_id', $busId)->findOrFail($breakdownId);
    
    $validated = $request->validate([
        'description' => 'required|string',
        'breakdown_date' => 'required|date',
        'severity' => 'required|string|in:low,medium,high',
        'status' => 'required|string|in:reported,in_progress,resolved',
        'repair_cost' => 'nullable|numeric|min:0',
        'resolved_date' => 'nullable|date|after_or_equal:breakdown_date',
        'notes' => 'nullable|string',
    ]);

    $breakdown->update($validated);

    return response()->json($breakdown);
}

/**
 * Supprimer une panne
 */
public function destroyBreakdown($busId, $breakdownId)
{
    $breakdown = BusBreakdown::where('bus_id', $busId)->findOrFail($breakdownId);
    $breakdown->delete();

    return response()->json(['message' => 'Panne supprimée avec succès'], 200);
}

// ===== VIDANGES =====

/**
 * Modifier une vidange
 */
public function updateVidange(Request $request, $busId, $vidangeId)
{
    $vidange = BusVidange::where('bus_id', $busId)->findOrFail($vidangeId);
    
    $validated = $request->validate([
        'type' => 'required|string|max:100',
        'vidange_date' => 'nullable|date',
        'next_vidange_date' => 'nullable|date',
        'planned_date' => 'nullable|date',
        'cost' => 'nullable|numeric|min:0',
        'service_provider' => 'nullable|string|max:255',
        'mileage' => 'nullable|numeric|min:0',
        'notes' => 'nullable|string',
    ]);

    $vidange->update($validated);

    return response()->json($vidange);
}

/**
 * Supprimer une vidange
 */
public function destroyVidange($busId, $vidangeId)
{
    $vidange = BusVidange::where('bus_id', $busId)->findOrFail($vidangeId);
    $vidange->delete();

    return response()->json(['message' => 'Vidange supprimée avec succès'], 200);
}
```

---

## 🔍 MODÈLES REQUIS

Assurez-vous que ces modèles existent dans `app/Models/` :

1. **TechnicalVisit.php**
2. **InsuranceRecord.php**
3. **BusBreakdown.php**
4. **BusVidange.php**

Si un modèle n'existe pas, créez-le avec :

```bash
php artisan make:model TechnicalVisit
php artisan make:model InsuranceRecord
php artisan make:model BusBreakdown
php artisan make:model BusVidange
```

### Exemple de modèle : TechnicalVisit.php

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TechnicalVisit extends Model
{
    protected $fillable = [
        'bus_id',
        'visit_date',
        'expiry_date',
        'visit_center',
        'result',
        'cost',
        'notes',
        'certificate_number',
    ];

    protected $casts = [
        'visit_date' => 'date',
        'expiry_date' => 'date',
        'cost' => 'decimal:2',
    ];

    public function bus()
    {
        return $this->belongsTo(Bus::class);
    }
}
```

Répétez ce pattern pour les 3 autres modèles.

---

## ✅ CHECKLIST

- [ ] Routes ajoutées dans `routes/api.php`
- [ ] Méthodes ajoutées dans `BusApiController.php`
- [ ] Modèles créés/vérifiés
- [ ] Migrations exécutées (`php artisan migrate`)
- [ ] Tester avec Postman/Insomnia
- [ ] Déployer sur serveur

---

## 🧪 TESTS AVEC POSTMAN

### Créer une visite technique

```http
POST /api/buses/1/technical-visits
Authorization: Bearer {token}
Content-Type: application/json

{
    "visit_date": "2025-01-15",
    "expiry_date": "2026-01-15",
    "result": "Favorable",
    "visit_center": "Centre Auto Dakar",
    "cost": 50000,
    "certificate_number": "VT-2025-001",
    "notes": "RAS"
}
```

### Modifier une visite

```http
PUT /api/buses/1/technical-visits/1
Authorization: Bearer {token}
Content-Type: application/json

{
    "visit_date": "2025-01-15",
    "expiry_date": "2026-01-15",
    "result": "Défavorable",
    "notes": "Problème freins"
}
```

### Supprimer une visite

```http
DELETE /api/buses/1/technical-visits/1
Authorization: Bearer {token}
```

---

**Répétez ces tests pour Assurances, Pannes et Vidanges ! ✅**
