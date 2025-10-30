import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/horaire_model.dart';
import '../services/horaire_service.dart';
import '../services/device_service.dart';
import '../services/auth_service.dart';

// Service provider
final horaireServiceProvider = Provider<HoraireService>((ref) {
  return HoraireService();
});

// State class pour gérer les horaires
class HoraireState {
  final List<Horaire> horaires;
  final Map<String, List<Horaire>> horairesGrouped;
  final bool isLoading;
  final String? error;

  HoraireState({
    this.horaires = const [],
    this.horairesGrouped = const {},
    this.isLoading = false,
    this.error,
  });

  HoraireState copyWith({
    List<Horaire>? horaires,
    Map<String, List<Horaire>>? horairesGrouped,
    bool? isLoading,
    String? error,
  }) {
    return HoraireState(
      horaires: horaires ?? this.horaires,
      horairesGrouped: horairesGrouped ?? this.horairesGrouped,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier pour gérer l'état des horaires
class HoraireNotifier extends StateNotifier<HoraireState> {
  final HoraireService _service;
  final AuthService _authService = AuthService();
  Timer? _autoRefreshTimer;

  HoraireNotifier(this._service) : super(HoraireState()) {
    // Charger les horaires au démarrage
    fetchTodayHoraires();
    // Démarrer le rafraîchissement automatique toutes les 30 secondes
    startAutoRefresh();
  }

  // Vérifier si l'utilisateur connecté est un administrateur
  Future<bool> _isUserAdmin() async {
    try {
      final user = await _authService.getSavedUser();
      print('👤 [HoraireProvider] Utilisateur connecté: ${user?.name} (role: ${user?.role})');
      
      if (user == null) {
        print('🔐 [HoraireProvider] Pas d\'utilisateur connecté');
        return false;
      }
      
      // Vérifier le rôle ou les permissions directement
      final isAdmin = user.role == 'Super Admin' || 
                     user.role == 'Admin' || 
                     user.role == 'chef agence' || 
                     (user.permissions?.contains('manage_horaires') ?? false);
      
      print('🔐 [HoraireProvider] Résultat isUserAdmin(): $isAdmin');
      
      return isAdmin;
    } catch (e) {
      print('❌ [HoraireProvider] Erreur détection admin: $e');
      return false;
    }
  }

  // Démarrer le rafraîchissement automatique
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchTodayHoraires(silent: true),
    );
  }

  // Arrêter le rafraîchissement automatique
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  // Récupérer tous les horaires
  Future<void> fetchAllHoraires({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final horaires = await _service.fetchAllHoraires();
      state = state.copyWith(
        horaires: horaires,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Récupérer les horaires d'aujourd'hui groupés par gare
  // Pour les admins: récupère TOUS les horaires
  // Pour les utilisateurs publics: filtre automatiquement par le device_id de l'appareil
  Future<void> fetchTodayHoraires({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      print('🔄 [HoraireProvider] Début récupération des horaires...');
      
      // Vérifier si l'utilisateur est admin
      final isAdmin = await _isUserAdmin();
      print('👤 [HoraireProvider] Utilisateur admin: $isAdmin');
      
      if (isAdmin) {
        print('✅ [HoraireProvider] Mode ADMIN - Récupération de TOUS les horaires');
        // ✅ ADMIN: Récupérer TOUS les horaires (sans filtre par device_id)
        final allHoraires = await _service.fetchAllHoraires();
        print('📊 [HoraireProvider] Horaires récupérés (admin): ${allHoraires.length}');
        
        // Grouper par gare pour compatibilité
        Map<String, List<Horaire>> grouped = {};
        for (final horaire in allHoraires) {
          final gareName = horaire.gare.nom;
          if (!grouped.containsKey(gareName)) {
            grouped[gareName] = [];
          }
          grouped[gareName]!.add(horaire);
        }

        state = state.copyWith(
          horairesGrouped: grouped,
          horaires: allHoraires,
          isLoading: false,
          error: null,
        );
      } else {
        print('🔒 [HoraireProvider] Mode PUBLIC - Filtrage par device_id');
        // 🔒 UTILISATEUR PUBLIC: Filtrer par device_id comme avant
        final deviceId = await DeviceService.getDeviceId();
        print('📱 [HoraireProvider] Device ID: $deviceId');
        final grouped = await _service.fetchTodayHoraires(deviceId: deviceId);
        
        // Aplatir pour avoir aussi une liste simple
        final allHoraires = <Horaire>[];
        grouped.forEach((gare, horaires) {
          allHoraires.addAll(horaires);
        });
        print('📊 [HoraireProvider] Horaires récupérés (public): ${allHoraires.length}');

        state = state.copyWith(
          horairesGrouped: grouped,
          horaires: allHoraires,
          isLoading: false,
          error: null,
        );
      }
      print('✅ [HoraireProvider] Récupération terminée avec succès');
    } catch (e) {
      print('❌ [HoraireProvider] Erreur: $e');
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  // Récupérer les horaires par gare
  Future<void> fetchHorairesByGare(int gareId, {bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final horaires = await _service.fetchHorairesByGare(gareId);
      state = state.copyWith(
        horaires: horaires,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Récupérer les horaires par appareil
  Future<void> fetchHorairesByAppareil(String appareil, {bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final horaires = await _service.fetchHorairesByAppareil(appareil);
      state = state.copyWith(
        horaires: horaires,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Rafraîchir manuellement
  Future<void> refresh() => fetchTodayHoraires();
}

// Provider principal des horaires
final horaireProvider = StateNotifierProvider<HoraireNotifier, HoraireState>((ref) {
  final service = ref.watch(horaireServiceProvider);
  return HoraireNotifier(service);
});

// Providers dérivés pour un accès facile
final horairesListProvider = Provider<List<Horaire>>((ref) {
  return ref.watch(horaireProvider).horaires;
});

final horairesGroupedProvider = Provider<Map<String, List<Horaire>>>((ref) {
  return ref.watch(horaireProvider).horairesGrouped;
});

final isLoadingHorairesProvider = Provider<bool>((ref) {
  return ref.watch(horaireProvider).isLoading;
});

// Providers pour filtrer les horaires
final horairesEnEmbarquementProvider = Provider<List<Horaire>>((ref) {
  final horaires = ref.watch(horairesListProvider);
  return horaires.where((h) => h.statut == 'embarquement').toList();
});

final horairesALheureProvider = Provider<List<Horaire>>((ref) {
  final horaires = ref.watch(horairesListProvider);
  return horaires.where((h) => h.statut == 'a_l_heure').toList();
});

final horairesTerminesProvider = Provider<List<Horaire>>((ref) {
  final horaires = ref.watch(horairesListProvider);
  return horaires.where((h) => h.statut == 'termine').toList();
});

final prochainsDepartsProvider = Provider<List<Horaire>>((ref) {
  final horaires = ref.watch(horairesListProvider);
  // Afficher TOUS les départs actifs de la journée (même terminés)
  return horaires
      .where((h) => h.actif)
      .toList()
    ..sort((a, b) => a.heure.compareTo(b.heure));
});
