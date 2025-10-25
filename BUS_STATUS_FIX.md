# 🐛 PROBLÈME : 15 Bus Inactifs au lieu d'Actifs

## 🔍 Diagnostic

### Symptôme
- **Total de bus** : 15 ✅
- **Actifs** : 0 ❌
- **Inactifs** : 15 ❌

### Problème Identifié
L'API renvoie probablement le statut des bus comme **"disponible"** mais le code mobile attend **"actif"** ou le champ `active_buses` n'est pas correctement calculé côté serveur.

## 📊 Structure Actuelle

### Modèle Flutter (`bus_models.dart`)
```dart
class BusDashboardStats {
  @JsonKey(name: 'total_buses')
  final int totalBuses;
  
  @JsonKey(name: 'active_buses')  // ← Attend ce champ de l'API
  final int activeBuses;
  
  // ...
}
```

### Affichage (`bus_dashboard_screen.dart` ligne 152-158)
```dart
Row(
  children: [
    _buildQuickStat('Actifs', stats.activeBuses, Colors.green[300]!),
    _buildQuickStat(
      'Inactifs',
      stats.totalBuses - stats.activeBuses,  // ← Calcul
      Colors.orange[300]!,
    ),
  ],
)
```

### Statut Bus (`bus_models.dart` ligne 74)
```dart
final String? status;  // Peut être: "disponible", "en_service", "en_panne", etc.
```

## 🔧 Solutions Possibles

### Solution 1 : Vérifier l'API Laravel ✅ RECOMMANDÉ

Le problème est probablement côté serveur. L'API doit compter les bus avec le statut **"disponible"** comme actifs.

#### Fichier Laravel à Vérifier
`app/Http/Controllers/Api/BusController.php` (méthode `dashboard`)

#### Code Attendu
```php
public function dashboard()
{
    $stats = [
        'total_buses' => Bus::count(),
        'active_buses' => Bus::whereIn('status', ['disponible', 'en_service'])->count(),
        // OU
        'active_buses' => Bus::where('status', 'disponible')->count(),
        // ...
    ];
    
    return response()->json([
        'stats' => $stats,
        'recent_breakdowns' => // ...
    ]);
}
```

#### Vérification
1. Ouvrir le fichier Laravel
2. Chercher la méthode `dashboard` ou `getDashboard`
3. Vérifier comment `active_buses` est calculé
4. S'assurer qu'il compte les bus avec `status = 'disponible'`

### Solution 2 : Adapter le Modèle Flutter (Si l'API ne peut pas être modifiée)

Si l'API renvoie un champ différent (ex: `available_buses`), adapter le modèle :

```dart
@JsonKey(name: 'available_buses')  // ← Changer selon l'API
final int activeBuses;
```

### Solution 3 : Calculer Côté Flutter (Temporaire)

Si l'API ne renvoie pas `active_buses`, le calculer à partir de la liste des bus :

```dart
// Dans bus_provider.dart
final activeBuses = buses.where((bus) => 
  bus.status == 'disponible' || bus.status == 'en_service'
).length;
```

## 🧪 Test de l'API

### 1. Vérifier la Réponse API
```bash
# Tester l'endpoint dashboard
curl -X GET "https://votre-api.com/api/buses/dashboard" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Réponse Attendue
```json
{
  "stats": {
    "total_buses": 15,
    "active_buses": 15,  // ← Doit être 15 si tous sont disponibles
    "maintenance_needed": 0,
    "insurance_expiring": 0,
    "technical_visit_expiring": 0,
    "vidange_needed": 0
  },
  "recent_breakdowns": []
}
```

### 2. Vérifier les Statuts des Bus
```bash
# Lister tous les bus
curl -X GET "https://votre-api.com/api/buses" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Réponse Attendue
```json
{
  "data": [
    {
      "id": 1,
      "registration_number": "AB-1234-CD",
      "status": "disponible",  // ← Vérifier ce champ
      // ...
    },
    // ... 14 autres bus
  ]
}
```

## 📝 Valeurs Possibles du Statut

### Statuts Actifs (Comptés comme actifs)
- `disponible` ✅
- `en_service` ✅
- `en_route` ✅

### Statuts Inactifs (Comptés comme inactifs)
- `en_panne` ❌
- `en_maintenance` ❌
- `hors_service` ❌
- `retiré` ❌

## 🔍 Debugging

### 1. Ajouter des Logs Flutter
Dans `bus_provider.dart`, ajouter :

```dart
final dashboardAsync = await _apiService.getBusDashboard();
debugPrint('📊 Dashboard Stats:');
debugPrint('Total buses: ${dashboardAsync.stats.totalBuses}');
debugPrint('Active buses: ${dashboardAsync.stats.activeBuses}');
```

### 2. Vérifier la Console
Lancer l'app et observer les logs :
```
📊 Dashboard Stats:
Total buses: 15
Active buses: 0  ← Si 0, le problème est côté API
```

### 3. Inspecter la Réponse API
Dans `bus_api_service.dart`, ajouter :

```dart
final response = await _dio.get('/buses/dashboard');
debugPrint('🔍 API Response: ${response.data}');
```

## ✅ Solution Recommandée

### Étape 1 : Vérifier l'API Laravel
1. Ouvrir `app/Http/Controllers/Api/BusController.php`
2. Trouver la méthode `dashboard`
3. Vérifier le calcul de `active_buses`

### Étape 2 : Corriger le Calcul
```php
'active_buses' => Bus::where('status', 'disponible')->count(),
```

### Étape 3 : Tester
```bash
# Relancer le serveur Laravel
php artisan serve

# Tester l'endpoint
curl http://localhost:8000/api/buses/dashboard
```

### Étape 4 : Vérifier dans l'App
1. Relancer l'app Flutter
2. Aller dans "Gestion des Bus"
3. Vérifier : **15 Actifs, 0 Inactifs** ✅

## 📊 Résultat Attendu

### Avant ❌
```
Total de bus: 15
🟢 0 Actifs
🟠 15 Inactifs
```

### Après ✅
```
Total de bus: 15
🟢 15 Actifs
🟠 0 Inactifs
```

## 🚀 Actions Immédiates

1. **Vérifier l'API Laravel** : `BusController.php` → méthode `dashboard`
2. **Corriger le calcul** : `active_buses` doit compter les bus "disponible"
3. **Tester** : Relancer l'API et l'app
4. **Valider** : 15 Actifs, 0 Inactifs ✅

## 📝 Fichiers à Vérifier

### Laravel (Backend)
- `app/Http/Controllers/Api/BusController.php`
- `app/Models/Bus.php`

### Flutter (Mobile)
- `lib/models/bus_models.dart` (ligne 11)
- `lib/screens/bus/bus_dashboard_screen.dart` (ligne 152-158)
- `lib/providers/bus_provider.dart`

---

**Le problème est probablement côté API Laravel. Vérifiez comment `active_buses` est calculé ! 🔍**
