# Corrections apportées au module Bus

## Date: 22 Octobre 2025

### Problèmes identifiés et corrigés

#### 1. Traduction du statut "available" → "disponible"
**Problème**: Le statut "available" s'affichait en anglais au lieu de "disponible" en français.

**Fichiers modifiés**:
- `lib/screens/bus/bus_detail_screen.dart` (ligne 781-782)
- `lib/screens/bus/bus_list_screen.dart` (ligne 487-488)

**Solution**: Ajout du cas `'available'` dans les méthodes `_getStatusLabel()` pour retourner "Disponible".

```dart
case 'available':
  return 'Disponible';
```

#### 2. Couleur du badge pour le statut "available"
**Problème**: Le statut "available" n'avait pas de couleur définie.

**Fichier modifié**: 
- `lib/screens/bus/bus_list_screen.dart` (ligne 469-470)

**Solution**: Ajout du cas `'available'` pour utiliser la couleur verte (comme 'active').

```dart
case 'active':
case 'available':
  return Colors.green;
```

#### 3. Affichage de la capacité du bus
**Problème**: La capacité s'affichait même quand elle était égale à 0 ou null, affichant "0 places".

**Fichier modifié**:
- `lib/screens/bus/bus_detail_screen.dart` (ligne 155-156)

**Solution**: Ajout d'une condition pour n'afficher la capacité que si elle est non nulle ET supérieure à 0.

```dart
if (bus.capacity != null && bus.capacity! > 0) 
  _InfoRow('Capacité', '${bus.capacity} places'),
```

#### 4. Logs de debug pour le chargement des données
**Problème**: Pas assez de logs pour comprendre pourquoi les données ne sont pas reçues.

**Fichier modifié**:
- `lib/services/bus_api_service.dart` (lignes 154, 220-221, 249)

**Solution**: Ajout de logs détaillés pour voir les réponses de l'API:
- Log du body complet de la réponse
- Log du nombre d'items dans les listes paginées
- Ces logs aideront à debugger les problèmes de données

```dart
_log('Response body: ${response.body}');
_log('Data items count: ${data['data']?.length ?? 0}');
```

### Points à vérifier côté backend

Si les données ne s'affichent toujours pas, vérifiez:

1. **Les endpoints de l'API** retournent bien des données pour le bus #3883:
   - `/api/buses/3883` - détails du bus
   - `/api/buses/3883/fuel-history` - historique carburant
   - `/api/buses/3883/fuel-stats` - statistiques carburant

2. **Le format de réponse** doit correspondre aux modèles Flutter:
   ```json
   {
     "id": 3883,
     "registration_number": "Premium 3883",
     "brand": "Mercedes",
     "model": "Sprinter",
     "capacity": 20,
     "status": "available",
     ...
   }
   ```

3. **Les données de test** dans la base de données:
   - Vérifier que le bus Premium 3883 a bien des enregistrements de carburant
   - Vérifier que la capacité du bus est renseignée

### Comment tester

1. **Relancer l'application** Flutter:
   ```bash
   cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
   flutter run
   ```

2. **Vérifier les logs** dans la console pour voir les réponses de l'API

3. **Tester l'affichage**:
   - Le badge de statut doit afficher "Disponible" (en vert)
   - La capacité ne doit s'afficher que si elle est > 0
   - Les données du carburant devraient apparaître si elles existent dans le backend

#### 5. Mapping du champ capacité (seat_count → capacity)
**Problème**: Le backend Laravel utilise `seat_count` mais le modèle Flutter cherchait `capacity`.

**Fichier modifié**:
- `lib/models/bus_models.dart` (ligne 71-72)

**Solution**: Ajout du mapping JSON pour lier `seat_count` de l'API à `capacity` dans Flutter.

```dart
@JsonKey(name: 'seat_count')
final int? capacity;
```

**ACTION REQUISE**: Vous devez régénérer les fichiers de sérialisation JSON:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Prochaines étapes si le problème persiste

Si après ces corrections, vous ne voyez toujours pas de données:

1. **Régénérer les fichiers générés**: Exécutez `flutter pub run build_runner build --delete-conflicting-outputs`

2. **Vérifier la base de données**: Assurez-vous que `seat_count` a des valeurs dans la table `buses`
   ```sql
   SELECT id, registration_number, seat_count, status FROM buses LIMIT 10;
   ```

3. **Vérifier la connexion API**: Assurez-vous que l'app se connecte bien à `https://gestion-compagny.universaltechnologiesafrica.com/api`

4. **Vérifier l'authentification**: Le token JWT est peut-être expiré

5. **Consulter les logs Flutter**: Recherchez les messages préfixés par `[BusApiService]`

6. **Tester l'API directement**: Utilisez Postman ou curl pour vérifier que l'API retourne des données

7. **Vérifier le backend Laravel**: Assurez-vous que les contrôleurs retournent les bonnes données avec les relations chargées
