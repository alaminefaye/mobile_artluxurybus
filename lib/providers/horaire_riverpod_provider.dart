import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/horaire_model.dart';
import '../services/horaire_service.dart';
import '../services/device_service.dart';

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
  Timer? _autoRefreshTimer;

  HoraireNotifier(this._service) : super(HoraireState()) {
    // Charger les horaires au démarrage
    fetchTodayHoraires();
    // Démarrer le rafraîchissement automatique toutes les 30 secondes
    startAutoRefresh();
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
  // Filtre automatiquement par le device_id de l'appareil
  Future<void> fetchTodayHoraires({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      // Récupérer le device_id
      final deviceId = await DeviceService.getDeviceId();
      
      // Appeler l'API avec le device_id pour filtrer
      final grouped = await _service.fetchTodayHoraires(deviceId: deviceId);
      
      // Aplatir pour avoir aussi une liste simple
      final allHoraires = <Horaire>[];
      grouped.forEach((gare, horaires) {
        allHoraires.addAll(horaires);
      });

      state = state.copyWith(
        horairesGrouped: grouped,
        horaires: allHoraires,
        isLoading: false,
        error: null,
      );
    } catch (e) {
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
