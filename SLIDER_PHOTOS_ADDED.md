# ✨ Slider de Photos Ajouté

## 🎯 Objectif

Ajouter un **carrousel de photos** avant la section "Nos Services" pour présenter visuellement l'entreprise.

## 📦 Package Ajouté

**`carousel_slider: ^5.0.0`** dans `pubspec.yaml`

## 🎨 Design du Slider

### Caractéristiques
- **Hauteur** : 200px
- **Auto-play** : Défilement automatique toutes les 4 secondes
- **Animation** : Transition fluide (800ms)
- **Effet** : Carte centrale agrandie
- **Ombres** : Ombres portées pour la profondeur
- **Overlay** : Dégradé noir en bas pour le texte

### Contenu des Slides

4 slides avec :
1. **Bus Premium** - "Confort et élégance"
2. **Intérieur Luxueux** - "Sièges spacieux et climatisés"
3. **Service 5 Étoiles** - "Personnel qualifié et accueillant"
4. **Sécurité Maximale** - "Véhicules régulièrement entretenus"

### Indicateurs
- **Points** : En bas du slider
- **Actif** : Barre bleue (24px)
- **Inactif** : Points gris (8px)
- **Animation** : Transition fluide

## 📱 Structure Visuelle

```
┌─────────────────────────────────┐
│  🚌 Art Luxury Bus              │ ← En-tête
├─────────────────────────────────┤
│ [📞] [✉️] [🌐]                  │ ← Contacts
├─────────────────────────────────┤
│ ┌───────────────────────────┐   │
│ │  [Photo Bus]              │   │
│ │  Bus Premium              │   │ ← SLIDER (NOUVEAU)
│ │  Confort et élégance      │   │
│ └───────────────────────────┘   │
│      ● ━ ○ ○                    │ ← Indicateurs
├─────────────────────────────────┤
│ ⭐ Nos Services                 │ ← Services
└─────────────────────────────────┘
```

## 🎨 Éléments Visuels

### 1. Image
- **Source** : `assets/images/12.png`
- **Fit** : Cover (remplit toute la carte)
- **Fallback** : Dégradé bleu-orange avec icône bus

### 2. Overlay
- **Dégradé** : Transparent → Noir (70%)
- **Position** : Du haut vers le bas
- **But** : Rendre le texte lisible

### 3. Texte
- **Position** : En bas à gauche
- **Titre** : Blanc, 20px, bold
- **Description** : Blanc 70%, 14px
- **Padding** : 20px

### 4. Carte
- **Border-radius** : 20px
- **Ombre** : Noire 20%, blur 10, offset (0,5)
- **Margin** : 5px horizontal

### 5. Indicateurs
- **Actif** : Barre bleue 24x8px
- **Inactif** : Point gris 8x8px
- **Spacing** : 4px entre chaque
- **Position** : Centré sous le slider

## 🔧 Modifications Appliquées

### 1. pubspec.yaml
```yaml
# Carousel
carousel_slider: ^5.0.0
```

### 2. company_info_screen.dart

#### Imports
```dart
import 'package:carousel_slider/carousel_slider.dart';
```

#### Classe
```dart
class CompanyInfoScreen extends StatefulWidget {
  // ...
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  int _currentSlide = 0;
  // ...
}
```

#### Méthode _buildPhotoSlider
- **Lignes** : 218-373
- **Slides** : 4 cartes avec images et textes
- **Options** : Auto-play, animation, indicateurs

## 📸 Personnalisation

### Changer les Images

Modifiez dans `_buildPhotoSlider` (ligne 220-241) :

```dart
final List<Map<String, String>> slides = [
  {
    'image': 'assets/images/bus1.jpg',  // ← Votre image
    'title': 'Votre Titre',
    'description': 'Votre description',
  },
  // Ajoutez plus de slides...
];
```

### Changer la Vitesse

Ligne 249 :
```dart
autoPlayInterval: const Duration(seconds: 4),  // ← Changez ici
```

### Changer la Hauteur

Ligne 247 :
```dart
height: 200,  // ← Changez ici
```

### Changer le Nombre de Slides Visibles

Ligne 253 :
```dart
viewportFraction: 0.9,  // 0.9 = 90% de l'écran
```

## 🧪 Test

### 1. Installer le package
```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter pub get
```

### 2. Lancer l'app
```bash
flutter run
```

### 3. Tester le slider
1. **Cliquer** : Bouton "Info" sur la page d'accueil
2. **Observer** : Slider après les 3 boutons de contact ✅
3. **Attendre** : Le slider défile automatiquement ✅
4. **Swiper** : Glisser pour changer de slide ✅
5. **Indicateurs** : Points en bas changent ✅

### 4. Vérifier les animations
- **Auto-play** : Défilement toutes les 4 secondes ✅
- **Transition** : Animation fluide ✅
- **Effet zoom** : Slide centrale agrandie ✅
- **Indicateurs** : Barre bleue suit le slide actif ✅

## ✨ Avantages

- ✅ **Visuel** : Présentation attractive des services
- ✅ **Automatique** : Défilement sans interaction
- ✅ **Interactif** : Possibilité de swiper
- ✅ **Professionnel** : Design moderne avec ombres
- ✅ **Informatif** : Titre et description sur chaque slide
- ✅ **Responsive** : S'adapte à toutes les tailles d'écran
- ✅ **Mode sombre** : Compatible (texte blanc)

## 📝 Prochaines Étapes

### 1. Ajouter de vraies photos
Placez vos photos dans `assets/images/` :
- `bus_exterior.jpg`
- `bus_interior.jpg`
- `service_team.jpg`
- `safety_features.jpg`

### 2. Déclarer dans pubspec.yaml
```yaml
flutter:
  assets:
    - assets/images/bus_exterior.jpg
    - assets/images/bus_interior.jpg
    - assets/images/service_team.jpg
    - assets/images/safety_features.jpg
```

### 3. Mettre à jour les chemins
Dans `_buildPhotoSlider`, changez :
```dart
'image': 'assets/images/bus_exterior.jpg',
```

## 🚀 Déploiement

```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter pub get
git add .
git commit -m "Feat: Ajout slider photos dans écran Info"
git push
```

---

**Le slider de photos est prêt ! Ajoutez vos vraies photos pour un rendu professionnel ! 📸✨**
