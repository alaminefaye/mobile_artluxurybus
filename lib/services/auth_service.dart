import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simple_auth_models.dart';
// LoginRequest maintenant dans simple_auth_models.dart
import '../models/user.dart';
import '../utils/api_config.dart';
import '../utils/debug_logger.dart';

class AuthService {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Headers par défaut
  Map<String, String> get _headers => ApiConfig.defaultHeaders;

  // Headers avec token d'authentification
  Future<Map<String, String>> get _authHeaders async {
    final token = await getToken();
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Connexion
  Future<AuthResponse> login(LoginRequest loginRequest) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint.fullUrl),
        headers: _headers,
        body: json.encode(loginRequest.toJson()),
      );

      DebugLogger.response(response.statusCode, response.body);

      if (response.statusCode != 200) {
        DebugLogger.error('Server error', 'Status: ${response.statusCode}, Body: ${response.body.substring(0, 200)}...');
        
        String errorMessage;
        if (response.statusCode == 500) {
          errorMessage = 'Le serveur est temporairement indisponible. Veuillez contacter l\'administrateur.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Service d\'authentification non trouvé sur le serveur.';
        } else if (response.statusCode == 401) {
          errorMessage = 'Identifiants incorrects.';
        } else {
          errorMessage = 'Erreur serveur (${response.statusCode}). Veuillez réessayer.';
        }
        
        return AuthResponse(
          success: false,
          message: errorMessage,
        );
      }

      final responseData = json.decode(response.body);
      
      // Vérifier si la réponse a le bon format
      if (responseData is! Map<String, dynamic>) {
        return AuthResponse(
          success: false,
          message: 'Format de réponse invalide',
        );
      }

      // Log des données reçues pour debug
      DebugLogger.log('Parsing response: ${responseData.keys}');
      
      final authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.success && authResponse.data != null) {
        // Sauvegarder le token et les données utilisateur
        await _saveAuthData(authResponse.data!);
      }

      return authResponse;
    } catch (e) {
      DebugLogger.error('Login failed', e);
      return AuthResponse(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  // Inscription
  Future<AuthResponse> register(Map<String, dynamic> registerData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerEndpoint.fullUrl),
        headers: _headers,
        body: json.encode(registerData),
      );

      final authResponse = AuthResponse.fromJson(json.decode(response.body));

      if (authResponse.success && authResponse.data != null) {
        await _saveAuthData(authResponse.data!);
      }

      return authResponse;
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Erreur d\'inscription: $e',
      );
    }
  }

  // Déconnexion
  Future<bool> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse(ApiConfig.logoutEndpoint.fullUrl),
          headers: await _authHeaders,
        );
      }

      await _clearAuthData();
      return true;
    } catch (e) {
      // Même en cas d'erreur, on supprime les données locales
      await _clearAuthData();
      return false;
    }
  }

  // Récupérer le profil utilisateur
  Future<User?> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.userProfileEndpoint.fullUrl),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Mot de passe oublié
  Future<AuthResponse> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPasswordEndpoint.fullUrl),
        headers: _headers,
        body: json.encode({'email': email}),
      );

      return AuthResponse.fromJson(json.decode(response.body));
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Erreur lors de l\'envoi: $e',
      );
    }
  }

  // Réinitialisation du mot de passe
  Future<AuthResponse> resetPassword(Map<String, dynamic> resetData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordEndpoint.fullUrl),
        headers: _headers,
        body: json.encode(resetData),
      );

      return AuthResponse.fromJson(json.decode(response.body));
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Erreur de réinitialisation: $e',
      );
    }
  }

  // Sauvegarder les données d'authentification
  Future<void> _saveAuthData(AuthData authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, authData.token);
    await prefs.setString(userKey, json.encode(authData.user.toJson()));
  }

  // Supprimer les données d'authentification
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  // Récupérer le token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Récupérer l'utilisateur sauvegardé
  Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);
    if (userData != null) {
      return User.fromJson(json.decode(userData));
    }
    return null;
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
