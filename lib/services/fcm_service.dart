import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static const String _baseUrl = 'https://skf-artluxurybus.com/api';
  
  /// Initialiser FCM pour un utilisateur connecté
  static Future<void> initializeFCMForUser(String userId, String authToken) async {
    try {
      // 1. Demander permission pour les notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Obtenir le token FCM
        String? token = await _firebaseMessaging.getToken();
        
        if (token != null) {
          // 3. Envoyer le token au serveur avec l'ID utilisateur
          await _sendTokenToServer(token, userId, authToken);
          
          // 4. Sauvegarder le token localement
          await _saveTokenLocally(token, userId);
          
        }
      }
    } catch (e) {
      // Erreur ignorée en production
    }
  }

  /// Nettoyer FCM lors de la déconnexion
  static Future<void> cleanupFCMForUser(String userId, String authToken) async {
    try {
      // 1. Récupérer le token actuel
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentToken = prefs.getString('fcm_token_$userId');
      
      if (currentToken != null) {
        // 2. Désactiver le token sur le serveur
        await _deactivateTokenOnServer(currentToken, authToken);
        
        // 3. Supprimer le token localement
        await prefs.remove('fcm_token_$userId');
        await prefs.remove('fcm_user_id');
        
      }
      
      // 4. Supprimer le token de Firebase (optionnel)
      await _firebaseMessaging.deleteToken();
      
    } catch (e) {
      // Erreur ignorée en production
    }
  }

  /// Envoyer le token au serveur Laravel
  static Future<void> _sendTokenToServer(String token, String userId, String authToken) async {
    try {
      final deviceId = await _getDeviceId();
      final requestBody = {
        'token': token, // Laravel attend 'token'
        'fcm_token': token, // Aussi pour compatibilité
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'device_id': deviceId,
      };
      
      
      final response = await http.post(
        Uri.parse('$_baseUrl/fcm/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
      } else if (response.statusCode == 403) {
        // Utilisateur Pointage - c'est normal qu'il soit bloqué
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['code'] != 'FCM_BLOCKED_POINTAGE') {
            // Log only if not the expected pointage block
          }
        } catch (e) {
          // Erreur d'accès - ignorée en production
        }
      } else if (response.statusCode == 422) {
        // Erreur de validation - ignorée en production
      } else {
        // Erreur serveur - ignorée en production
      }
    } catch (e) {
      // Erreur ignorée en production
    }
  }

  /// Désactiver le token sur le serveur
  static Future<void> _deactivateTokenOnServer(String token, String authToken) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/fcm/delete-all'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
      } else {
      }
    } catch (e) {
      // Erreur ignorée en production
    }
  }

  /// Sauvegarder le token localement
  static Future<void> _saveTokenLocally(String token, String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token_$userId', token);
    await prefs.setString('fcm_user_id', userId);
  }

  /// Obtenir l'ID de l'appareil
  static Future<String> _getDeviceId() async {
    // Vous pouvez utiliser device_info_plus pour obtenir un ID unique
    return 'mobile_device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Vérifier si l'utilisateur actuel a un token valide
  static Future<bool> hasValidTokenForUser(String userId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedUserId = prefs.getString('fcm_user_id');
      String? savedToken = prefs.getString('fcm_token_$userId');
      
      return savedUserId == userId && savedToken != null;
    } catch (e) {
      return false;
    }
  }

  /// Nettoyer tous les tokens (sécurité)
  static Future<void> cleanupAllTokens() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Supprimer tous les tokens FCM sauvegardés
      Set<String> keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('fcm_token_') || key == 'fcm_user_id') {
          await prefs.remove(key);
        }
      }
      
      // Supprimer le token Firebase
      await _firebaseMessaging.deleteToken();
      
    } catch (e) {
      // Erreur ignorée en production
    }
  }
}
