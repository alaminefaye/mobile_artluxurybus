# 🔧 IMPLÉMENTATION DES FILTRES CARBURANT

## ⚠️ ÉTAT ACTUEL

Le fichier `bus_detail_screen.dart` a une structure cassée suite aux éditions. Il faut le restaurer depuis Git ou le reconstruire.

## ✅ SOLUTION RAPIDE

### 1. Restaurer le Fichier Original
```bash
cd "/Users/mouhamadoulaminefaye/Desktop/PROJETS DEV/mobile_dev/artluxurybus"
git checkout lib/screens/bus/bus_detail_screen.dart
```

### 2. Appliquer les Corrections Proprement

Voici le code complet à appliquer :

#### A. Convertir en StatefulWidget (Lignes 8-20)
```dart
class BusDetailScreen extends ConsumerStatefulWidget {
  final int busId;

  const BusDetailScreen({super.key, required this.busId});

  @override
  ConsumerState<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends ConsumerState<BusDetailScreen> {
  String _selectedPeriod = 'Ce mois';
  String _selectedYear = '2025';

  @override
  Widget build(BuildContext context) {
    final busDetailsAsync = ref.watch(busDetailsProvider(widget.busId));
    // ... reste du code
  }
```

#### B. Remplacer Tous les `busId` par `widget.busId`

Dans toutes les méthodes de la classe `_BusDetailScreenState`, remplacer :
- `busId` → `widget.busId`

Exemples :
```dart
// Ligne ~194
final maintenanceAsync = ref.watch(maintenanceListProvider(widget.busId));

// Ligne ~248-249
final fuelHistoryAsync = ref.watch(fuelHistoryProvider(widget.busId));
final fuelStatsAsync = ref.watch(fuelStatsProvider(widget.busId));

// Ligne ~347
busId: widget.busId,

// Ligne ~374
builder: (context) => FuelRecordFormScreen(busId: widget.busId),

// Ligne ~380-381
ref.invalidate(fuelHistoryProvider(widget.busId));
ref.invalidate(fuelStatsProvider(widget.busId));

// Ligne ~394
final visitsAsync = ref.watch(technicalVisitsProvider(widget.busId));

// Ligne ~446
final insuranceAsync = ref.watch(insuranceHistoryProvider(widget.busId));

// Ligne ~524
final breakdownsState = ref.watch(breakdownsProvider(widget.busId));

// Ligne ~629
final vidangesState = ref.watch(vidangesProvider(widget.busId));

// Ligne ~881
onPressed: () => ref.refresh(busDetailsProvider(widget.busId)),
```

#### C. Implémenter les Callbacks des Filtres (Lignes ~255-275)

```dart
// Filtre Période
_buildFilterDropdown(
  'Période',
  ['Aujourd\'hui', 'Ce mois', 'Année'],
  _selectedPeriod,  // ← Utiliser la variable d'état
  (value) {
    if (value != null) {
      setState(() {
        _selectedPeriod = value;
      });
      // Rafraîchir les données
      ref.invalidate(fuelHistoryProvider(widget.busId));
      ref.invalidate(fuelStatsProvider(widget.busId));
    }
  },
),

// Filtre Année
_buildFilterDropdown(
  'Année',
  ['2025', '2024', '2023'],
  _selectedYear,  // ← Utiliser la variable d'état
  (value) {
    if (value != null) {
      setState(() {
        _selectedYear = value;
      });
      // Rafraîchir les données
      ref.invalidate(fuelHistoryProvider(widget.busId));
      ref.invalidate(fuelStatsProvider(widget.busId));
    }
  },
),
```

## 🔄 COMMANDES COMPLÈTES

### Étape 1 : Restaurer le Fichier
```bash
cd "/Users/mouhamadoulaminefaye/Desktop/PROJETS DEV/mobile_dev/artluxurybus"
git checkout lib/screens/bus/bus_detail_screen.dart
```

### Étape 2 : Vérifier que ça compile
```bash
flutter analyze lib/screens/bus/bus_detail_screen.dart
```

### Étape 3 : Appliquer les Modifications

Utilisez un éditeur de texte pour faire les 3 changements ci-dessus :
1. Convertir en StatefulWidget
2. Remplacer `busId` par `widget.busId`
3. Implémenter les callbacks

### Étape 4 : Tester
```bash
flutter run
```

## 📋 CHECKLIST

- [ ] Fichier restauré depuis Git
- [ ] Converti en ConsumerStatefulWidget
- [ ] Variables d'état ajoutées (_selectedPeriod, _selectedYear)
- [ ] Tous les `busId` remplacés par `widget.busId`
- [ ] Callbacks des filtres implémentés avec setState()
- [ ] Appels à ref.invalidate() ajoutés
- [ ] Code compile sans erreur
- [ ] App testée : les filtres changent les valeurs
- [ ] App testée : les données se rafraîchissent

## ⚠️ NOTE IMPORTANTE

**Les filtres vont maintenant changer les valeurs affichées dans les dropdowns**, mais **les données ne seront PAS réellement filtrées** car :

1. L'API Laravel ne supporte pas encore les paramètres de filtrage
2. Les providers ne passent pas les paramètres à l'API

### Pour un Filtrage Complet

Il faudrait :

#### 1. Modifier l'API Laravel
```php
// BusApiController.php
public function fuelHistory(Request $request, $busId) {
    $query = FuelRecord::where('bus_id', $busId);
    
    // Filtrer par période
    if ($request->has('period')) {
        switch ($request->period) {
            case 'Aujourd\'hui':
                $query->whereDate('fueled_at', today());
                break;
            case 'Ce mois':
                $query->whereMonth('fueled_at', now()->month)
                      ->whereYear('fueled_at', now()->year);
                break;
        }
    }
    
    // Filtrer par année
    if ($request->has('year')) {
        $query->whereYear('fueled_at', $request->year);
    }
    
    return $query->orderBy('fueled_at', 'desc')->paginate(15);
}
```

#### 2. Créer un Provider avec Paramètres
```dart
// bus_provider.dart
final fuelHistoryWithFiltersProvider = FutureProvider.family<PaginatedResponse<FuelRecord>, Map<String, dynamic>>((ref, params) async {
  final busId = params['busId'] as int;
  final period = params['period'] as String?;
  final year = params['year'] as String?;
  
  final service = ref.read(busApiServiceProvider);
  return await service.getFuelHistory(
    busId,
    period: period,
    year: year,
  );
});
```

#### 3. Utiliser le Nouveau Provider
```dart
Widget _buildFuelTab(WidgetRef ref) {
  final fuelHistoryAsync = ref.watch(fuelHistoryWithFiltersProvider({
    'busId': widget.busId,
    'period': _selectedPeriod,
    'year': _selectedYear,
  }));
  
  // ... reste du code
}
```

## 🎯 RÉSULTAT ATTENDU

### Avec les Modifications Actuelles
- ✅ Les dropdowns changent de valeur quand on sélectionne
- ✅ Les données se rafraîchissent (mais sans filtrage)
- ✅ L'UI fonctionne correctement

### Avec le Filtrage Complet (Optionnel)
- ✅ Les données sont réellement filtrées par période et année
- ✅ Les statistiques sont recalculées selon les filtres
- ✅ L'historique affiche uniquement les enregistrements filtrés

---

**Pour l'instant, restaurez le fichier et appliquez les 3 modifications de base ! 🔧**
