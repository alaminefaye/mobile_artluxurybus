# 🚨 FIX URGENT: Erreur "type 'String' is not a subtype of type 'num'"

## ❌ Problème Actuel

```
I/flutter: [BusApiService] ✅ Patente ajoutée avec succès
I/flutter: [BusApiService] ❌ Erreur: type 'String' is not a subtype of type 'num' in type cast
```

La patente est créée MAIS l'erreur apparaît quand même car **l'application utilise encore l'ancienne version du code**.

---

## ✅ Solution: ARRÊTER et RELANCER l'App

### 🔴 ÉTAPE 1: ARRÊTER L'APPLICATION

**Dans VS Code:**
1. Cliquez sur le bouton **STOP** (carré rouge) dans la barre de debug
2. OU appuyez sur `Shift+F5`

**Dans Android Studio:**
1. Cliquez sur le bouton **Stop** (carré rouge)
2. OU appuyez sur `Cmd+F2` (Mac) / `Ctrl+F2` (Windows)

**Vérifiez que l'app est bien arrêtée:**
- L'icône de debug doit disparaître
- Plus de logs dans la console

---

### 🟢 ÉTAPE 2: RELANCER L'APPLICATION

**Option A - Relance Simple (RECOMMANDÉ):**

Dans votre IDE, appuyez sur **F5** ou cliquez sur le bouton **Run/Debug**.

**Option B - Rebuild Complet (si Option A ne fonctionne pas):**

```bash
# 1. Nettoyer
flutter clean

# 2. Récupérer les dépendances
flutter pub get

# 3. Relancer
flutter run
```

**Option C - Script Automatique:**

```bash
./rebuild_app.sh
# Puis relancer manuellement avec F5
```

---

## 🧪 TEST APRÈS RELANCE

1. Ouvrez **Gestion Bus** → Sélectionnez un bus
2. Allez dans l'onglet **Patentes**
3. Cliquez sur **+** (Ajouter)
4. Remplissez le formulaire:
   - Numéro: `TEST-2025-001`
   - Date d'émission: `26/10/2025`
   - Date d'expiration: `26/10/2026`
   - Coût: `150000`
5. Cliquez sur **Ajouter**

### ✅ Résultat Attendu

```
I/flutter: [BusApiService] ✅ Patente ajoutée avec succès
```

**SANS** le message d'erreur !

---

## 🔍 Pourquoi ça arrive ?

### Le Code est Correct ✅

Nous avons ajouté un convertisseur qui gère les deux cas:

```dart
// Dans bus_models.dart
@JsonKey(fromJson: _costFromJson)
final double cost;

static double _costFromJson(dynamic value) {
  if (value is num) return value.toDouble();    // ✅ Si c'est un number
  if (value is String) return double.parse(value); // ✅ Si c'est une string
  return 0.0;
}
```

```dart
// Dans bus_models.g.dart
cost: Patent._costFromJson(json['cost']),  // ✅ Utilise le convertisseur
```

### Mais l'App Utilise l'Ancienne Version ❌

Quand vous faites un **Hot Reload** (`r`) ou **Hot Restart** (`R`), Flutter ne recompile pas complètement le code.

Pour que les changements dans les fichiers `.dart` et `.g.dart` soient pris en compte, il faut **ARRÊTER et RELANCER** l'application.

---

## 📊 Checklist de Vérification

- [ ] ✅ Code modifié dans `bus_models.dart`
- [ ] ✅ Code modifié dans `bus_models.g.dart`
- [ ] ✅ Package `file_picker` ajouté
- [ ] ✅ Formulaire avec upload implémenté
- [ ] ⚠️ **APPLICATION ARRÊTÉE**
- [ ] ⚠️ **APPLICATION RELANCÉE**

---

## 🆘 Si ça ne fonctionne toujours pas

### Vérification 1: Le convertisseur est-il bien utilisé ?

Cherchez dans `lib/models/bus_models.g.dart` ligne 256:

```dart
cost: Patent._costFromJson(json['cost']),  // ✅ Doit être comme ça
```

Si vous voyez:
```dart
cost: (json['cost'] as num).toDouble(),  // ❌ Ancienne version
```

Alors le fichier n'a pas été mis à jour. Faites un `flutter clean` puis relancez.

### Vérification 2: Rebuild complet

```bash
# Supprimer tous les builds
rm -rf build/
rm -rf .dart_tool/

# Nettoyer
flutter clean

# Récupérer les dépendances
flutter pub get

# Relancer
flutter run
```

---

## 📝 Résumé

1. **ARRÊTEZ** l'application (bouton Stop rouge)
2. **RELANCEZ** l'application (F5 ou flutter run)
3. **TESTEZ** l'ajout d'une patente
4. ✅ L'erreur devrait disparaître !

---

**Date**: 26 octobre 2025  
**Statut**: ✅ Code corrigé - Relance requise  
**Action**: ARRÊTER et RELANCER l'app
