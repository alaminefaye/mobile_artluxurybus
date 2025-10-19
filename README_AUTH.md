# Configuration de l'Authentification - Art Luxury Bus

## 📱 Intégration Flutter ↔ Laravel

Ce document explique comment configurer et tester l'authentification entre l'application Flutter et le backend Laravel.

## 🚀 Configuration

### 1. Backend Laravel (gestion-compagny)

Assurez-vous que votre serveur Laravel fonctionne :

```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/gestion-compagny
php artisan serve
```

Le serveur sera disponible sur `http://localhost:8000`

### 2. Configuration Flutter

1. **URL de l'API** : Modifiez l'URL dans `lib/utils/api_config.dart` selon votre configuration :

```dart
// Pour le développement local
static const String baseUrl = 'http://localhost:8000/api';

// Pour un serveur distant
// static const String baseUrl = 'http://192.168.1.X:8000/api';
// static const String baseUrl = 'https://votre-domaine.com/api';
```

2. **Installation des dépendances** :

```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter pub get
flutter packages pub run build_runner build
```

## 🧪 Test de l'Authentification

### 1. Créer un utilisateur de test

Dans votre projet Laravel, créez un utilisateur de test :

```bash
php artisan tinker
```

```php
use App\Models\User;
User::create([
    'name' => 'Test User',
    'email' => 'test@artluxurybus.com',
    'password' => bcrypt('123456'),
    'is_active' => true,
    'is_blocked' => false,
]);
```

### 2. Lancer l'application Flutter

```bash
flutter run
```

### 3. Tester la connexion

- **Email** : `test@artluxurybus.com`
- **Mot de passe** : `123456`

## 🔧 Fonctionnalités Implémentées

### ✅ Authentification de Base
- [x] Écran de connexion avec validation
- [x] Gestion des états (chargement, erreurs)
- [x] Stockage sécurisé des tokens
- [x] Déconnexion automatique
- [x] Gestion des erreurs réseau

### ✅ API Endpoints Intégrés
- [x] `POST /api/auth/login` - Connexion
- [x] `POST /api/auth/logout` - Déconnexion
- [x] `POST /api/auth/forgot-password` - Mot de passe oublié
- [x] `GET /api/user` - Profil utilisateur

### ✅ Gestion d'État
- [x] Provider Riverpod pour l'authentification
- [x] Persistence des données utilisateur
- [x] Navigation automatique selon le statut

## 🛠️ Prochaines Étapes

### Phase 2 - Fonctionnalités Métier
- [ ] Gestion des bus
- [ ] Système de billetterie
- [ ] Gestion des employés
- [ ] Planning des trajets
- [ ] Rapports et statistiques

### Phase 3 - Fonctionnalités Avancées
- [ ] Notifications push
- [ ] Synchronisation offline
- [ ] Géolocalisation
- [ ] Scan QR codes

## 🔍 Débogage

### Problèmes Courants

1. **Erreur de connexion** :
   - Vérifiez que le serveur Laravel fonctionne
   - Vérifiez l'URL dans `api_config.dart`
   - Vérifiez les CORS dans Laravel

2. **Erreur de validation** :
   - Vérifiez le format des données envoyées
   - Consultez les logs Laravel : `tail -f storage/logs/laravel.log`

3. **Token invalide** :
   - Effacez les données de l'app : Settings > Apps > Art Luxury Bus > Storage > Clear Data

### Logs de Débogage

Pour activer les logs détaillés dans Flutter :

```bash
flutter run --verbose
```

## 📁 Structure du Projet

```
lib/
├── main.dart                 # Point d'entrée avec AuthWrapper
├── models/                   # Modèles de données
│   ├── user.dart
│   ├── auth_response.dart
│   └── login_request.dart
├── services/                 # Services API
│   └── auth_service.dart
├── providers/                # Gestion d'état Riverpod
│   └── auth_provider.dart
├── screens/                  # Écrans de l'application
│   ├── auth/
│   │   └── login_screen.dart
│   └── home_screen.dart
└── utils/                    # Utilitaires
    └── api_config.dart       # Configuration API
```

## 🚨 Sécurité

- Les tokens sont stockés de manière sécurisée avec `shared_preferences`
- Les mots de passe ne sont jamais stockés localement
- Les requêtes utilisent HTTPS en production
- Validation des données côté client et serveur
