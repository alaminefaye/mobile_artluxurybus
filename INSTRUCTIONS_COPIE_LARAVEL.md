# 📋 INSTRUCTIONS POUR COPIER LE CODE LARAVEL

## ✅ FICHIERS CRÉÉS

J'ai créé 2 fichiers PHP prêts à copier :

1. **`laravel_routes_crud_bus.php`** - Routes API
2. **`laravel_controller_methods.php`** - Méthodes contrôleur

---

## 🚀 ÉTAPE 1 : AJOUTER LES ROUTES

### Fichier cible
`/Users/mouhamadoulamineFaye/Desktop/PROJETS DEV/gestion-compagny/routes/api.php`

### Instructions

1. Ouvrez `routes/api.php` dans votre projet Laravel
2. Trouvez le groupe `Route::middleware('auth:sanctum')`
3. Cherchez les routes bus existantes (probablement vers la ligne 50-100)
4. **Copiez tout le contenu** de `laravel_routes_crud_bus.php`
5. **Collez-le** après les routes bus existantes

### Exemple de placement

```php
Route::middleware('auth:sanctum')->group(function () {
    // ... routes existantes ...
    
    // Routes bus existantes
    Route::get('buses', [BusApiController::class, 'index']);
    Route::get('buses/{id}', [BusApiController::class, 'show']);
    // ... autres routes bus ...
    
    // ===== NOUVEAU : Collez ici le contenu de laravel_routes_crud_bus.php =====
    Route::post('buses/{bus}/technical-visits', [BusApiController::class, 'storeTechnicalVisit']);
    Route::put('buses/{bus}/technical-visits/{visit}', [BusApiController::class, 'updateTechnicalVisit']);
    // ... etc ...
});
```

---

## 🚀 ÉTAPE 2 : AJOUTER LES MÉTHODES

### Fichier cible
`/Users/mouhamadoulamineFaye/Desktop/PROJETS DEV/gestion-compagny/app/Http/Controllers/Api/BusApiController.php`

### Instructions

1. Ouvrez `BusApiController.php`
2. Allez **tout en bas du fichier**
3. Trouvez la **dernière accolade fermante** `}` de la classe
4. **Copiez tout le contenu** de `laravel_controller_methods.php`
5. **Collez-le AVANT** la dernière accolade fermante

### Exemple de placement

```php
class BusApiController extends Controller
{
    // ... méthodes existantes ...
    
    public function getFuelHistory($id) {
        // ... code existant ...
    }
    
    // ===== NOUVEAU : Collez ici le contenu de laravel_controller_methods.php =====
    
    /**
     * Créer une visite technique
     */
    public function storeTechnicalVisit(Request $request, $busId)
    {
        // ... code ...
    }
    
    // ... toutes les autres méthodes ...
    
} // <- Cette accolade ferme la classe, NE PAS LA SUPPRIMER
```

---

## 🧪 ÉTAPE 3 : TESTER

### Avec Postman

**Créer une visite technique** :
```http
POST http://votre-domaine.com/api/buses/1/technical-visits
Authorization: Bearer {votre_token}
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

**Modifier une visite** :
```http
PUT http://votre-domaine.com/api/buses/1/technical-visits/1
Authorization: Bearer {votre_token}
Content-Type: application/json

{
    "visit_date": "2025-01-15",
    "expiry_date": "2026-01-15",
    "result": "Défavorable",
    "notes": "Problème freins"
}
```

**Supprimer une visite** :
```http
DELETE http://votre-domaine.com/api/buses/1/technical-visits/1
Authorization: Bearer {votre_token}
```

Répétez pour :
- Assurances : `/insurance-records`
- Pannes : `/breakdowns`
- Vidanges : `/vidanges`

---

## ⚠️ VÉRIFICATIONS

Avant de tester, assurez-vous que :

- [ ] Les modèles existent (`TechnicalVisit`, `InsuranceRecord`, `BusBreakdown`, `BusVidange`)
- [ ] Les tables existent en base de données
- [ ] Les migrations ont été exécutées
- [ ] Vous avez un token d'authentification valide

---

## 📝 MODÈLES REQUIS

Si les modèles n'existent pas, créez-les :

```bash
cd /Users/mouhamadoulamineFaye/Desktop/PROJETS\ DEV/gestion-compagny
php artisan make:model TechnicalVisit
php artisan make:model InsuranceRecord
php artisan make:model BusBreakdown
php artisan make:model BusVidange
```

Puis ajoutez les `$fillable` dans chaque modèle (voir `BACKEND_LARAVEL_CRUD_COMPLETE.md` pour les exemples).

---

## ✅ RÉSULTAT ATTENDU

Après avoir copié le code :

- ✅ 12 nouvelles routes API fonctionnelles
- ✅ 12 méthodes contrôleur opérationnelles
- ✅ CRUD complet pour 4 ressources
- ✅ Validation des données
- ✅ Messages d'erreur appropriés

---

**Temps estimé** : 10-15 minutes

**Difficulté** : Facile (copier-coller)

🎉 **Bonne chance !**
