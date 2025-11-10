import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/safe_auth_response.dart';
import '../models/login_request.dart';
import '../utils/api_config.dart';
import '../utils/error_message_helper.dart';

class SafeAuthService {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Headers par défaut
  Map<String, String> get _headers => ApiConfig.defaultHeaders;

  // Connexion ultra-sécurisée
  Future<SafeAuthResponse> login(LoginRequest loginRequest) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint.fullUrl),
        headers: _headers,
        body: json.encode(loginRequest.toJson()),
      );


      if (response.statusCode != 200) {
        return SafeAuthResponse(
          success: false,
          message: 'Erreur serveur: ${response.statusCode}',
        );
      }

      // Parsing ultra-sécurisé
      dynamic responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        return SafeAuthResponse(
          success: false,
          message: 'Réponse JSON invalide',
        );
      }
      
      if (responseData is! Map<String, dynamic>) {
        return SafeAuthResponse(
          success: false,
          message: 'Format de réponse invalide',
        );
      }

      
      // Utilisation du parsing ultra-sécurisé
      final authResponse = SafeAuthResponse.fromJson(responseData);

      if (authResponse.success && authResponse.data != null) {
        // Sauvegarder le token et les données utilisateur
        await _saveAuthData(authResponse.data!);
      }

      return authResponse;
    } catch (e) {
      return SafeAuthResponse(
        success: false,
        message: ErrorMessageHelper.getUserFriendlyError(
          e,
          defaultMessage: 'Impossible de se connecter. Vérifiez vos identifiants et votre connexion internet.',
        ),
      );
    }
  }

  // Sauvegarder les données d'authentification
  Future<void> _saveAuthData(SafeAuthData authData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, authData.token);
      await prefs.setString(userKey, json.encode(authData.user.toJson()));
    } catch (e) {
      // Erreur ignorée en production
    }
  }

  // Supprimer les données d'authentification
  Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(userKey);
    } catch (e) {
      // Erreur ignorée en production
    }
  }

  // Récupérer le token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Récupérer l'utilisateur sauvegardé
  Future<SafeUser?> getSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(userKey);
      if (userData != null) {
        return SafeUser.fromJson(json.decode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
