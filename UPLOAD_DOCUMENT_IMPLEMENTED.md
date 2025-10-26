# ✅ Fonctionnalité Upload Document - IMPLÉMENTÉE

## 📋 Ce Qui a Été Fait

### 1. ✅ Package `file_picker` Ajouté

**Fichier** : `pubspec.yaml`

```yaml
# File Picker
file_picker: ^8.0.0+1
```

### 2. ✅ Formulaire de Patente Mis à Jour

**Fichier** : `lib/screens/bus/patent_form_screen.dart`

#### Imports Ajoutés :
```dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
```

#### Variables d'État :
```dart
// Variables pour le document
File? _documentFile;
String? _documentFileName;
```

#### Bouton Upload Dynamique :
```dart
OutlinedButton.icon(
  onPressed: _pickDocument,
  icon: Icon(
    _documentFile != null ? Icons.check_circle : Icons.upload_file,
    color: _documentFile != null ? Colors.green : null,
  ),
  label: Text(
    _documentFile != null
        ? 'Document sélectionné: $_documentFileName'
        : 'Téléverser un document (PDF, Image)',
  ),
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    side: BorderSide(
      color: _documentFile != null ? Colors.green : Colors.grey,
      width: _documentFile != null ? 2 : 1,
    ),
  ),
)
```

#### Bouton "Retirer" (si document sélectionné) :
```dart
if (_documentFile != null) ..[
  const SizedBox(height: 8),
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      TextButton.icon(
        onPressed: _removeDocument,
        icon: const Icon(Icons.close, size: 18),
        label: const Text('Retirer le document'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
        ),
      ),
    ],
  ),
]
```

### 3. ✅ Méthodes Implémentées

#### `_pickDocument()` - Sélection de Fichier
```dart
Future<void> _pickDocument() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _documentFile = File(result.files.single.path!);
        _documentFileName = result.files.single.name;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document sélectionné: ${result.files.single.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

#### `_removeDocument()` - Retirer le Document
```dart
void _removeDocument() {
  setState(() {
    _documentFile = null;
    _documentFileName = null;
  });
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Document retiré')),
  );
}
```

---

## 🎯 Fonctionnalités

### ✅ Types de Fichiers Acceptés
- **PDF** : `.pdf`
- **Images** : `.jpg`, `.jpeg`, `.png`

### ✅ Interface Utilisateur
1. **Avant sélection** :
   - Icône : 📤 Upload
   - Texte : "Téléverser un document (PDF, Image)"
   - Bordure : Grise

2. **Après sélection** :
   - Icône : ✅ Check (vert)
   - Texte : "Document sélectionné: nom_du_fichier.pdf"
   - Bordure : Verte (2px)
   - Bouton "Retirer le document" (rouge)

### ✅ Messages de Feedback
- ✅ **Succès** : "Document sélectionné: [nom]" (vert)
- ✅ **Erreur** : "Erreur lors de la sélection du fichier: [détails]" (rouge)
- ✅ **Retrait** : "Document retiré"

---

## 🚀 INSTALLATION

### Étape 1 : Installer les Dépendances

```bash
flutter pub get
```

### Étape 2 : Redémarrer l'Application

**Option A - Hot Restart** :
- VS Code : `Cmd+Shift+F5` (Mac) ou `Ctrl+Shift+F5` (Windows)
- Android Studio : Bouton "Hot Restart"

**Option B - Relancer** :
```bash
flutter run
```

---

## 🧪 TEST

### Scénario 1 : Sélection d'un PDF

1. Ouvrir le formulaire de patente
2. Cliquer sur "Téléverser un document"
3. Sélectionner un fichier PDF
4. ✅ Voir : "Document sélectionné: mon_document.pdf" (vert)
5. ✅ Bouton "Retirer le document" apparaît

### Scénario 2 : Sélection d'une Image

1. Cliquer sur "Téléverser un document"
2. Sélectionner une image (.jpg, .jpeg, .png)
3. ✅ Voir : "Document sélectionné: photo.jpg" (vert)

### Scénario 3 : Retirer un Document

1. Après avoir sélectionné un document
2. Cliquer sur "Retirer le document"
3. ✅ Bouton redevient normal
4. ✅ Message : "Document retiré"

### Scénario 4 : Annuler la Sélection

1. Cliquer sur "Téléverser un document"
2. Appuyer sur "Annuler" dans le sélecteur
3. ✅ Rien ne se passe (normal)

---

## ⚠️ PROCHAINE ÉTAPE : Upload vers le Serveur

Actuellement, le fichier est **sélectionné** mais **pas encore envoyé** au serveur.

Pour envoyer le fichier au serveur Laravel, il faut :

### 1. Créer une Route Laravel

**Fichier** : `routes/api.php`

```php
Route::post('/upload-patent-document', [UploadController::class, 'uploadPatentDocument']);
```

### 2. Créer le Contrôleur

**Fichier** : `app/Http/Controllers/Api/UploadController.php`

```php
public function uploadPatentDocument(Request $request)
{
    $request->validate([
        'document' => 'required|file|mimes:pdf,jpg,jpeg,png|max:10240', // 10MB max
    ]);

    $path = $request->file('document')->store('patent-documents', 'public');
    
    return response()->json([
        'success' => true,
        'path' => $path,
        'url' => Storage::url($path),
    ]);
}
```

### 3. Modifier la Méthode `_submit()` dans Flutter

```dart
Future<void> _submit() async {
  // ... validation ...

  // 1. Uploader le document d'abord (si présent)
  String? documentPath;
  if (_documentFile != null) {
    documentPath = await _uploadDocument();
    if (documentPath == null) {
      // Erreur d'upload
      return;
    }
  }

  // 2. Créer la patente avec le chemin du document
  final patent = Patent(
    // ... autres champs ...
    documentPath: documentPath,
  );

  // 3. Envoyer au serveur
  // ...
}

Future<String?> _uploadDocument() async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/upload-patent-document'),
    );

    request.files.add(await http.MultipartFile.fromPath(
      'document',
      _documentFile!.path,
    ));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final json = jsonDecode(responseData);

    if (json['success']) {
      return json['path'];
    }
    return null;
  } catch (e) {
    print('Erreur upload: $e');
    return null;
  }
}
```

---

## 📊 Résumé

| Fonctionnalité | Statut |
|----------------|--------|
| Package `file_picker` | ✅ Ajouté |
| Sélection de fichier | ✅ Implémenté |
| Types acceptés (PDF, Images) | ✅ Configuré |
| Interface dynamique | ✅ Implémenté |
| Bouton "Retirer" | ✅ Implémenté |
| Messages de feedback | ✅ Implémenté |
| Upload vers serveur | ⚠️ À implémenter |

---

**Date** : 26 octobre 2025  
**Statut** : ✅ Sélection fonctionnelle - Upload serveur à implémenter
