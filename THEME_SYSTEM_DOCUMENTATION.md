# Système de Thème - Art Luxury Bus

## Vue d'ensemble

L'application Art Luxury Bus dispose maintenant d'un système complet de gestion des thèmes avec trois modes :
- **Mode Clair** : Interface lumineuse pour une utilisation en journée
- **Mode Sombre** : Interface sombre pour économiser la batterie et réduire la fatigue oculaire
- **Mode Système** : S'adapte automatiquement aux paramètres de l'appareil

## Architecture

### 1. Fichiers créés/modifiés

#### Thème (`lib/theme/app_theme.dart`)
- ✅ **lightTheme** : Thème clair complet
- ✅ **darkTheme** : Thème sombre complet avec couleurs adaptées
- Couleurs cohérentes : Bleu marine (`#1A237E`) et Orange beige (`#F1BD92`)

#### Provider (`lib/providers/theme_provider.dart`)
- **ThemeMode enum** : light, dark, system
- **ThemeModeNotifier** : Gestion de l'état du thème
- **themeModeProvider** : Provider Riverpod pour le mode de thème
- **isDarkModeProvider** : Provider pour savoir si le mode sombre est actif
- Sauvegarde automatique dans **SharedPreferences**

#### Écran de paramètres (`lib/screens/theme_settings_screen.dart`)
- Interface moderne et intuitive
- 3 options de thème avec descriptions
- Aperçu en temps réel
- Indicateur visuel de sélection

#### Main (`lib/main.dart`)
- Intégration du provider de thème
- Configuration `theme`, `darkTheme` et `themeMode`
- Support automatique du mode système

#### HomePage (`lib/screens/home_page.dart`)
- Ajout de l'option "Apparence" dans les préférences
- Navigation vers l'écran de paramètres de thème

## Fonctionnalités

### 1. Changement de thème
```dart
// Changer le thème
final themeModeNotifier = ref.read(themeModeProvider.notifier);
themeModeNotifier.setThemeMode(ThemeMode.dark);
```

### 2. Vérifier le thème actuel
```dart
// Obtenir le mode de thème
final themeMode = ref.watch(themeModeProvider);

// Savoir si le mode sombre est actif
final isDark = ref.watch(isDarkModeProvider);
```

### 3. Persistance
Les préférences de thème sont automatiquement sauvegardées dans SharedPreferences et restaurées au démarrage de l'application.

## Couleurs du thème sombre

### Couleurs principales
- **Background** : `#121212` (Noir profond)
- **Surface** : `#1E1E1E` (Gris foncé)
- **Cards** : `#1E1E1E` (Gris foncé)
- **Primary** : `#1A237E` (Bleu marine - conservé)
- **Secondary** : `#F1BD92` (Orange beige - conservé)

### Couleurs de texte
- **Titre** : `#FFFFFF` (Blanc)
- **Corps** : `#FFFFFF` (Blanc)
- **Secondaire** : `#B0B0B0` (Gris clair)
- **Hint** : `#707070` (Gris moyen)

### Couleurs d'interface
- **Divider** : `#3C3C3C` (Gris moyen)
- **Input Background** : `#2C2C2C` (Gris foncé)
- **Border** : `#3C3C3C` (Gris moyen)

## Navigation

### Accès aux paramètres de thème
1. Ouvrir l'application
2. Aller dans l'onglet **Profil**
3. Section **Préférences**
4. Cliquer sur **Apparence**
5. Sélectionner le mode souhaité

## Avantages

### Mode Clair
- ✅ Meilleure lisibilité en plein jour
- ✅ Interface familière et professionnelle
- ✅ Contraste optimal pour la lecture

### Mode Sombre
- ✅ Réduit la fatigue oculaire la nuit
- ✅ Économise la batterie (écrans OLED/AMOLED)
- ✅ Interface moderne et élégante
- ✅ Moins de lumière bleue

### Mode Système
- ✅ S'adapte automatiquement à l'heure
- ✅ Cohérence avec les autres applications
- ✅ Pas besoin de changer manuellement

## Compatibilité

- ✅ **Android** : Fonctionne sur toutes les versions
- ✅ **iOS** : Fonctionne sur toutes les versions
- ✅ **Material 3** : Design moderne et cohérent
- ✅ **Persistance** : Préférences sauvegardées

## Tests

### Test manuel
1. Changer le thème dans les paramètres
2. Vérifier que l'interface change immédiatement
3. Redémarrer l'application
4. Vérifier que le thème est conservé

### Test du mode système
1. Sélectionner "Mode Système"
2. Changer le thème de l'appareil (Paramètres système)
3. Vérifier que l'app s'adapte automatiquement

## Personnalisation future

Pour ajouter un nouveau thème ou modifier les couleurs :

1. Modifier `lib/theme/app_theme.dart`
2. Ajuster les couleurs dans `lightTheme` ou `darkTheme`
3. Les changements s'appliquent automatiquement

## Résultat

✅ **3 modes de thème** : Clair, Sombre, Système
✅ **Persistance** : Préférences sauvegardées
✅ **Interface moderne** : Écran de paramètres élégant
✅ **Changement instantané** : Pas besoin de redémarrer
✅ **Cohérence** : Design uniforme dans toute l'app
✅ **Accessibilité** : Meilleure expérience utilisateur
