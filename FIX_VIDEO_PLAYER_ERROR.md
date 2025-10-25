# Résolution de l'erreur "No active player with ID 1"

## Problème

```
StateError (Bad state: No active player with ID 1.)
```

Cette erreur provient du package `video_player_android` qui est inclus comme dépendance de `video_player`, mais vous n'utilisez pas de vidéos dans votre application.

## Cause

Le package `video_player: ^2.9.2` était présent dans `pubspec.yaml` (ligne 78) avec le commentaire "Video playback for ads banner", mais :
- ❌ Aucun code n'utilise ce package
- ❌ Aucune bannière vidéo n'est implémentée
- ❌ Le package peut s'initialiser automatiquement et causer des erreurs

## Solution appliquée

✅ **Suppression de la dépendance `video_player`** du fichier `pubspec.yaml`

## Étapes pour résoudre

### 1. Nettoyer les dépendances

```bash
# Dans le dossier du projet
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus

# Nettoyer le cache
flutter clean

# Récupérer les dépendances
flutter pub get
```

### 2. Supprimer les fichiers de build

```bash
# Supprimer les builds Android
rm -rf android/build
rm -rf android/app/build

# Supprimer les builds iOS (si nécessaire)
rm -rf ios/Pods
rm -rf ios/.symlinks
```

### 3. Rebuild l'application

```bash
# Pour Android
flutter run

# Ou si vous avez des problèmes
flutter run --no-sound-null-safety
```

### 4. Vérifier que l'erreur a disparu

L'erreur `No active player with ID 1` ne devrait plus apparaître car le package `video_player` n'est plus installé.

## Si vous voulez utiliser des vidéos plus tard

Si vous décidez d'implémenter des bannières vidéo pour les publicités :

### 1. Réinstaller le package

```yaml
# Dans pubspec.yaml
dependencies:
  video_player: ^2.9.2
```

### 2. Initialiser correctement

```dart
import 'package:video_player/video_player.dart';

class VideoAdBanner extends StatefulWidget {
  final String videoUrl;
  
  const VideoAdBanner({required this.videoUrl, super.key});
  
  @override
  State<VideoAdBanner> createState() => _VideoAdBannerState();
}

class _VideoAdBannerState extends State<VideoAdBanner> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }
  
  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        _controller.play();
        _controller.setLooping(true);
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation vidéo: $e');
    }
  }
  
  @override
  void dispose() {
    _controller.dispose(); // IMPORTANT : Toujours dispose
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}
```

### 3. Points importants

- ✅ **Toujours appeler `dispose()`** sur le controller
- ✅ **Vérifier `mounted`** avant `setState()`
- ✅ **Gérer les erreurs** avec try-catch
- ✅ **Initialiser avant d'utiliser** le player

## Alternative : Utiliser des images pour les bannières

Si vous voulez des bannières publicitaires sans vidéo :

```dart
// Vous avez déjà cached_network_image
import 'package:cached_network_image/cached_network_image.dart';

Widget _buildImageAdBanner(String imageUrl) {
  return CachedNetworkImage(
    imageUrl: imageUrl,
    fit: BoxFit.cover,
    placeholder: (context, url) => const CircularProgressIndicator(),
    errorWidget: (context, url, error) => const Icon(Icons.error),
  );
}
```

## Packages actuellement installés pour les médias

✅ **cached_network_image** : Images en cache
✅ **flutter_cache_manager** : Gestion du cache
✅ **image_picker** : Sélection d'images

Ces packages sont suffisants pour gérer des bannières publicitaires avec images.

## Résumé

| Action | Statut |
|--------|--------|
| Suppression de `video_player` | ✅ Fait |
| Nettoyage requis | ⏳ À faire |
| Rebuild requis | ⏳ À faire |

## Commandes à exécuter

```bash
# 1. Nettoyer
flutter clean

# 2. Récupérer les dépendances
flutter pub get

# 3. Rebuild
flutter run
```

## Conclusion

L'erreur `No active player with ID 1` était causée par une dépendance inutilisée. Après avoir supprimé `video_player` et nettoyé le projet, l'erreur ne devrait plus apparaître.

Si vous avez besoin de bannières publicitaires, utilisez des **images** avec `cached_network_image` plutôt que des vidéos, c'est plus léger et plus rapide.
