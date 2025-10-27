import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_auth_models.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

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

  // Connexion
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final loginRequest = LoginRequest(email: email, password: password);
      final response = await _authService.login(loginRequest);

      if (response.success && response.data != null) {
        state = state.copyWith(
          user: response.data!.user,
          isAuthenticated: true,
          isLoading: false,
        );
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
        state = state.copyWith(user: user);
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'actualisation: $e');
    }
  }

  // Alias pour refreshUserProfile
  Future<void> refreshUser() async {
    await refreshUserProfile();
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
