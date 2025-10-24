import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_loyalty_models.dart';
import '../services/loyalty_service.dart';

class LoyaltyState {
  final bool isLoading;
  final LoyaltyClient? client;
  final String? error;
  final bool isRegistering;

  const LoyaltyState({
    this.isLoading = false,
    this.client,
    this.error,
    this.isRegistering = false,
  });

  LoyaltyState copyWith({
    bool? isLoading,
    LoyaltyClient? client,
    String? error,
    bool? isRegistering,
    bool clearClient = false,
    bool clearError = false,
  }) {
    return LoyaltyState(
      isLoading: isLoading ?? this.isLoading,
      client: clearClient ? null : (client ?? this.client),
      error: clearError ? null : (error ?? this.error),
      isRegistering: isRegistering ?? this.isRegistering,
    );
  }

  bool get hasClient => client != null;
  bool get hasError => error != null;
}

class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  LoyaltyNotifier() : super(const LoyaltyState());

  // Vérifier les points d'un client
  Future<bool> checkClientPoints(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await LoyaltyService.checkPoints(phone);

      if (response.success && response.exists == true && response.client != null) {
        state = state.copyWith(
          isLoading: false,
          client: response.client,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
          clearClient: true,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de connexion: ${e.toString()}',
        clearClient: true,
      );
      return false;
    }
  }

  // Inscrire un nouveau client
  Future<bool> registerClient({
    required String nom,
    required String prenom,
    required String telephone,
    String? email,
  }) async {
    state = state.copyWith(isRegistering: true, clearError: true);

    try {
      final response = await LoyaltyService.registerClient(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
      );

      if (response.success && response.client != null) {
        state = state.copyWith(
          isRegistering: false,
          client: response.client,
        );
        return true;
      } else {
        state = state.copyWith(
          isRegistering: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: 'Erreur lors de l\'inscription: ${e.toString()}',
      );
      return false;
    }
  }

  // Rafraîchir les données du client
  Future<void> refreshClient() async {
    if (state.client?.telephone != null) {
      await checkClientPoints(state.client!.telephone);
    }
  }

  // Obtenir le profil complet avec historique
  Future<LoyaltyProfileResponse?> getClientProfile() async {
    debugPrint('🔵 [LoyaltyProvider] getClientProfile called');
    debugPrint('  - Client exists: ${state.client != null}');
    debugPrint('  - Client phone: ${state.client?.telephone}');
    
    if (state.client?.telephone == null) {
      debugPrint('❌ [LoyaltyProvider] No client in state, returning null');
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await LoyaltyService.getProfile(state.client!.telephone);
      
      debugPrint('📥 [LoyaltyProvider] Response received:');
      debugPrint('  - success: ${response.success}');
      debugPrint('  - message: ${response.message}');
      debugPrint('  - client exists: ${response.client != null}');
      debugPrint('  - history exists: ${response.history != null}');
      
      if (response.success && response.client != null) {
        state = state.copyWith(
          isLoading: false,
          client: response.client,
        );
        return response;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        debugPrint('⚠️ [LoyaltyProvider] Response not successful or no client');
        return response; // Retourner la réponse même en cas d'échec pour voir l'erreur
      }
    } catch (e) {
      debugPrint('❌ [LoyaltyProvider] Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la récupération du profil: ${e.toString()}',
      );
      return null;
    }
  }

  // Mettre à jour les informations client
  Future<bool> updateClient({
    String? nom,
    String? prenom,
    String? email,
  }) async {
    if (state.client?.telephone == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await LoyaltyService.updateClient(
        phone: state.client!.telephone,
        nom: nom,
        prenom: prenom,
        email: email,
      );

      if (response.success && response.client != null) {
        state = state.copyWith(
          isLoading: false,
          client: response.client,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour: ${e.toString()}',
      );
      return false;
    }
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Effacer le client
  void clearClient() {
    state = state.copyWith(clearClient: true, clearError: true);
  }

  // Reset complet
  void reset() {
    state = const LoyaltyState();
  }
}

// Provider principal
final loyaltyProvider = StateNotifierProvider<LoyaltyNotifier, LoyaltyState>(
  (ref) => LoyaltyNotifier(),
);

// Providers utilitaires
final loyaltyStatsProvider = FutureProvider<LoyaltyStatsResponse>((ref) async {
  return await LoyaltyService.getStats();
});

final hasLoyaltyClientProvider = Provider<bool>((ref) {
  final loyaltyState = ref.watch(loyaltyProvider);
  return loyaltyState.hasClient;
});

final loyaltyClientProvider = Provider<LoyaltyClient?>((ref) {
  final loyaltyState = ref.watch(loyaltyProvider);
  return loyaltyState.client;
});

final loyaltyErrorProvider = Provider<String?>((ref) {
  final loyaltyState = ref.watch(loyaltyProvider);
  return loyaltyState.error;
});

final loyaltyLoadingProvider = Provider<bool>((ref) {
  final loyaltyState = ref.watch(loyaltyProvider);
  return loyaltyState.isLoading;
});
