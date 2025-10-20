# 📝 Guide d'utilisation du Logger - Art Luxury Bus

## 🎯 Objectif

Remplacer les `print()` par un système de logging professionnel qui respecte les bonnes pratiques Flutter.

## 📚 Utilisation

### Import
```dart
import '../utils/logger.dart';
```

### Niveaux de log disponibles

#### 1. **Info** - Informations générales
```dart
AppLogger.info('Utilisateur connecté avec succès');
AppLogger.info('Token FCM généré', tag: 'FCM');
```

#### 2. **Error** - Erreurs avec contexte
```dart
AppLogger.error('Erreur de connexion API', error: e);
AppLogger.error('Échec de l\'authentification', error: e, stackTrace: stackTrace);
```

#### 3. **Debug** - Debug uniquement (supprimé en production)
```dart
AppLogger.debug('Variable state: $state');
AppLogger.debug('User permissions: ${user.permissions}');
```

#### 4. **Warning** - Avertissements
```dart
AppLogger.warning('Token expiré, rechargement automatique');
AppLogger.warning('Connexion réseau instable');
```

## 🔍 Avantages vs print()

| Aspect | print() | AppLogger |
|--------|---------|-----------|
| **Production** | ❌ Affiché en prod | ✅ Contrôlé par niveau |
| **Contexte** | ❌ Message seul | ✅ Timestamp, niveau, app |
| **Erreurs** | ❌ Pas de stacktrace | ✅ Erreur + stacktrace |
| **Performance** | ❌ Toujours actif | ✅ Debug supprimé en prod |
| **Lint** | ❌ Warning lint | ✅ Conforme aux bonnes pratiques |

## 🚀 Migration depuis print()

### Avant (❌)
```dart
print('Erreur API: $e');
```

### Après (✅)
```dart
AppLogger.error('Erreur API', error: e);
```

## 📱 Visualisation des logs

### Dans le développement
- **VS Code** : Onglet Debug Console
- **Android Studio** : Onglet Dart Analysis
- **Terminal** : `flutter logs`

### Levels visibles
- **Debug** : Seulement en mode debug
- **Info/Warning/Error** : Toujours visibles

## 🔧 Bonnes pratiques

### 1. **Messages descriptifs**
```dart
// ❌ Mauvais
AppLogger.error('Erreur');

// ✅ Bon  
AppLogger.error('Erreur lors de la soumission du feedback', error: e);
```

### 2. **Utiliser les bons niveaux**
```dart
// Pour le debug temporaire
AppLogger.debug('Valeur calculée: $result');

// Pour les erreurs critiques
AppLogger.error('Échec de sauvegarde des données', error: e);

// Pour les informations importantes
AppLogger.info('Synchronisation terminée avec succès');
```

### 3. **Tags optionnels pour filtrer**
```dart
AppLogger.info('Token enregistré', tag: 'FCM');
AppLogger.error('Échec requête', error: e, tag: 'API');
```

Ce système remplace complètement `print()` et respecte les standards de l'industrie ! 🎉
