import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feature_permission_model.dart';
import '../services/feature_permission_service.dart';
import 'auth_provider.dart';

/// Service de gestion des permissions
final featurePermissionServiceProvider = Provider<FeaturePermissionService>((ref) {
  return FeaturePermissionService();
});

/// Provider pour récupérer toutes les permissions
/// Se recharge automatiquement quand l'utilisateur se connecte ou se déconnecte
final featurePermissionsProvider = FutureProvider<FeaturePermissionsResponse>((ref) async {
  // Écouter les changements d'authentification pour invalider les permissions
  final authState = ref.watch(authProvider);
  
  // Si l'utilisateur n'est pas authentifié, retourner une réponse vide
  if (!authState.isAuthenticated) {
    return FeaturePermissionsResponse(
      permissions: [],
      userId: 0,
      userName: '',
      userRole: null,
    );
  }
  
  final service = ref.watch(featurePermissionServiceProvider);
  return await service.getUserPermissions();
});

/// Provider pour vérifier si une fonctionnalité spécifique est activée
final isFeatureEnabledProvider = Provider.family<bool, String>((ref, featureCode) {
  final permissionsAsync = ref.watch(featurePermissionsProvider);
  
  return permissionsAsync.when(
    data: (response) {
      final permission = response.permissions.firstWhere(
        (p) => p.featureCode == featureCode,
        orElse: () => FeaturePermission(
          featureCode: featureCode,
          featureName: '',
          category: 'general',
          isEnabled: false,
          requiresAdmin: false,
        ),
      );
      return permission.isEnabled;
    },
    loading: () => false, // Par défaut désactivé pendant le chargement
    error: (_, __) => false, // Par défaut désactivé en cas d'erreur
  );
});

/// Provider pour les permissions par catégorie
final featurePermissionsByCategoryProvider = Provider.family<List<FeaturePermission>, String>((ref, category) {
  final permissionsAsync = ref.watch(featurePermissionsProvider);
  
  return permissionsAsync.when(
    data: (response) {
      return response.permissions.where((p) => p.category == category).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider pour les permissions client
final clientFeaturePermissionsProvider = Provider<List<FeaturePermission>>((ref) {
  return ref.watch(featurePermissionsByCategoryProvider('client'));
});

/// Provider pour les permissions admin
final adminFeaturePermissionsProvider = Provider<List<FeaturePermission>>((ref) {
  return ref.watch(featurePermissionsByCategoryProvider('admin'));
});

/// Provider pour les permissions générales
final generalFeaturePermissionsProvider = Provider<List<FeaturePermission>>((ref) {
  return ref.watch(featurePermissionsByCategoryProvider('general'));
});

/// Provider pour compter les fonctionnalités activées
final enabledFeaturesCountProvider = Provider<int>((ref) {
  final permissionsAsync = ref.watch(featurePermissionsProvider);
  
  return permissionsAsync.when(
    data: (response) {
      return response.permissions.where((p) => p.isEnabled).length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider pour rafraîchir les permissions
final refreshFeaturePermissionsProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(featurePermissionsProvider);
  };
});
