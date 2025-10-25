# ✅ Écran Informations Entreprise

## 🎯 Objectif

Remplacer le bouton **"Offres"** par **"Info"** pour afficher les informations complètes de l'entreprise Art Luxury Bus.

## 🔧 Modifications appliquées

### 1. HomePage - Bouton modifié

**Fichier** : `lib/screens/home_page.dart`

#### Avant ❌
```dart
_buildQuickActionItem(
  icon: Icons.card_giftcard_rounded,
  label: 'Offres',
  color: Colors.purple,
),
```

#### Après ✅
```dart
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyInfoScreen(),
      ),
    );
  },
  child: _buildQuickActionItem(
    icon: Icons.info_rounded,
    label: 'Info',
    color: Colors.blue,
  ),
),
```

### 2. Nouvel écran créé

**Fichier** : `lib/screens/company_info_screen.dart`

## 📋 Contenu de l'écran

L'écran affiche les informations suivantes :

### 1. En-tête
- Logo de l'entreprise (icône bus)
- Nom : **Art Luxury Bus**
- Slogan : **"Votre confort, notre priorité"**
- Design avec dégradé bleu

### 2. À Propos
- Description de l'entreprise
- Mission et engagement

### 3. Contact
- **Téléphone** : +225 XX XX XX XX XX (cliquable)
- **Email** : contact@artluxurybus.com (cliquable)
- **Site Web** : www.artluxurybus.com (cliquable)

### 4. Adresse
- **Siège Social** : Abidjan, Côte d'Ivoire
- **Quartier** : Cocody, Angré 7ème Tranche

### 5. Horaires d'Ouverture
- **Lundi - Vendredi** : 7h00 - 19h00
- **Samedi** : 8h00 - 18h00
- **Dimanche** : 9h00 - 17h00

### 6. Nos Services
- 🚌 Transport interurbain
- 🎫 Réservation en ligne
- 💳 Paiement mobile
- 🎁 Programme de fidélité
- 📍 Suivi en temps réel
- 🛡️ Assurance voyage

### 7. Réseaux Sociaux
- **Facebook** (cliquable)
- **Instagram** (cliquable)
- **WhatsApp** (cliquable)

### 8. Footer
- Copyright © 2025 Art Luxury Bus
- Tous droits réservés

## 🎨 Design

### Caractéristiques
- ✅ **Mode sombre** : Entièrement compatible
- ✅ **Cartes** : Design moderne avec ombres
- ✅ **Icônes** : Colorées et expressives
- ✅ **Interactions** : Tous les contacts sont cliquables
- ✅ **Responsive** : S'adapte à toutes les tailles d'écran

### Couleurs
- **Bleu principal** : AppTheme.primaryBlue
- **Cartes** : Theme.of(context).cardColor
- **Textes** : Adaptés au thème (clair/sombre)

## 🔗 Fonctionnalités interactives

### 1. Téléphone
```dart
_launchPhone('+225XXXXXXXXXX')
```
- Ouvre l'application téléphone
- Numéro pré-rempli

### 2. Email
```dart
_launchEmail('contact@artluxurybus.com')
```
- Ouvre l'application email
- Destinataire et sujet pré-remplis

### 3. Site Web
```dart
_launchUrl('https://www.artluxurybus.com')
```
- Ouvre dans le navigateur externe

### 4. WhatsApp
```dart
_launchWhatsApp('+225XXXXXXXXXX')
```
- Ouvre WhatsApp avec le numéro

### 5. Réseaux sociaux
- Facebook, Instagram : Ouvrent dans le navigateur
- Liens vers les pages officielles

## 📦 Package utilisé

**url_launcher: ^6.3.1** (déjà présent dans pubspec.yaml)

Permet de :
- Ouvrir des liens web
- Lancer des appels téléphoniques
- Envoyer des emails
- Ouvrir WhatsApp

## 🧪 Test

### 1. Lancer l'app
```bash
flutter run
```

### 2. Vérifier le bouton
1. Sur la **page d'accueil**
2. Observer les 3 boutons rapides en haut
3. **Vérifier** : Le 3ème bouton affiche maintenant **"Info"** avec une icône bleue ✅

### 3. Tester l'écran
1. **Cliquer** sur le bouton "Info"
2. **Observer** : L'écran d'informations s'ouvre ✅
3. **Vérifier** :
   - En-tête avec logo et nom ✅
   - Toutes les sections affichées ✅
   - Design moderne et propre ✅

### 4. Tester les interactions
1. **Cliquer sur Téléphone** : Ouvre l'app téléphone ✅
2. **Cliquer sur Email** : Ouvre l'app email ✅
3. **Cliquer sur Site Web** : Ouvre le navigateur ✅
4. **Cliquer sur WhatsApp** : Ouvre WhatsApp ✅
5. **Cliquer sur réseaux sociaux** : Ouvrent les pages ✅

### 5. Tester le mode sombre
1. **Activer le mode sombre** : Profil → Paramètres → Thème
2. **Retourner sur Info**
3. **Observer** : Tout est parfaitement visible ✅

## 📸 Aperçu

### Page d'accueil
```
┌─────────────────────────────┐
│  📍 Abidjan                 │
├─────────────────────────────┤
│  [Réserver] [Mes trajets]   │
│  [Info] ← NOUVEAU           │
└─────────────────────────────┘
```

### Écran Info
```
┌─────────────────────────────┐
│  🚌 Art Luxury Bus          │
│  Votre confort, notre...    │
├─────────────────────────────┤
│  📋 À Propos                │
│  Description...             │
├─────────────────────────────┤
│  📞 Contact                 │
│  ☎️ Téléphone               │
│  ✉️ Email                   │
│  🌐 Site Web                │
├─────────────────────────────┤
│  📍 Adresse                 │
│  Abidjan, Cocody...         │
├─────────────────────────────┤
│  🕐 Horaires                │
│  Lun-Ven: 7h-19h            │
├─────────────────────────────┤
│  🎯 Nos Services            │
│  🚌 Transport               │
│  🎫 Réservation             │
│  ...                        │
├─────────────────────────────┤
│  📱 Suivez-nous             │
│  [Facebook] [Insta] [WA]    │
└─────────────────────────────┘
```

## 🎯 Avantages

- ✅ **Informations complètes** : Tout sur l'entreprise en un seul endroit
- ✅ **Contacts cliquables** : Appel, email, web en un clic
- ✅ **Design moderne** : Interface élégante et professionnelle
- ✅ **Mode sombre** : Parfaitement compatible
- ✅ **Réseaux sociaux** : Liens directs vers les pages
- ✅ **Horaires** : Clients informés des heures d'ouverture
- ✅ **Services** : Liste complète des offres

## 📝 Personnalisation

Pour personnaliser les informations, modifiez dans `company_info_screen.dart` :

### Téléphone
```dart
value: '+225 XX XX XX XX XX',  // Ligne 60
onTap: () => _launchPhone('+225XXXXXXXXXX'),  // Ligne 61
```

### Email
```dart
value: 'contact@artluxurybus.com',  // Ligne 68
onTap: () => _launchEmail('contact@artluxurybus.com'),  // Ligne 69
```

### Site Web
```dart
value: 'www.artluxurybus.com',  // Ligne 76
onTap: () => _launchUrl('https://www.artluxurybus.com'),  // Ligne 77
```

### Adresse
```dart
Text(
  'Abidjan, Côte d\'Ivoire\n'
  'Cocody, Angré 7ème Tranche',  // Lignes 100-101
),
```

### Horaires
```dart
_buildScheduleItem('Lundi - Vendredi', '7h00 - 19h00'),  // Ligne 119
_buildScheduleItem('Samedi', '8h00 - 18h00'),  // Ligne 121
_buildScheduleItem('Dimanche', '9h00 - 17h00'),  // Ligne 123
```

### Réseaux sociaux
```dart
onTap: () => _launchUrl('https://facebook.com/artluxurybus'),  // Ligne 160
onTap: () => _launchUrl('https://instagram.com/artluxurybus'),  // Ligne 168
onTap: () => _launchWhatsApp('+225XXXXXXXXXX'),  // Ligne 176
```

## 🚀 Déploiement

```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
git add .
git commit -m "Feat: Ajout écran informations entreprise (remplace Offres)"
git push
```

---

**L'écran d'informations entreprise est prêt ! Les clients peuvent maintenant accéder à toutes les informations importantes !** 🎉✨
