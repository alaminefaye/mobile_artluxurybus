# 🚀 Guide Complet CRUD - Modules Bus

## ✅ Déjà Implémenté

### 1. Module Carburant
- ✅ Écran détails: `fuel_record_detail_screen.dart`
- ✅ Formulaire ajout/modification: `fuel_record_form_screen.dart`
- ✅ Navigation depuis liste vers détails
- ⏳ À faire: Connecter aux APIs et ajouter bouton FAB

---

## 📋 Étapes pour Finaliser le Module Carburant

### Étape 1: Ajouter bouton FAB dans bus_detail_screen.dart

```dart
// Dans _buildFuelTab(), remplacer return Column par:
return Stack(
  children: [
    Column(
      children: [
        // ... code existant des stats et liste
      ],
    ),
    
    // Bouton Flottant Ajouter
    Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FuelRecordFormScreen(busId: busId),
            ),
          );
          
          if (result == true) {
            // Rafraîchir la liste
            ref.refresh(fuelHistoryProvider(busId));
            ref.refresh(fuelStatsProvider(busId));
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    ),
  ],
);
```

### Étape 2: Ajouter import dans bus_detail_screen.dart

```dart
import 'fuel_record_form_screen.dart';
```

### Étape 3: Implémenter API DELETE dans fuel_record_detail_screen.dart

Remplacer le TODO ligne 280 par:

```dart
try {
  final apiService = BusApiService();
  await apiService.deleteFuelRecord(busId, fuelRecord.id);
  
  if (mounted) {
    Navigator.pop(context); // Fermer dialog
    Navigator.pop(context, true); // Retour avec succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enregistrement supprimé'),
        backgroundColor: Colors.green,
      ),
    );
  }
} catch (e) {
  if (mounted) {
    Navigator.pop(context); // Fermer dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Étape 4: Ajouter méthode DELETE dans bus_api_service.dart

```dart
/// Supprimer un enregistrement de carburant
Future<void> deleteFuelRecord(int busId, int recordId) async {
  try {
    _log('🗑️ Suppression du carburant #$recordId...');
    
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/buses/$busId/fuel-records/$recordId'),
      headers: headers,
    ).timeout(ApiConfig.requestTimeout);
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      _log('✅ Carburant supprimé avec succès');
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    _log('❌ Erreur lors de la suppression: $e');
    rethrow;
  }
}
```

### Étape 5: Implémenter API POST/PUT dans fuel_record_form_screen.dart

Remplacer les lignes 145-150 par:

```dart
final apiService = BusApiService();

if (widget.fuelRecord == null) {
  // Création
  await apiService.addFuelRecord(
    busId: widget.busId,
    quantity: double.parse(_quantityController.text),
    cost: double.parse(_costController.text),
    unitPrice: _unitPriceController.text.isNotEmpty 
        ? double.parse(_unitPriceController.text)
        : null,
    fueledAt: _selectedDate,
    fuelType: _fuelType,
    fuelStation: _stationController.text.isNotEmpty ? _stationController.text : null,
    mileage: _mileageController.text.isNotEmpty 
        ? double.parse(_mileageController.text)
        : null,
    notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    invoiceImage: _invoiceImage,
  );
} else {
  // Modification
  await apiService.updateFuelRecord(
    busId: widget.busId,
    recordId: widget.fuelRecord!.id,
    quantity: double.parse(_quantityController.text),
    cost: double.parse(_costController.text),
    unitPrice: _unitPriceController.text.isNotEmpty 
        ? double.parse(_unitPriceController.text)
        : null,
    fueledAt: _selectedDate,
    fuelType: _fuelType,
    fuelStation: _stationController.text.isNotEmpty ? _stationController.text : null,
    mileage: _mileageController.text.isNotEmpty 
        ? double.parse(_mileageController.text)
        : null,
    notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    invoiceImage: _invoiceImage,
  );
}
```

### Étape 6: Ajouter méthodes POST/PUT dans bus_api_service.dart

```dart
/// Ajouter un enregistrement de carburant
Future<FuelRecord> addFuelRecord({
  required int busId,
  required double quantity,
  required double cost,
  double? unitPrice,
  required DateTime fueledAt,
  String? fuelType,
  String? fuelStation,
  double? mileage,
  String? notes,
  File? invoiceImage,
}) async {
  try {
    _log('➕ Ajout d\'un enregistrement de carburant...');
    
    final headers = await _getHeaders();
    
    // Si image, utiliser multipart
    if (invoiceImage != null) {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/fuel-records'),
      );
      
      request.headers.addAll(headers);
      request.fields['quantity'] = quantity.toString();
      request.fields['cost'] = cost.toString();
      if (unitPrice != null) request.fields['unit_price'] = unitPrice.toString();
      request.fields['fueled_at'] = fueledAt.toIso8601String().split('T')[0];
      if (fuelType != null) request.fields['fuel_type'] = fuelType;
      if (fuelStation != null) request.fields['fuel_station'] = fuelStation;
      if (mileage != null) request.fields['mileage'] = mileage.toString();
      if (notes != null) request.fields['notes'] = notes;
      
      request.files.add(await http.MultipartFile.fromPath(
        'invoice_photo',
        invoiceImage.path,
      ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _log('✅ Enregistrement ajouté avec succès');
        return FuelRecord.fromJson(data);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } else {
      // Sans image, utiliser JSON normal
      final body = {
        'quantity': quantity,
        'cost': cost,
        if (unitPrice != null) 'unit_price': unitPrice,
        'fueled_at': fueledAt.toIso8601String().split('T')[0],
        if (fuelType != null) 'fuel_type': fuelType,
        if (fuelStation != null) 'fuel_station': fuelStation,
        if (mileage != null) 'mileage': mileage,
        if (notes != null) 'notes': notes,
      };
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/fuel-records'),
        headers: headers,
        body: json.encode(body),
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _log('✅ Enregistrement ajouté avec succès');
        return FuelRecord.fromJson(data);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    }
  } catch (e) {
    _log('❌ Erreur lors de l\'ajout: $e');
    rethrow;
  }
}

/// Modifier un enregistrement de carburant
Future<FuelRecord> updateFuelRecord({
  required int busId,
  required int recordId,
  required double quantity,
  required double cost,
  double? unitPrice,
  required DateTime fueledAt,
  String? fuelType,
  String? fuelStation,
  double? mileage,
  String? notes,
  File? invoiceImage,
}) async {
  try {
    _log('✏️ Modification du carburant #$recordId...');
    
    final headers = await _getHeaders();
    
    // Similaire à addFuelRecord mais avec PUT
    // ... (même logique que add mais avec PUT et recordId dans l'URL)
    
  } catch (e) {
    _log('❌ Erreur lors de la modification: $e');
    rethrow;
  }
}
```

---

## 📦 Packages Requis

Ajoutez dans `pubspec.yaml`:

```yaml
dependencies:
  image_picker: ^1.0.4
  http: ^1.1.0
```

Puis exécutez:
```bash
flutter pub get
```

---

## 🔄 Structure à Répéter pour Autres Modules

Pour chaque module (Maintenance, Visites, Assurances, Pannes, Vidanges):

1. **Écran détails** (`XXX_detail_screen.dart`)
   - Afficher tous les champs
   - Boutons Modifier/Supprimer
   
2. **Formulaire** (`XXX_form_screen.dart`)
   - Tous les champs avec validation
   - Mode création/édition
   
3. **Navigation** (dans `bus_detail_screen.dart`)
   - `onTap` sur ListTile → écran détails
   - FAB → formulaire ajout
   
4. **APIs** (dans `bus_api_service.dart`)
   - GET (déjà fait)
   - POST pour ajouter
   - PUT pour modifier
   - DELETE pour supprimer

---

## 🎯 Ordre de Priorité

1. ✅ Carburant (en cours)
2. Maintenance
3. Visites Techniques
4. Pannes
5. Vidanges
6. Assurances

---

## 📝 Notes Importantes

- Tous les endpoints API doivent être préfixés par `/api`
- Format des dates: `YYYY-MM-DD` pour l'API
- Les tokens JWT sont gérés automatiquement par `AuthService`
- Utilisez `ref.refresh()` pour recharger les données après modifications
- Les images doivent être envoyées en `multipart/form-data`

---

## 🚀 Prochaines Étapes

1. Finaliser le module Carburant avec les 6 étapes ci-dessus
2. Tester le CRUD complet
3. Créer les écrans pour les autres modules en utilisant la même structure
4. Implémenter les endpoints API côté Laravel si manquants

---

**Le CRUD Carburant est à 80% terminé. Il reste juste à connecter les APIs et tester !**
