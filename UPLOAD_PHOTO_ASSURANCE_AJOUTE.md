# ✅ Upload Photo Document Assurance Ajouté !

## Fonctionnalité ajoutée

Le formulaire d'assurance permet maintenant d'**ajouter/modifier la photo du document** !

## Modifications apportées

### 1. ✅ Imports ajoutés
```dart
import 'package:image_picker/image_picker.dart';
import 'dart:io';
```

### 2. ✅ Variables ajoutées
```dart
File? _documentPhoto;
final _picker = ImagePicker();
```

### 3. ✅ Méthode `_pickImage()` créée
Permet de sélectionner une photo depuis la galerie :
- Résolution max : 1920x1080
- Qualité : 85%
- Gestion des erreurs

### 4. ✅ Interface utilisateur

#### Cas 1 : Nouvelle assurance (pas de photo)
```
┌─────────────────────────────┐
│ 📎 Document photo           │
│                             │
│ [📷 Ajouter une photo]      │
└─────────────────────────────┘
```

#### Cas 2 : Photo sélectionnée
```
┌─────────────────────────────┐
│ 📎 Document photo           │
│                             │
│ [Image preview 200px]       │
│                             │
│ [✏️ Changer] [🗑️ Supprimer] │
└─────────────────────────────┘
```

#### Cas 3 : Modification (document existant)
```
┌─────────────────────────────┐
│ 📎 Document photo           │
│                             │
│ ✅ Document actuel disponible│
│                             │
│ [✏️ Remplacer le document]  │
└─────────────────────────────┘
```

## Utilisation

### Ajouter une photo (nouvelle assurance)

1. Ouvrez le formulaire de nouvelle assurance
2. Remplissez les champs obligatoires
3. Cliquez sur **"📷 Ajouter une photo"**
4. Sélectionnez une photo depuis la galerie
5. La photo s'affiche en prévisualisation
6. Cliquez sur **"Ajouter"**

### Modifier une photo (assurance existante)

1. Ouvrez une assurance existante
2. Cliquez sur **"✏️ Modifier"**
3. Si un document existe : **"✏️ Remplacer le document"**
4. Si pas de document : **"📷 Ajouter une photo"**
5. Sélectionnez la nouvelle photo
6. Cliquez sur **"Modifier"**

### Supprimer une photo sélectionnée

1. Après avoir sélectionné une photo
2. Cliquez sur **"🗑️ Supprimer"**
3. La photo est retirée (mais pas encore envoyée au serveur)

## Fonctionnalités

### ✅ Prévisualisation
- Image affichée à 200px de hauteur
- Largeur pleine
- Coins arrondis (8px)
- Fit: cover

### ✅ Optimisation
- Résolution max : 1920x1080 (évite fichiers trop lourds)
- Qualité : 85% (bon compromis qualité/taille)
- Source : Galerie uniquement

### ✅ Gestion des états
- **Pas de photo** : Bouton "Ajouter"
- **Photo sélectionnée** : Preview + Changer/Supprimer
- **Document existant** : Message + Bouton "Remplacer"

### ✅ Gestion des erreurs
- Message d'erreur si problème de sélection
- SnackBar rouge avec le message d'erreur

## Prochaine étape : Backend

⚠️ **Important** : Le formulaire sélectionne la photo mais **ne l'envoie pas encore au serveur**.

Pour que ça fonctionne complètement, il faut :

### 1. Modifier `BusApiService` pour supporter l'upload

```dart
Future<void> addInsurance(int busId, Map<String, dynamic> data, {File? documentPhoto}) async {
  final uri = Uri.parse('$baseUrl/api/buses/$busId/insurance-records');
  
  if (documentPhoto != null) {
    // Utiliser multipart/form-data
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${await _getToken()}';
    
    // Ajouter les champs
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });
    
    // Ajouter la photo
    request.files.add(
      await http.MultipartFile.fromPath(
        'document_photo',
        documentPhoto.path,
      ),
    );
    
    final response = await request.send();
    // ...
  } else {
    // Requête JSON normale
    // ...
  }
}
```

### 2. Modifier `_submit()` dans le formulaire

```dart
Future<void> _submit() async {
  // ...
  
  if (widget.insurance == null) {
    await _apiService.addInsurance(
      widget.busId, 
      data,
      documentPhoto: _documentPhoto,  // ← Passer la photo
    );
  } else {
    await _apiService.updateInsurance(
      widget.busId, 
      widget.insurance!.id, 
      data,
      documentPhoto: _documentPhoto,  // ← Passer la photo
    );
  }
  
  // ...
}
```

### 3. Backend Laravel doit accepter le fichier

Le contrôleur Laravel doit gérer :
```php
if ($request->hasFile('document_photo')) {
    $path = $request->file('document_photo')->store('insurance_records', 'public');
    $data['document_photo'] = $path;
}
```

## Avantages de cette implémentation

✅ **Interface intuitive** : Boutons clairs selon le contexte
✅ **Prévisualisation** : L'utilisateur voit la photo avant d'envoyer
✅ **Modification facile** : Peut changer ou supprimer la photo
✅ **Optimisation** : Photos redimensionnées automatiquement
✅ **Gestion d'erreurs** : Messages clairs en cas de problème
✅ **État existant** : Indique si un document existe déjà

## Test de l'interface

### 1. Tester la sélection
```
Formulaire → Ajouter une photo → Sélectionner → Voir preview
```

### 2. Tester le changement
```
Preview visible → Changer → Sélectionner nouvelle → Voir nouvelle preview
```

### 3. Tester la suppression
```
Preview visible → Supprimer → Preview disparaît
```

### 4. Tester avec document existant
```
Modifier assurance avec document → Voir "Document actuel disponible"
```

## Résultat actuel

🎉 **L'interface est prête !**

- ✅ Sélection de photo fonctionnelle
- ✅ Prévisualisation affichée
- ✅ Boutons Changer/Supprimer
- ✅ Gestion des états
- ⚠️ **Envoi au serveur à implémenter**

## Pour compléter

1. Modifier `BusApiService` pour supporter multipart/form-data
2. Passer `_documentPhoto` dans les appels API
3. Vérifier que le backend Laravel accepte le fichier
4. Tester l'upload complet

L'interface utilisateur est maintenant complète et prête à envoyer les photos dès que le backend sera configuré ! 🚀
