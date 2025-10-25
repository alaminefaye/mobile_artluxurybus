# 📊 ANALYSE DES MODÈLES - CRUD COMPLET

## 🔍 Modèles Analysés

### 1. TechnicalVisit (Visites Techniques)

**Champs requis pour création** :
- `bus_id` : int (fourni automatiquement)
- `visit_date` : DateTime ✅
- `expiry_date` : DateTime ✅
- `result` : String ✅ (ex: "Favorable", "Défavorable")

**Champs optionnels** :
- `visit_center` : String? (centre de visite)
- `cost` : double? (coût)
- `notes` : String?
- `certificate_number` : String? (numéro certificat)

**Formulaire à créer** :
```dart
- Date de visite (DatePicker)
- Date d'expiration (DatePicker)
- Résultat (Dropdown: Favorable/Défavorable)
- Centre de visite (TextField optionnel)
- Coût (TextField numérique optionnel)
- Numéro certificat (TextField optionnel)
- Notes (TextField multiline optionnel)
```

---

### 2. InsuranceRecord (Assurances)

**Champs requis pour création** :
- `bus_id` : int (fourni automatiquement)
- `insurance_company` : String ✅ (compagnie d'assurance)
- `policy_number` : String ✅ (numéro de police)
- `start_date` : DateTime ✅
- `expiry_date` : DateTime ✅
- `coverage_type` : String ✅ (type de couverture)
- `premium` : double ✅ (prime)

**Champs optionnels** :
- `notes` : String?

**Formulaire à créer** :
```dart
- Compagnie d'assurance (TextField)
- Numéro de police (TextField)
- Date de début (DatePicker)
- Date d'expiration (DatePicker)
- Type de couverture (Dropdown ou TextField)
- Prime (TextField numérique)
- Notes (TextField multiline optionnel)
```

---

### 3. BusBreakdown (Pannes)

**Champs requis pour création** :
- `bus_id` : int (fourni automatiquement)
- `description` : String ✅
- `breakdown_date` : DateTime ✅
- `severity` : String ✅ (low, medium, high)
- `status` : String ✅ (reported, in_progress, resolved)

**Champs optionnels** :
- `repair_cost` : double?
- `resolved_date` : DateTime?
- `notes` : String?

**Formulaire à créer** :
```dart
- Description (TextField multiline)
- Date de panne (DatePicker)
- Sévérité (Dropdown: Faible/Moyenne/Élevée)
- Statut (Dropdown: Signalée/En cours/Résolue)
- Coût de réparation (TextField numérique optionnel)
- Date de résolution (DatePicker optionnel)
- Notes (TextField multiline optionnel)
```

---

### 4. BusVidange (Vidanges)

**Champs requis pour création** :
- `bus_id` : int (fourni automatiquement)
- `type` : String ✅ (type de vidange)

**Champs optionnels** :
- `vidange_date` : DateTime? (date effectuée)
- `next_vidange_date` : DateTime? (prochaine vidange)
- `planned_date` : DateTime? (date planifiée)
- `cost` : double?
- `service_provider` : String? (prestataire)
- `mileage` : double? (kilométrage)
- `notes` : String?
- `completed_at` : DateTime?
- `completion_notes` : String?

**Formulaire à créer** :
```dart
- Type (Dropdown: Huile moteur/Huile boîte/Filtre/Complète)
- Date planifiée (DatePicker optionnel)
- Date effectuée (DatePicker optionnel)
- Prochaine vidange (DatePicker optionnel)
- Prestataire (TextField optionnel)
- Kilométrage (TextField numérique optionnel)
- Coût (TextField numérique optionnel)
- Notes (TextField multiline optionnel)
```

---

## 🎯 PLAN D'IMPLÉMENTATION

### Étape 1 : Service API (bus_api_service.dart)

#### Visites Techniques
```dart
Future<TechnicalVisit> addTechnicalVisit({
  required int busId,
  required DateTime visitDate,
  required DateTime expiryDate,
  required String result,
  String? visitCenter,
  double? cost,
  String? certificateNumber,
  String? notes,
})

Future<TechnicalVisit> updateTechnicalVisit({
  required int busId,
  required int visitId,
  required DateTime visitDate,
  required DateTime expiryDate,
  required String result,
  String? visitCenter,
  double? cost,
  String? certificateNumber,
  String? notes,
})

Future<void> deleteTechnicalVisit(int busId, int visitId)
```

#### Assurances
```dart
Future<InsuranceRecord> addInsurance({
  required int busId,
  required String insuranceCompany,
  required String policyNumber,
  required DateTime startDate,
  required DateTime expiryDate,
  required String coverageType,
  required double premium,
  String? notes,
})

Future<InsuranceRecord> updateInsurance({
  required int busId,
  required int insuranceId,
  required String insuranceCompany,
  required String policyNumber,
  required DateTime startDate,
  required DateTime expiryDate,
  required String coverageType,
  required double premium,
  String? notes,
})

Future<void> deleteInsurance(int busId, int insuranceId)
```

#### Pannes
```dart
Future<BusBreakdown> updateBreakdown({
  required int busId,
  required int breakdownId,
  required String description,
  required DateTime breakdownDate,
  required String severity,
  required String status,
  double? repairCost,
  DateTime? resolvedDate,
  String? notes,
})

Future<void> deleteBreakdown(int busId, int breakdownId)
```

#### Vidanges
```dart
Future<BusVidange> updateVidange({
  required int busId,
  required int vidangeId,
  required String type,
  DateTime? vidangeDate,
  DateTime? nextVidangeDate,
  DateTime? plannedDate,
  double? cost,
  String? serviceProvider,
  double? mileage,
  String? notes,
})

Future<void> deleteVidange(int busId, int vidangeId)
```

---

### Étape 2 : Formulaires Flutter

Créer 4 fichiers dans `lib/screens/bus/` :
1. `technical_visit_form_screen.dart`
2. `insurance_form_screen.dart`
3. `breakdown_form_screen.dart`
4. `vidange_form_screen.dart`

Chaque formulaire aura :
- Mode création ET édition
- Validation des champs
- DatePickers pour les dates
- Dropdowns pour les choix fixes
- Gestion des erreurs
- Bouton Enregistrer

---

### Étape 3 : Intégration dans bus_detail_screen.dart

Pour chaque onglet :
1. Ajouter bouton FAB (FloatingActionButton)
2. Ajouter actions sur chaque item (éditer/supprimer)
3. Gérer la navigation vers les formulaires
4. Rafraîchir la liste après création/modification/suppression

---

## 🚀 ORDRE D'IMPLÉMENTATION

1. ✅ **Pannes** (déjà 50% fait - addBreakdown existe)
2. ✅ **Vidanges** (déjà 50% fait - scheduleVidange existe)
3. ✅ **Visites Techniques** (à créer de zéro)
4. ✅ **Assurances** (à créer de zéro)

---

**Prêt à commencer l'implémentation ! 🎯**
