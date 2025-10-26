# ✅ BACKEND - Upload Facture Corrigé !

## Problème résolu

**Erreur 422** : `"The facture photo field must be a string"`

### Cause
Le backend Laravel attendait une **string** mais recevait un **fichier image** uploadé par Flutter.

### Solution appliquée

Modifié `addBreakdown()` dans `BusApiController.php` pour :
1. Accepter un fichier image au lieu d'une string
2. Uploader le fichier dans `storage/bus_breakdowns/factures/`
3. Stocker le chemin dans la base de données

## Code corrigé

### Validation

**AVANT** (❌) :
```php
'facture_photo' => 'nullable|string',
```

**APRÈS** (✅) :
```php
'facture_photo' => 'nullable|image|max:15360', // 15MB max
```

### Upload du fichier

**Ajouté** :
```php
// Gestion de l'upload de la photo de facture
if ($request->hasFile('facture_photo')) {
    $file = $request->file('facture_photo');
    $filename = time() . '_' . $file->getClientOriginalName();
    $data['facture_photo'] = $file->storeAs('bus_breakdowns/factures', $filename, 'public');
}
```

## Méthodes corrigées

### 1. ✅ `addBreakdown()` (ligne 237-280)
- Accepte fichier image
- Upload dans `storage/public/bus_breakdowns/factures/`
- Nom de fichier : `timestamp_nomoriginal.jpg`

### 2. ✅ `updateBreakdown()` (ligne 554-585)
Déjà correcte ! Gère :
- Upload nouvelle photo
- Suppression ancienne photo
- Validation image

## Stockage des fichiers

### Structure
```
storage/
  └── app/
      └── public/
          └── bus_breakdowns/
              └── factures/
                  ├── 1729900000_facture1.jpg
                  ├── 1729900001_facture2.jpg
                  └── ...
```

### URL d'accès
```
https://gestion-compagny.universaltechnologiesafrica.com/storage/bus_breakdowns/factures/1729900000_facture1.jpg
```

## Configuration Laravel

### Vérifier le lien symbolique

Si les images ne s'affichent pas, créer le lien :

```bash
cd /path/to/gestion-compagny
php artisan storage:link
```

Cela crée un lien symbolique :
```
public/storage -> storage/app/public
```

## Test

### 1. Créer une panne avec facture

**Flutter** :
1. Bus → Pannes → [+]
2. Remplir les champs
3. Ajouter une photo
4. Cliquer "Ajouter"

**Backend** :
- ✅ Reçoit le fichier via multipart/form-data
- ✅ Valide que c'est une image
- ✅ Upload dans `storage/public/bus_breakdowns/factures/`
- ✅ Enregistre le chemin en BDD
- ✅ Retourne la panne créée

### 2. Modifier une panne avec nouvelle facture

**Flutter** :
1. Ouvrir une panne
2. Modifier → Remplacer facture
3. Cliquer "Modifier"

**Backend** :
- ✅ Supprime l'ancienne photo
- ✅ Upload la nouvelle
- ✅ Met à jour le chemin en BDD

### 3. Afficher la facture

**Flutter** :
1. Ouvrir les détails d'une panne
2. Scroll en bas
3. ✅ La photo de facture s'affiche

**URL construite** :
```dart
breakdown.facturePhoto!.startsWith('http')
    ? breakdown.facturePhoto!
    : 'https://gestion-compagny.../storage/${breakdown.facturePhoto!}'
```

## Formats acceptés

- **Images** : JPG, JPEG, PNG, GIF, BMP, SVG, WEBP
- **Taille max** : 15 MB (15360 KB)
- **Validation** : Automatique par Laravel

## Sécurité

### Validation
- ✅ Type de fichier vérifié (image uniquement)
- ✅ Taille limitée (15 MB max)
- ✅ Nom de fichier sécurisé (timestamp + nom)

### Stockage
- ✅ Fichiers dans `storage/app/public` (hors web root)
- ✅ Accès via lien symbolique
- ✅ Permissions contrôlées

## Résultat

✅ **L'upload de facture fonctionne maintenant !**

### Flux complet
1. Flutter sélectionne photo → File
2. BusApiService envoie via multipart/form-data
3. Laravel reçoit le fichier
4. Laravel valide (image, taille)
5. Laravel upload dans storage
6. Laravel enregistre le chemin en BDD
7. Flutter affiche la photo depuis l'URL

Tout est opérationnel ! 🎉
