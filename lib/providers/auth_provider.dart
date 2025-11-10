import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_auth_models.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/feedback_api_service.dart';
import '../services/notification_api_service.dart';
import '../services/ads_api_service.dart';
import '../services/horaire_service.dart';
import '../services/video_advertisement_service.dart';
import '../services/trip_service.dart';
import '../services/depart_service.dart';
import '../services/reservation_service.dart';
import '../services/mail_api_service.dart';
import '../services/bagage_api_service.dart';

// Service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkAuthStatus();
  }

  // Vérifier le statut d'authentification au démarrage
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getSavedUser();
        state = state.copyWith(
          user: user,
          isAuthenticated: user != null,
          isLoading: false,
        );
        
        // Définir les tokens pour les services si connecté
        if (user != null) {
          await _setTokensForAllServices();
        }
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de la vérification du statut: $e',
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  // Définir le token pour tous les services API
  Future<void> _setTokensForAllServices() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        FeedbackApiService.setToken(token);
        NotificationApiService.setToken(token);
        AdsApiService.setToken(token);
        HoraireService.setToken(token);
        VideoAdvertisementService.setToken(token);
        TripService.setToken(token);
        DepartService.setToken(token);
        ReservationService.setToken(token);
        MailApiService.setToken(token);
        BagageApiService.setToken(token);
      }
    } catch (e) {
      // Erreur silencieuse, pas critique
    }
  }

  // Connexion
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final loginRequest = LoginRequest(email: email, password: password);
      final response = await _authService.login(loginRequest);

      if (response.success && response.data != null) {
        debugPrint('🔍 [AuthProvider] Données utilisateur reçues: ${response.data!.user.toJson()}');
        debugPrint('🔍 [AuthProvider] Rôle de l\'utilisateur: "${response.data!.user.role}"');
        
        state = state.copyWith(
          user: response.data!.user,
          isAuthenticated: true,
          isLoading: false,
        );
        
        debugPrint('🔍 [AuthProvider] État mis à jour - Rôle dans state: "${state.user?.role}"');
        
        // ✅ IMPORTANT: Définir le token IMMÉDIATEMENT pour tous les services API
        await _setTokensForAllServices();
        
        return true;
      } else {
        state = state.copyWith(
          error: response.message,
          isLoading: false,
          isAuthenticated: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur de connexion: $e',
        isLoading: false,
        isAuthenticated: false,
      );
      return false;
    }
  }

  // Inscription
  Future<bool> register(Map<String, dynamic> registerData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.register(registerData);

      if (response.success && response.data != null) {
        state = state.copyWith(
          user: response.data!.user,
          isAuthenticated: true,
          isLoading: false,
        );
        
        // ✅ IMPORTANT: Définir le token IMMÉDIATEMENT pour tous les services API
        await _setTokensForAllServices();
        
        return true;
      } else {
        state = state.copyWith(
          error: response.message,
          isLoading: false,
          isAuthenticated: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur d\'inscription: $e',
        isLoading: false,
        isAuthenticated: false,
      );
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _authService.logout();
      state = const AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      // Même en cas d'erreur, on déconnecte localement
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  // Mot de passe oublié
  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.forgotPassword(email);
      state = state.copyWith(
        isLoading: false,
        error: response.success ? null : response.message,
      );
      return response.success;
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de l\'envoi: $e',
        isLoading: false,
      );
      return false;
    }
  }

  // Actualiser le profil utilisateur
  Future<void> refreshUserProfile() async {
    try {
      final user = await _authService.getUserProfile();
      if (user != null) {
        // Sauvegarder l'utilisateur dans SharedPreferences pour tous les rôles
        await _authService.saveUser(user);
        // Mettre à jour l'état
        state = state.copyWith(user: user);
        debugPrint('✅ [AuthProvider] Profil utilisateur rafraîchi et sauvegardé pour le rôle: ${user.role}');
      } else {
        debugPrint('⚠️ [AuthProvider] Aucun utilisateur récupéré depuis l\'API');
      }
    } catch (e) {
      debugPrint('❌ [AuthProvider] Erreur lors de l\'actualisation: $e');
      state = state.copyWith(error: 'Erreur lors de l\'actualisation: $e');
    }
  }

  // Alias pour refreshUserProfile
  Future<void> refreshUser() async {
    await refreshUserProfile();
  }

  // Mettre à jour l'état après une inscription réussie
  Future<void> updateAuthAfterRegistration({
    required User user,
  }) async {
    debugPrint('🔄 [AuthProvider] Mise à jour de l\'état après inscription');
    debugPrint('   - User ID: ${user.id}');
    debugPrint('   - Email: ${user.email}');
    debugPrint('   - Rôle: ${user.role}');
    
    state = state.copyWith(
      user: user,
      isAuthenticated: true,
      isLoading: false,
      error: null,
    );
    
    // Définir les tokens pour tous les services
    await _setTokensForAllServices();
    
    debugPrint('✅ [AuthProvider] État mis à jour - Authentifié: ${state.isAuthenticated}');
  }

  // Recharger l'utilisateur depuis SharedPreferences
  Future<void> reloadUserFromStorage() async {
    try {
      final user = await _authService.getSavedUser();
      if (user != null) {
        state = state.copyWith(user: user);
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors du rechargement: $e');
    }
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
