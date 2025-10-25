# Correction Mode Sombre - Cartes de Services et Bouton "En savoir plus"

## Problèmes identifiés

### 1. Cartes de services avec bordure blanche
Les cartes de services (Réserver, Mes Offres, Fidélité, etc.) avaient un fond blanc qui créait des bordures blanches éblouissantes en mode sombre.

### 2. Labels des services invisibles
Les labels des services (Réserver, Mes Offres, Gares, etc.) utilisaient `Colors.grey[800]` (gris très foncé) et étaient invisibles en mode sombre.

### 3. Bouton "En savoir plus" invisible
Le bouton "En savoir plus" sur les cartes de promotions avait un fond blanc avec du texte blanc, le rendant complètement invisible en mode sombre.

## Corrections appliquées

### 1. Cartes de services (`_buildServiceIcon`)

#### ❌ Avant
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,  // ❌ Toujours blanc
    borderRadius: BorderRadius.circular(16),
  ),
)
```

#### ✅ Après
```dart
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,  // ✅ S'adapte au thème
    borderRadius: BorderRadius.circular(16),
  ),
)
```

**Résultat** :
- Mode clair : Cartes blanches ✅
- Mode sombre : Cartes gris foncé (#1E1E1E) ✅

### 2. Labels des services (`_buildServiceIcon`)

#### ❌ Avant
```dart
Text(
  label,
  style: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.grey[800],  // ❌ Gris foncé invisible en mode sombre
  ),
)
```

#### ✅ Après
```dart
Text(
  label,
  style: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).textTheme.bodyLarge?.color,  // ✅ S'adapte au thème
  ),
)
```

**Résultat** :
- Mode clair : Labels gris foncé ✅
- Mode sombre : Labels blancs ✅

### 3. Bouton "En savoir plus" (`_buildPromotionCard`)

#### ❌ Avant
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,  // ❌ Fond blanc
  ),
  child: Row(
    children: [
      Text(
        'En savoir plus',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,  // ❌ Blanc en mode sombre
        ),
      ),
      Icon(
        Icons.arrow_forward_rounded,
        color: Theme.of(context).textTheme.bodyLarge?.color,  // ❌ Blanc en mode sombre
      ),
    ],
  ),
)
```

#### ✅ Après
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.9),  // ✅ Blanc semi-transparent
  ),
  child: const Row(
    children: [
      Text(
        'En savoir plus',
        style: TextStyle(
          color: Color(0xFF1A237E),  // ✅ Bleu marine (toujours visible)
        ),
      ),
      Icon(
        Icons.arrow_forward_rounded,
        color: Color(0xFF1A237E),  // ✅ Bleu marine (toujours visible)
      ),
    ],
  ),
)
```

**Résultat** :
- Mode clair : Bouton blanc avec texte bleu ✅
- Mode sombre : Bouton blanc avec texte bleu ✅

## Explication de la solution

### Cartes de services
Utilisation de `Theme.of(context).cardColor` qui s'adapte automatiquement :
- Mode clair : `#FFFFFF` (blanc)
- Mode sombre : `#1E1E1E` (gris foncé)

### Labels des services
Utilisation de `Theme.of(context).textTheme.bodyLarge?.color` qui s'adapte automatiquement :
- Mode clair : Gris foncé/noir
- Mode sombre : Blanc

### Bouton "En savoir plus"
Le bouton garde un fond blanc (car il est sur un fond coloré - violet/orange) mais utilise une couleur de texte fixe (bleu marine #1A237E) qui est toujours visible sur fond blanc, peu importe le thème.

## Éléments conservés

### Couleurs qui ne changent pas
- ✅ Icônes colorées des services (rouge, bleu, violet, etc.)
- ✅ Dégradés des cartes de promotions
- ✅ Badge "NOUVEAU"
- ✅ Couleur du bouton "En savoir plus" (bleu marine)

### Éléments qui s'adaptent
- ✅ Background des cartes de services
- ✅ Labels des services
- ✅ Tous les textes

## Test de validation

### Checklist
- [x] Cartes de services visibles en mode clair
- [x] Cartes de services visibles en mode sombre (pas de bordure blanche)
- [x] Labels des services visibles en mode clair
- [x] Labels des services visibles en mode sombre (texte blanc)
- [x] Bouton "En savoir plus" visible en mode clair
- [x] Bouton "En savoir plus" visible en mode sombre
- [x] Icônes colorées conservées
- [x] Dégradés des promotions conservés
- [x] Transition fluide entre modes

### Commande de test
```bash
# Lancer l'app
flutter run

# Test
1. Aller dans l'onglet Accueil
2. Vérifier les cartes de services (Réserver, Mes Offres, etc.)
3. Scroller vers les "Offres Spéciales"
4. Vérifier le bouton "En savoir plus" sur les cartes
5. Activer le mode sombre (Profil → Apparence → Mode Sombre)
6. Revenir à l'Accueil
7. Vérifier que les cartes n'ont plus de bordure blanche
8. Vérifier que le bouton "En savoir plus" est visible (texte bleu)
```

## Résumé des changements

| Élément | Avant | Après | Résultat |
|---------|-------|-------|----------|
| Cartes services | `Colors.white` | `Theme.of(context).cardColor` | S'adapte au thème |
| Labels services | `Colors.grey[800]` | `Theme.of(context).textTheme.bodyLarge?.color` | S'adapte au thème |
| Bouton fond | `Colors.white` | `Colors.white.withValues(alpha: 0.9)` | Blanc semi-transparent |
| Bouton texte | `Theme.of(context).textTheme` | `Color(0xFF1A237E)` | Toujours visible |

## Fichiers modifiés

- `lib/screens/home_page.dart`
  - Fonction `_buildServiceIcon` (ligne ~979 et ~1026)
  - Fonction `_buildPromotionCard` (ligne ~1210)

## Conclusion

Les cartes de services, leurs labels et le bouton "En savoir plus" sont maintenant parfaitement visibles en mode sombre :
- ✅ Pas de bordure blanche éblouissante
- ✅ Labels des services visibles (blanc en mode sombre)
- ✅ Bouton "En savoir plus" toujours visible
- ✅ Conservation de l'identité visuelle
- ✅ Transition fluide entre modes
