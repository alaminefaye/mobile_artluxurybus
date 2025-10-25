# ✅ Corrections Modèles - Assurance, Pannes, Vidanges

## Problème identifié

**Erreur** : `type 'Null' is not a subtype of type 'String' in type cast`

Les modèles Flutter ne correspondaient PAS aux migrations Laravel.

## Migrations Laravel (Source de vérité)

### 1. Insurance Records (`insurance_records`)
```php
$table->id();
$table->foreignId('bus_id')->constrained()->onDelete('cascade');
$table->string('policy_number');              // NON NULL
$table->string('insurance_company');          // NON NULL
$table->date('start_date');
$table->date('end_date');                     // PAS expiry_date
$table->decimal('cost', 10, 2);               // NON NULL, PAS premium
$table->string('document_photo')->nullable();
$table->text('notes')->nullable();
$table->boolean('is_notified')->default(false);
$table->timestamps();
```

### 2. Bus Breakdowns (`bus_breakdowns`)
```php
$table->id();
$table->foreignId('bus_id')->constrained('buses')->onDelete('cascade');
$table->integer('kilometrage')->nullable();
$table->text('reparation_effectuee');         // NON NULL
$table->date('date_panne');
$table->text('description_probleme');         // NON NULL
$table->text('diagnostic_mecanicien');        // NON NULL
$table->string('piece_remplacee')->nullable();
$table->decimal('prix_piece', 10, 2)->nullable();
$table->string('facture_photo')->nullable();
$table->text('notes_complementaires')->nullable();
$table->enum('statut_reparation', ['en_cours', 'terminee', 'en_attente_pieces'])->default('en_cours');
$table->foreignId('created_by')->constrained('users')->onDelete('cascade');
$table->timestamps();
```

### 3. Bus Vidanges (`bus_vidanges`)
```php
$table->id();
$table->foreignId('bus_id')->constrained('buses')->onDelete('cascade');
$table->date('last_vidange_date');            // NON NULL
$table->date('next_vidange_date');            // NON NULL
$table->text('notes')->nullable();
$table->unsignedBigInteger('created_by');     // NON NULL
$table->timestamps();
```

## Corrections appliquées

### 1. InsuranceRecord

**AVANT** (❌ Incorrect) :
```dart
@JsonKey(name: 'insurance_company')
final String? insuranceCompany;  // ❌ Nullable

@JsonKey(name: 'policy_number')
final String? policyNumber;      // ❌ Nullable

@JsonKey(name: 'expiry_date')    // ❌ Mauvais nom
final DateTime expiryDate;

@JsonKey(name: 'coverage_type')  // ❌ N'existe pas
final String? coverageType;

final double? premium;           // ❌ Mauvais nom + nullable
```

**APRÈS** (✅ Correct) :
```dart
@JsonKey(name: 'policy_number')
final String policyNumber;       // ✅ NON NULL

@JsonKey(name: 'insurance_company')
final String insuranceCompany;   // ✅ NON NULL

@JsonKey(name: 'end_date')       // ✅ Bon nom
final DateTime expiryDate;

final double cost;               // ✅ Bon nom + NON NULL

@JsonKey(name: 'document_photo')
final String? documentPhoto;     // ✅ Ajouté

@JsonKey(name: 'is_notified')
final bool isNotified;           // ✅ Ajouté

@JsonKey(name: 'updated_at')
final DateTime? updatedAt;       // ✅ Ajouté
```

### 2. BusBreakdown

**AVANT** (❌ Incorrect) :
```dart
final String? description;       // ❌ Nom simplifié
final String? severity;          // ❌ N'existe pas
final String? status;            // ❌ N'existe pas

@JsonKey(name: 'repair_cost')
final double? repairCost;        // ❌ Mauvais nom

@JsonKey(name: 'resolved_date')
final DateTime? resolvedDate;    // ❌ N'existe pas
```

**APRÈS** (✅ Correct) :
```dart
final int? kilometrage;

@JsonKey(name: 'reparation_effectuee')
final String reparationEffectuee;        // ✅ NON NULL

@JsonKey(name: 'date_panne')
final DateTime breakdownDate;

@JsonKey(name: 'description_probleme')
final String descriptionProbleme;        // ✅ NON NULL

@JsonKey(name: 'diagnostic_mecanicien')
final String diagnosticMecanicien;       // ✅ NON NULL

@JsonKey(name: 'piece_remplacee')
final String? pieceRemplacee;

@JsonKey(name: 'prix_piece')
final double? prixPiece;

@JsonKey(name: 'facture_photo')
final String? facturePhoto;

@JsonKey(name: 'notes_complementaires')
final String? notesComplementaires;

@JsonKey(name: 'statut_reparation')
final String statutReparation;           // ✅ NON NULL

@JsonKey(name: 'created_by')
final int createdBy;                     // ✅ NON NULL

@JsonKey(name: 'updated_at')
final DateTime? updatedAt;               // ✅ Ajouté
```

### 3. BusVidange

**AVANT** (❌ Incorrect) :
```dart
@JsonKey(name: 'vidange_date')
final DateTime? vidangeDate;             // ❌ Mauvais nom + nullable

@JsonKey(name: 'next_vidange_date')
final DateTime? nextVidangeDate;         // ❌ Nullable

@JsonKey(name: 'planned_date')
final DateTime? plannedDate;             // ❌ N'existe pas

final String? type;                      // ❌ N'existe pas
final double? cost;                      // ❌ N'existe pas
final String? serviceProvider;           // ❌ N'existe pas
final double? mileage;                   // ❌ N'existe pas
final DateTime? completedAt;             // ❌ N'existe pas
final String? completionNotes;           // ❌ N'existe pas
```

**APRÈS** (✅ Correct) :
```dart
@JsonKey(name: 'last_vidange_date')
final DateTime lastVidangeDate;          // ✅ Bon nom + NON NULL

@JsonKey(name: 'next_vidange_date')
final DateTime nextVidangeDate;          // ✅ NON NULL

final String? notes;

@JsonKey(name: 'created_by')
final int createdBy;                     // ✅ NON NULL

@JsonKey(name: 'updated_at')
final DateTime? updatedAt;               // ✅ Ajouté
```

## Étapes suivantes

### 1. Régénération des fichiers .g.dart ✅
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Corrections des écrans Flutter

Les écrans suivants doivent être corrigés :

#### A. `bus_detail_screen.dart`
- ❌ `insurance.coverageType` → ✅ Retirer (n'existe plus)
- ❌ `insurance.premium` → ✅ `insurance.cost`
- ❌ `breakdown.severity` → ✅ `breakdown.statutReparation`
- ❌ `breakdown.description` → ✅ `breakdown.descriptionProbleme`
- ❌ `breakdown.status` → ✅ `breakdown.statutReparation`
- ❌ `breakdown.repairCost` → ✅ `breakdown.prixPiece`
- ❌ `vidange.type` → ✅ Retirer (n'existe plus)
- ❌ `vidange.plannedDate` → ✅ `vidange.lastVidangeDate`
- ❌ `vidange.completedAt` → ✅ Retirer (n'existe plus)
- ❌ `vidange.cost` → ✅ Retirer (n'existe plus)

#### B. `insurance_form_screen.dart`
- ❌ `insurance.premium` → ✅ `insurance.cost`
- ❌ Champs nullable → ✅ Champs obligatoires

#### C. `breakdown_form_screen.dart`
- ❌ Anciens champs → ✅ Nouveaux champs de la migration

#### D. `vidange_form_screen.dart`
- ❌ `plannedDate`, `completedAt`, etc. → ✅ `lastVidangeDate`, `nextVidangeDate`

#### E. `bus_dashboard_screen.dart`
- ❌ `breakdown.severity`, `breakdown.description`, `breakdown.status` → ✅ Nouveaux champs

## Résumé des changements

### InsuranceRecord
| Ancien | Nouveau | Raison |
|--------|---------|--------|
| `insuranceCompany?` | `insuranceCompany` | NON NULL dans DB |
| `policyNumber?` | `policyNumber` | NON NULL dans DB |
| `expiry_date` | `end_date` | Nom correct |
| `premium?` | `cost` | Nom correct + NON NULL |
| - | `documentPhoto?` | Manquait |
| - | `isNotified` | Manquait |
| `coverageType?` | ❌ Retiré | N'existe pas dans DB |

### BusBreakdown
| Ancien | Nouveau | Raison |
|--------|---------|--------|
| `description?` | `descriptionProbleme` | Nom correct + NON NULL |
| `severity?` | ❌ Retiré | N'existe pas dans DB |
| `status?` | ❌ Retiré | N'existe pas dans DB |
| `repairCost?` | `prixPiece?` | Nom correct |
| `resolvedDate?` | ❌ Retiré | N'existe pas dans DB |
| - | `reparationEffectuee` | Manquait |
| - | `diagnosticMecanicien` | Manquait |
| - | `pieceRemplacee?` | Manquait |
| - | `facturePhoto?` | Manquait |
| - | `notesComplementaires?` | Manquait |
| - | `statutReparation` | Manquait |
| - | `createdBy` | Manquait |
| - | `kilometrage?` | Manquait |

### BusVidange
| Ancien | Nouveau | Raison |
|--------|---------|--------|
| `vidangeDate?` | ❌ Retiré | N'existe pas dans DB |
| `nextVidangeDate?` | `nextVidangeDate` | NON NULL |
| `plannedDate?` | ❌ Retiré | N'existe pas dans DB |
| `type?` | ❌ Retiré | N'existe pas dans DB |
| `cost?` | ❌ Retiré | N'existe pas dans DB |
| `serviceProvider?` | ❌ Retiré | N'existe pas dans DB |
| `mileage?` | ❌ Retiré | N'existe pas dans DB |
| `completedAt?` | ❌ Retiré | N'existe pas dans DB |
| `completionNotes?` | ❌ Retiré | N'existe pas dans DB |
| - | `lastVidangeDate` | Manquait |
| - | `createdBy` | Manquait |

## Principe appliqué

**RÈGLE D'OR** : Les modèles Flutter doivent correspondre EXACTEMENT aux migrations Laravel.

- ✅ Même nom de champ (snake_case en DB → camelCase en Dart)
- ✅ Même nullabilité (NULL en DB → `?` en Dart)
- ✅ Même type de données
- ✅ Pas de champs supplémentaires
- ✅ Pas de champs manquants

## Résultat attendu

Après régénération et corrections des écrans :
- ✅ Plus d'erreur "type 'Null' is not a subtype of type 'String'"
- ✅ Assurance affiche correctement
- ✅ Pannes affichent correctement
- ✅ Vidanges affichent correctement
- ✅ Tous les onglets fonctionnent
