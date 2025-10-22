# ⚠️ ACTION IMMEDIATE REQUISE ⚠️

## 🚨 VOUS DEVEZ REGENERER LES FICHIERS `.g.dart` 🚨

**Le hot reload/restart NE SUFFIT PAS** car les modèles utilisent `json_serializable`.

---

## 📋 ÉTAPE PAR ÉTAPE

### Option 1: Script automatique (RECOMMANDÉ)
```bash
cd ~/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
./regenerate_and_run.sh
```

### Option 2: Commandes manuelles
```bash
cd ~/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Option 3: Depuis Android Studio/VSCode
1. Ouvrir le terminal intégré
2. Exécuter:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
3. Relancer l'app avec le bouton Run

---

## ✅ Corrections appliquées (en attente de régénération)

### 1. **Traduction "available" → "disponible"**
- Status: ✅ CORRIGÉ dans le code
- Fichiers: `bus_detail_screen.dart`, `bus_list_screen.dart`

### 2. **Mapping `seat_count` → `capacity`**
- Status: ✅ CORRIGÉ dans le code
- Fichier: `bus_models.dart` ligne 71-72
- Le backend envoie: `"seat_count":43`
- Flutter lit maintenant correctement cette valeur

### 3. **Mapping FuelStats (stats carburant)**
- Status: ✅ CORRIGÉ dans le code
- Fichier: `bus_models.dart` lignes 242-248
- Changements:
  - `total_consumption` → `total_cost`
  - `average_consumption` → `average_cost` (nullable)
  - `last_month_consumption` → `last_month_cost`

### 4. **Mapping FuelRecord (enregistrements carburant)**
- Status: ✅ CORRIGÉ dans le code
- Fichier: `bus_models.dart` lignes 189-237
- Changements:
  - Retiré `totalCost` (n'existe pas dans l'API)
  - Ajouté `cost` (existe dans l'API)
  - Ajouté `invoice_photo`
  - Ajouté `fueled_at`
  - Tous les champs numériques sont maintenant nullable

### 5. **PaginatedResponse - `to` et `from` nullable**
- Status: ✅ CORRIGÉ dans le code
- Fichier: `bus_models.dart` ligne 545
- L'API renvoie `null` quand il n'y a pas de résultats

### 6. **Affichage des enregistrements de carburant**
- Status: ✅ CORRIGÉ dans le code
- Fichier: `bus_detail_screen.dart` lignes 304-316
- Utilise maintenant `fuel.cost` au lieu de `fuel.totalCost`
- Gère les valeurs nulles correctement

---

## 📊 Ce que vous verrez après régénération

### ✅ AVANT (avec erreurs)
```
[BusApiService] ❌ Erreur: type 'Null' is not a subtype of type 'num'
```

### ✅ APRÈS (sans erreurs)
```
[BusApiService] ✅ Stats carburant récupérées avec succès
[BusApiService] ✅ Historique carburant récupéré avec succès
```

### Affichage attendu:
- ✅ Badge "**Disponible**" en vert (pas "available")
- ✅ "**43 sièges**" affiché (si seat_count=43 dans la DB)
- ✅ Enregistrement carburant du bus Premium 3884 visible:
  - Date: 22/10/2025
  - Coût: 100,000 FCFA
  - Quantité: 0 L (à corriger dans la DB si nécessaire)

---

## 🐛 Dépannage

### Erreur: "flutter: command not found"
➡️ Flutter n'est pas dans votre PATH

**Solution**:
```bash
# Option 1: Ajouter Flutter au PATH (dans ~/.zshrc ou ~/.bashrc)
export PATH="$PATH:/path/to/flutter/bin"

# Option 2: Utiliser le chemin complet
/path/to/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs
```

### Les erreurs persistent après régénération
➡️ Vérifiez que les fichiers `.g.dart` ont bien été mis à jour

**Solution**:
```bash
# Lister les fichiers générés récemment
ls -lt lib/models/*.g.dart

# Forcer une régénération complète
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Quantité non spécifiée" s'affiche
➡️ La base de données a `quantity: 0` ou `null`

**Solution SQL** (côté Laravel):
```sql
UPDATE fuel_records 
SET quantity = 50 
WHERE quantity IS NULL OR quantity = 0;
```

---

## 📱 Structure des données corrigée

### Backend Laravel envoie:
```json
{
  "id": 2,
  "registration_number": "Premium 3884",
  "seat_count": 43,  ← Mappé vers "capacity"
  "status": "available",  ← Traduit en "Disponible"
  "fuel_records": [{
    "id": 1,
    "bus_id": 2,
    "cost": 100000,  ← Mappé vers "cost"
    "quantity": 0,  ← Nullable maintenant
    "fueled_at": "2025-10-22T02:57:00.000000Z",
    "invoice_photo": "fuel-invoices/xxx.jpg"
  }]
}
```

### Flutter reçoit correctement:
```dart
Bus(
  id: 2,
  registrationNumber: "Premium 3884",
  capacity: 43,  // ✅ Depuis seat_count
  status: "available",  // ✅ Affiché comme "Disponible"
  fuelRecords: [
    FuelRecord(
      id: 1,
      busId: 2,
      cost: 100000,  // ✅ Depuis cost
      quantity: 0,  // ✅ Nullable
      fueledAt: DateTime(2025, 10, 22, 2, 57),
      invoicePhoto: "fuel-invoices/xxx.jpg"
    )
  ]
)
```

---

## ⚡ Commande rapide (copier-coller)

```bash
cd ~/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus && flutter pub run build_runner build --delete-conflicting-outputs && flutter run
```

---

## 📞 Si ça ne marche toujours pas

1. **Vérifier les logs** après régénération:
   - Chercher `[BusApiService]` dans les logs
   - Il ne devrait plus y avoir d'erreurs "type 'Null' is not a subtype..."

2. **Vérifier la base de données**:
   ```sql
   SELECT id, registration_number, seat_count, status FROM buses;
   SELECT * FROM fuel_records WHERE bus_id = 2;
   ```

3. **Clean complet du projet**:
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   flutter run
   ```

---

## 🎯 Checklist finale

- [ ] Régénérer les fichiers `.g.dart` avec `build_runner`
- [ ] Relancer l'application
- [ ] Vérifier que "Disponible" s'affiche (pas "available")
- [ ] Vérifier que "43 sièges" s'affiche (ou le bon nombre)
- [ ] Vérifier qu'il n'y a plus d'erreurs dans les logs
- [ ] Vérifier que l'enregistrement carburant du bus #2 s'affiche

---

**🚀 N'oubliez pas: RÉGÉNÉRER LES FICHIERS est OBLIGATOIRE !**
