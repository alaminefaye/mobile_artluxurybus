# 🔧 FIX: Erreur "type 'String' is not a subtype of type 'num'"

## ❌ Erreur Actuelle

```
I/flutter ( 4494): [BusApiService] ❌ Erreur lors de l'ajout de la patente: 
type 'String' is not a subtype of type 'num' in type cast
```

## ✅ Solution Appliquée

Nous avons ajouté un **convertisseur personnalisé** qui accepte `cost` comme **string OU number**.

### Fichiers Modifiés

#### 1. `lib/models/bus_models.dart`

Ajout du convertisseur `_costFromJson` :

```dart
@JsonKey(fromJson: _costFromJson)
final double cost;

// Convertisseur pour le champ cost (gère string ou number)
static double _costFromJson(dynamic value) {
  if (value is num) {
    return value.toDouble();
  } else if (value is String) {
    return double.parse(value);
  }
  return 0.0;
}
```

#### 2. `lib/models/bus_models.g.dart`

Utilisation du convertisseur dans `fromJson` :

```dart
Patent _$PatentFromJson(Map<String, dynamic> json) => Patent(
  // ...
  cost: Patent._costFromJson(json['cost']),  // ✅ Utilise le convertisseur
  // ...
);
```

#### 3. `lib/screens/bus/patent_form_screen.dart`

Ajout du bouton pour téléverser un document :

```dart
OutlinedButton.icon(
  onPressed: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de téléversement à venir'),
        duration: Duration(seconds: 2),
      ),
    );
  },
  icon: const Icon(Icons.upload_file),
  label: const Text('Téléverser un document (PDF, Image)'),
)
```

---

## 🚀 ÉTAPES POUR APPLIQUER LE FIX

### Option 1: Hot Restart (RECOMMANDÉ)

Dans votre IDE, faites un **Hot Restart** au lieu d'un simple Hot Reload :

1. **VS Code** : 
   - Appuyez sur `Cmd+Shift+F5` (Mac) ou `Ctrl+Shift+F5` (Windows/Linux)
   - OU cliquez sur l'icône "Restart" dans la barre de debug

2. **Android Studio** :
   - Cliquez sur le bouton "Hot Restart" (icône avec flèche circulaire verte)
   - OU appuyez sur `Cmd+\` (Mac) ou `Ctrl+\` (Windows/Linux)

### Option 2: Relancer l'Application

Si le Hot Restart ne fonctionne pas :

1. **Arrêtez l'application** (bouton Stop rouge)
2. **Relancez-la** avec `flutter run` ou F5

### Option 3: Rebuild Complet (si nécessaire)

Si les options précédentes ne fonctionnent pas :

```bash
# Nettoyer le build
flutter clean

# Récupérer les dépendances
flutter pub get

# Relancer l'app
flutter run
```

---

## 🧪 TEST DE VALIDATION

Après le restart, testez l'ajout d'une patente :

1. Ouvrez **Gestion Bus** → Sélectionnez un bus
2. Allez dans l'onglet **Patentes**
3. Cliquez sur le bouton **+** (Ajouter)
4. Remplissez le formulaire :
   - **Numéro** : `PAT-2025-TEST`
   - **Date d'émission** : `26/10/2025`
   - **Date d'expiration** : `26/10/2026`
   - **Coût** : `150000`
   - **Notes** : `Test après correction`
5. Cliquez sur **Ajouter**

### ✅ Résultat Attendu

```
I/flutter: [BusApiService] ✅ Patente ajoutée avec succès
```

### ❌ Si l'erreur persiste

Vérifiez les logs pour voir si le message d'erreur a changé. Si c'est toujours la même erreur, faites un rebuild complet (Option 3).

---

## 📋 POURQUOI ÇA ARRIVE ?

Le serveur Laravel retourne le champ `cost` comme une **string** :

```json
{
  "cost": "150000"  // ❌ String au lieu de number
}
```

Au lieu de :

```json
{
  "cost": 150000  // ✅ Number
}
```

Notre convertisseur gère maintenant **les deux cas** automatiquement.

---

## 🔍 VÉRIFICATION BACKEND (Optionnel)

Si vous voulez corriger le backend Laravel pour qu'il retourne un number :

### Dans le Modèle `Patent.php`

Ajoutez un cast :

```php
protected $casts = [
    'cost' => 'float',
    'issue_date' => 'datetime',
    'expiry_date' => 'datetime',
];
```

Cela garantira que `cost` est toujours retourné comme un nombre.

---

## 📝 RÉSUMÉ

- ✅ Convertisseur `_costFromJson` ajouté
- ✅ Bouton "Téléverser un document" ajouté
- ✅ Fichiers modifiés : `bus_models.dart`, `bus_models.g.dart`, `patent_form_screen.dart`
- ⚠️ **ACTION REQUISE** : Faire un **Hot Restart** pour appliquer les changements

---

**Date** : 26 octobre 2025  
**Statut** : ✅ Code corrigé - Restart requis
