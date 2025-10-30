import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simple_auth_models.dart';
// LoginRequest maintenant dans simple_auth_models.dart
import '../models/user.dart';
import '../utils/api_config.dart';
import 'fcm_service.dart';

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


      if (response.statusCode != 200) {
        
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

      
      final authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.success && authResponse.data != null) {
        // Sauvegarder le token et les données utilisateur
        await _saveAuthData(authResponse.data!);
        
        // 🔥 NOUVEAU: Initialiser FCM pour le nouvel utilisateur
        await _initializeFCMForUser(authResponse.data!);
      }

      return authResponse;
    } catch (e) {
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
      final user = await getSavedUser();
      
      if (token != null) {
        // 🔥 NOUVEAU: Nettoyer FCM avant la déconnexion
        if (user != null) {
          await _cleanupFCMForUser(user, token);
        }
        
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
      // Nettoyage FCM de sécurité
      await FCMService.cleanupAllTokens();
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

  // Sauvegarder uniquement l'utilisateur
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, json.encode(user.toJson()));
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

  // 🔥 NOUVEAU: Initialiser FCM pour un utilisateur
  Future<void> _initializeFCMForUser(AuthData authData) async {
    try {
      
      // Nettoyer d'abord tous les anciens tokens (sécurité)
      await FCMService.cleanupAllTokens();
      
      // Initialiser FCM pour le nouvel utilisateur
      await FCMService.initializeFCMForUser(
        authData.user.id.toString(),
        authData.token,
      );
      
    } catch (e) {
      // Erreur ignorée en production
    }
  }

  // 🔥 NOUVEAU: Nettoyer FCM pour un utilisateur
  Future<void> _cleanupFCMForUser(User user, String token) async {
    try {
      
      await FCMService.cleanupFCMForUser(
        user.id.toString(),
        token,
      );
      
    } catch (e) {
      // En cas d'erreur, nettoyage de sécurité
      await FCMService.cleanupAllTokens();
    }
  }

  // 🔥 NOUVEAU: Vérifier et réparer FCM si nécessaire
  Future<void> ensureFCMIsValid() async {
    try {
      final user = await getSavedUser();
      final token = await getToken();
      
      if (user != null && token != null) {
        // Vérifier si l'utilisateur a un token valide
        bool hasValidToken = await FCMService.hasValidTokenForUser(user.id.toString());
        
        if (!hasValidToken) {
          await _initializeFCMForUser(AuthData(
            user: user, 
            token: token,
            tokenType: 'Bearer',
          ));
        }
      }
    } catch (e) {
      // Erreur ignorée en production
    }
  }

  // Mise à jour du profil utilisateur
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final headers = await _authHeaders;
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/user/profile'),
        headers: headers,
        body: json.encode({
          'name': name,
          'email': email,
        }),
      );


      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Mettre à jour l'utilisateur sauvegardé localement
        if (data['data'] != null && data['data']['user'] != null) {
          final updatedUser = User.fromJson(data['data']['user']);
          await _saveUser(updatedUser);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Profil mis à jour avec succès',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  // Changement de mot de passe
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final headers = await _authHeaders;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user/change-password'),
        headers: headers,
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        }),
      );


      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mot de passe changé avec succès',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du changement de mot de passe',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  // Upload de photo de profil
  Future<Map<String, dynamic>> uploadAvatar(File avatarFile) async {
    try {
      final headers = await _authHeaders;
      
      // Créer une requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/user/upload-avatar'),
      );

      // Ajouter les headers
      request.headers.addAll(headers);

      // Ajouter le fichier
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
        ),
      );

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);


      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Mettre à jour l'utilisateur sauvegardé localement
        final user = await getSavedUser();
        if (user != null && data['data'] != null) {
          // Créer un nouvel utilisateur avec la photo mise à jour
          final updatedUser = user.copyWith(
            profilePhoto: data['data']['profile_photo'],
          );
          await _saveUser(updatedUser);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Photo de profil mise à jour avec succès',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'upload',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  // Vérifier si l'utilisateur connecté est un administrateur
  Future<bool> isUserAdmin() async {
    try {
      final user = await getSavedUser();
      if (user == null) return false;
      
      // Vérifier le rôle ou les permissions
      return user.role == 'Super Admin' || 
             user.role == 'Admin' || 
             user.role == 'RH' || 
             (user.permissions?.contains('manage_horaires') ?? false);
    } catch (e) {
      return false;
    }
  }
}
