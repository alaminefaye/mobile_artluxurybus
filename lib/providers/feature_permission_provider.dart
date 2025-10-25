import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feature_permission_model.dart';
import '../services/feature_permission_service.dart';

/// Service de gestion des permissions
final featurePermissionServiceProvider = Provider<FeaturePermissionService>((ref) {
  return FeaturePermissionService();
});

/// Provider pour récupérer toutes les permissions
final featurePermissionsProvider = FutureProvider<FeaturePermissionsResponse>((ref) async {
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
