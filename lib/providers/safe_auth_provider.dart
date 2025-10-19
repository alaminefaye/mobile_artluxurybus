import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/safe_auth_response.dart';
import '../models/login_request.dart';
import '../services/safe_auth_service.dart';

// Service provider
final safeAuthServiceProvider = Provider<SafeAuthService>((ref) => SafeAuthService());

// Auth state
class SafeAuthState {
  final SafeUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const SafeAuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  SafeAuthState copyWith({
    SafeUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return SafeAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth notifier
class SafeAuthNotifier extends StateNotifier<SafeAuthState> {
  final SafeAuthService _authService;

  SafeAuthNotifier(this._authService) : super(const SafeAuthState()) {
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

  // Déconnexion
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _authService.clearAuthData();
      state = const SafeAuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      // Même en cas d'erreur, on déconnecte localement
      state = const SafeAuthState(isAuthenticated: false, isLoading: false);
    }
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Auth provider
final safeAuthProvider = StateNotifierProvider<SafeAuthNotifier, SafeAuthState>((ref) {
  final authService = ref.read(safeAuthServiceProvider);
  return SafeAuthNotifier(authService);
});

// Convenience providers
final safeIsAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(safeAuthProvider).isAuthenticated;
});

final safeCurrentUserProvider = Provider<SafeUser?>((ref) {
  return ref.watch(safeAuthProvider).user;
});

final safeAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(safeAuthProvider).isLoading;
});

final safeAuthErrorProvider = Provider<String?>((ref) {
  return ref.watch(safeAuthProvider).error;
});
