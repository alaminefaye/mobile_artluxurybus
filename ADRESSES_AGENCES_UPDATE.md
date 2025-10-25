# ✅ Mise à Jour : Slider & Adresses des Agences

## 🎯 Modifications Appliquées

### 1. Slider de Photos
**Avant** : 4 slides avec `assets/images/12.png`
**Après** : 3 slides avec les vraies images

#### Images Utilisées
- **img1.jpg** : Bus Premium
- **img2.jpg** : Intérieur Luxueux
- **img3.jpg** : Service 5 Étoiles

### 2. Section Adresses
**Avant** : "Notre Adresse" (1 seule adresse)
**Après** : "Nos Adresses" (4 agences)

#### Les 4 Agences
1. **Agence Principale** - Adjamé, Abidjan
2. **Agence Yopougon** - Yopougon, Abidjan
3. **Agence Bouaké** - Bouaké, Abidjan
4. **Agence Yamoussoukro** - Bouaké, Abidjan

## 📱 Nouveau Design

### Slider (3 images)
```
┌─────────────────────────┐
│  [img1.jpg]             │
│  Bus Premium            │ ← Slide 1
│  Confort et élégance    │
└─────────────────────────┘
      ● ○ ○
```

### Adresses (4 cartes)
```
┌─────────────────────────────────┐
│ 📍 Nos Adresses                 │
├─────────────────────────────────┤
│ ┌───────────────────────────┐   │
│ │ 📍 Agence Principale      │   │
│ │ Adjamé - Abidjan          │   │
│ │ Côte d'Ivoire             │   │
│ └───────────────────────────┘   │
│ ┌───────────────────────────┐   │
│ │ 📍 Agence Yopougon        │   │
│ │ Yopougon - Abidjan        │   │
│ │ Côte d'Ivoire             │   │
│ └───────────────────────────┘   │
│ ┌───────────────────────────┐   │
│ │ 📍 Agence Bouaké          │   │
│ │ Bouaké - Abidjan          │   │
│ │ Côte d'Ivoire             │   │
│ └───────────────────────────┘   │
│ ┌───────────────────────────┐   │
│ │ 📍 Agence Yamoussoukro    │   │
│ │ Bouaké - Abidjan          │   │
│ │ Côte d'Ivoire             │   │
│ └───────────────────────────┘   │
└─────────────────────────────────┘
```

## 🎨 Design des Cartes d'Agence

### Caractéristiques
- **Icône** : Pin rouge dans un cercle
- **Bordure** : Rouge clair (20% opacité)
- **Fond** : Gris clair (scaffoldBackgroundColor)
- **Texte** :
  - Titre : Bold, 15px
  - Location : Normal, 14px
  - Subtitle : Gris, 13px

### Layout
```
┌────────────────────────────┐
│ [📍]  Agence Principale    │
│       Adjamé - Abidjan     │
│       Côte d'Ivoire        │
└────────────────────────────┘
```

## 🔧 Fichiers Modifiés

### 1. pubspec.yaml
```yaml
assets:
  - assets/images/
  - 12.png
  - art.jpg
  - img1.jpg  # ← AJOUTÉ
  - img2.jpg  # ← AJOUTÉ
  - img3.jpg  # ← AJOUTÉ
```

### 2. company_info_screen.dart

#### Slider (ligne 220-236)
```dart
final List<Map<String, String>> slides = [
  {
    'image': 'img1.jpg',  // ← Changé
    'title': 'Bus Premium',
    'description': 'Confort et élégance',
  },
  {
    'image': 'img2.jpg',  // ← Changé
    'title': 'Intérieur Luxueux',
    'description': 'Sièges spacieux et climatisés',
  },
  {
    'image': 'img3.jpg',  // ← Changé
    'title': 'Service 5 Étoiles',
    'description': 'Personnel qualifié et accueillant',
  },
];
```

#### Titre (ligne 613)
```dart
Text(
  'Nos Adresses',  // ← Changé de "Notre Adresse"
  // ...
),
```

#### Cartes d'agences (ligne 623-649)
```dart
_buildAgencyCard(
  context,
  title: 'Agence Principale',
  location: 'Adjamé - Abidjan',
  subtitle: 'Côte d\'Ivoire',
),
// ... 3 autres agences
```

#### Nouvelle méthode (ligne 656-719)
```dart
Widget _buildAgencyCard(
  BuildContext context, {
  required String title,
  required String location,
  required String subtitle,
}) {
  // Design de la carte avec icône et textes
}
```

## 📸 Images Utilisées

### Emplacement
```
/Users/mouhamadoulaminefaye/Desktop/PROJETS DEV/mobile_dev/artluxurybus/
├── img1.jpg  ← Bus Premium
├── img2.jpg  ← Intérieur
└── img3.jpg  ← Service
```

### Dans le Slider
- **img1.jpg** : Première slide (Bus Premium)
- **img2.jpg** : Deuxième slide (Intérieur)
- **img3.jpg** : Troisième slide (Service)

## 🧪 Test

### 1. Installer les dépendances
```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter pub get
```

### 2. Lancer l'app
```bash
flutter run
```

### 3. Vérifier le slider
1. **Cliquer** : Bouton "Info"
2. **Observer** : 3 slides avec img1, img2, img3 ✅
3. **Attendre** : Défilement automatique ✅
4. **Swiper** : Changer manuellement ✅

### 4. Vérifier les adresses
1. **Scroller** : Jusqu'à "Nos Adresses"
2. **Observer** : 4 cartes d'agences ✅
3. **Vérifier** :
   - Agence Principale (Adjamé) ✅
   - Agence Yopougon ✅
   - Agence Bouaké ✅
   - Agence Yamoussoukro ✅

### 5. Mode sombre
1. **Activer** : Mode sombre
2. **Retourner** : Écran Info
3. **Observer** : Tout est visible ✅

## ✨ Avantages

### Slider
- ✅ **Vraies photos** : Plus professionnel
- ✅ **3 slides** : Plus rapide à parcourir
- ✅ **Images réelles** : Meilleure présentation

### Adresses
- ✅ **4 agences** : Toutes les localisations
- ✅ **Design uniforme** : Cartes identiques
- ✅ **Icônes rouges** : Facilement identifiables
- ✅ **Informations claires** : Nom, ville, pays

## 📝 Personnalisation

### Changer une adresse
Dans `company_info_screen.dart` (ligne 623-649) :
```dart
_buildAgencyCard(
  context,
  title: 'Votre Agence',      // ← Nom
  location: 'Ville - Région',  // ← Localisation
  subtitle: 'Pays',            // ← Pays
),
```

### Ajouter une agence
Ajoutez après la ligne 649 :
```dart
const SizedBox(height: 12),
_buildAgencyCard(
  context,
  title: 'Nouvelle Agence',
  location: 'Ville - Région',
  subtitle: 'Côte d\'Ivoire',
),
```

### Changer une image du slider
Dans `company_info_screen.dart` (ligne 222) :
```dart
'image': 'votre_image.jpg',  // ← Votre image
```

N'oubliez pas de déclarer dans `pubspec.yaml` :
```yaml
assets:
  - votre_image.jpg
```

## 🚀 Déploiement

```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter pub get
git add .
git commit -m "Update: Slider avec vraies images + 4 agences"
git push
```

---

**Le slider utilise maintenant les vraies images et les 4 agences sont affichées ! 📍✨**
