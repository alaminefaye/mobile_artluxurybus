# Intégration des Fonctionnalités dans l'Application Mobile

## Vue d'ensemble

L'application mobile a été modifiée pour vérifier automatiquement les permissions des fonctionnalités et cacher celles qui sont désactivées dans le backend.

## Modifications apportées

### 1. Mise à jour des codes de fonctionnalités

Le fichier `lib/models/feature_permission_model.dart` a été mis à jour pour correspondre aux codes du backend :

- `reservation` : Réservation de trajets
- `mail` : Gestion des courriers
- `info` : Informations sur la compagnie
- `loyalty` : Programme de fidélité
- `feedback` : Suggestions/Préoccupations
- `my_trips` : Mes Trajets
- `recharge` : Recharge du solde
- `bus_management` : Gestion des bus (admin)
- `ticket_management` : Gestion des tickets (admin)

### 2. Intégration dans HomePage

Le fichier `lib/screens/home_page.dart` a été modifié pour :

- Vérifier les permissions avant d'afficher les quick actions (Réservation, Mes Trajets, Info)
- Vérifier les permissions avant d'afficher les services dans la grille
- Cacher automatiquement les fonctionnalités désactivées

#### Quick Actions (Actions rapides)

Les quick actions vérifient maintenant les permissions :
- **Réservation** : Vérifie `FeatureCodes.reservation`
- **Mes Trajets** : Vérifie `FeatureCodes.myTrips`
- **Info** : Vérifie `FeatureCodes.info`

#### Services dans la grille

Tous les services vérifient maintenant les permissions avant d'être affichés :
- **Réservation** : Vérifie `FeatureCodes.reservation`
- **Courrier** : Vérifie `FeatureCodes.mail`
- **Programme de Fidélité** : Vérifie `FeatureCodes.loyalty`
- **Feedback** : Vérifie `FeatureCodes.feedback`
- **Mes Trajets** : Vérifie `FeatureCodes.myTrips`
- **Recharge** : Vérifie `FeatureCodes.recharge`
- **Gestion des Bus** : Vérifie `FeatureCodes.busManagement` (admin)

### 3. Utilisation des Providers Riverpod

L'application utilise les providers Riverpod pour gérer les permissions :

- `featurePermissionsProvider` : Récupère toutes les permissions
- `isFeatureEnabledProvider` : Vérifie si une fonctionnalité spécifique est activée

Ces providers se mettent à jour automatiquement quand l'utilisateur se connecte ou se déconnecte.

## Fonctionnement

### Synchronisation des permissions

1. Au démarrage de l'application, les permissions sont synchronisées via `FeaturePermissionService.syncPermissions()`
2. Les permissions sont mises en cache dans le provider Riverpod
3. Les widgets utilisent `Consumer` pour réagir aux changements de permissions

### Affichage conditionnel

Quand une fonctionnalité est désactivée dans le backend :
1. L'API retourne `is_enabled: false` pour cette fonctionnalité
2. Le provider Riverpod met à jour l'état
3. Les widgets qui utilisent `Consumer` se reconstruisent automatiquement
4. Les fonctionnalités désactivées retournent `SizedBox.shrink()` et ne sont pas affichées

## Exemple d'utilisation

```dart
// Vérifier si une fonctionnalité est activée
Consumer(
  builder: (context, ref, child) {
    final isReservationEnabled = ref.watch(
      isFeatureEnabledProvider(FeatureCodes.reservation),
    );
    if (!isReservationEnabled) return const SizedBox.shrink();
    return _buildServiceIcon(
      icon: Icons.confirmation_number_rounded,
      label: t('home.book'),
      color: AppTheme.primaryBlue,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReservationScreen(),
          ),
        );
      },
    );
  },
)
```

## Avantages

1. **Flexibilité** : Les fonctionnalités peuvent être activées/désactivées depuis le backend sans modification du code mobile
2. **Réactivité** : Les changements sont visibles immédiatement après une reconnexion
3. **Maintenance** : Plus besoin de modifier le code pour activer/désactiver une fonctionnalité
4. **Sécurité** : Les fonctionnalités désactivées ne sont pas accessibles même si l'utilisateur essaie d'y accéder directement

## Notes importantes

- Les permissions sont synchronisées au démarrage de l'application
- Les changements dans le backend nécessitent une reconnexion pour être visibles
- Les fonctionnalités désactivées ne sont pas supprimées, elles sont juste cachées
- L'API vérifie d'abord l'état global (`is_active`) avant de vérifier les permissions utilisateur

## Prochaines étapes

1. Ajouter un mécanisme de rafraîchissement périodique des permissions
2. Ajouter une notification lorsque des fonctionnalités sont désactivées
3. Ajouter des vérifications de permissions dans les autres écrans de l'application
4. Implémenter un cache local pour les permissions (SharedPreferences)

