# Suppression du champ 'cost' - Visites Techniques

## Problème identifié
L'erreur SQL indique que le formulaire web essaie d'insérer une colonne `cost` qui n'existe pas dans la table `technical_visits`.

```
SQLSTATE[42S22]: Column not found: 1054 Unknown column 'cost'
```

## Solution : Supprimer le champ du formulaire

### Fichiers à modifier dans le projet Laravel

#### 1. Formulaire de création partagé
**Fichier** : `resources/views/admin/technical-visits/shared-form.blade.php`

**Chercher et SUPPRIMER** ce bloc :
```html
<!-- À SUPPRIMER -->
<div class="form-group">
    <label for="cost">Coût</label>
    <input type="number" 
           class="form-control @error('cost') is-invalid @enderror" 
           id="cost" 
           name="cost" 
           step="0.01"
           value="{{ old('cost') }}">
    @error('cost')
        <span class="invalid-feedback">{{ $message }}</span>
    @enderror
</div>
```

#### 2. Formulaire de création admin (si existe)
**Fichier** : `resources/views/admin/technical-visits/create.blade.php`

**Chercher et SUPPRIMER** le même bloc de code pour le champ `cost`.

#### 3. Formulaire d'édition (si existe)
**Fichier** : `resources/views/admin/technical-visits/edit.blade.php`

**Chercher et SUPPRIMER** :
```html
<!-- À SUPPRIMER -->
<div class="form-group">
    <label for="cost">Coût</label>
    <input type="number" 
           class="form-control @error('cost') is-invalid @enderror" 
           id="cost" 
           name="cost" 
           step="0.01"
           value="{{ old('cost', $technicalVisit->cost) }}">
    @error('cost')
        <span class="invalid-feedback">{{ $message }}</span>
    @enderror
</div>
```

## Vérification

### Contrôleur déjà correct ✅
Le fichier `app/Http/Controllers/Admin/TechnicalVisitController.php` est déjà correct :
- Ligne 85-91 : Validation sans 'cost'
- Ligne 125-131 : Validation sans 'cost'
- Ligne 215-220 : Validation sans 'cost'

**Aucune modification nécessaire dans le contrôleur.**

### Structure de la table
La table `technical_visits` contient :
- `id`
- `bus_id`
- `visit_date`
- `expiration_date`
- `document_photo`
- `notes`
- `created_at`
- `updated_at`

**Pas de colonne `cost`** → Le champ doit être supprimé du formulaire.

## Étapes de correction

1. **Ouvrir le projet Laravel** :
   ```bash
   cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/gestion-compagny
   ```

2. **Éditer le formulaire partagé** :
   ```bash
   nano resources/views/admin/technical-visits/shared-form.blade.php
   ```
   - Chercher le champ `cost`
   - Supprimer tout le bloc `<div class="form-group">...</div>` contenant `name="cost"`
   - Sauvegarder (Ctrl+O, Enter, Ctrl+X)

3. **Vérifier les autres formulaires** :
   ```bash
   # Chercher tous les fichiers contenant 'cost'
   grep -r "name=\"cost\"" resources/views/admin/technical-visits/
   ```

4. **Tester** :
   - Recharger la page du formulaire
   - Essayer de créer une visite technique
   - L'erreur devrait disparaître

## Alternative (si vous voulez garder le champ cost)

Si le champ `cost` est vraiment nécessaire, créez une migration :

```bash
php artisan make:migration add_cost_to_technical_visits_table
```

Puis ajoutez dans la migration :
```php
public function up()
{
    Schema::table('technical_visits', function (Blueprint $table) {
        $table->decimal('cost', 10, 2)->nullable()->after('notes');
    });
}

public function down()
{
    Schema::table('technical_visits', function (Blueprint $table) {
        $table->dropColumn('cost');
    });
}
```

Exécutez :
```bash
php artisan migrate
```

Puis modifiez le contrôleur pour accepter 'cost' dans la validation.

## Recommandation

**Supprimez simplement le champ du formulaire** car :
- ✅ Plus rapide
- ✅ Pas de modification de base de données
- ✅ Cohérent avec l'API mobile (qui n'utilise pas 'cost')
- ✅ Le contrôleur est déjà correct

## Résultat attendu

Après suppression du champ `cost` du formulaire :
- ✅ Création de visite technique fonctionnelle
- ✅ Plus d'erreur SQL
- ✅ Formulaire cohérent avec la structure de la table
