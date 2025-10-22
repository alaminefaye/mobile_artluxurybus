import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/debug_logger.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static const String _baseUrl = 'https://gestion-compagny.universaltechnologiesafrica.com/api';
  
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
          
          DebugLogger.log('✅ FCM Token initialisé pour utilisateur: $userId');
          DebugLogger.log('Token: ${token.substring(0, 20)}...');
        }
      }
    } catch (e) {
      DebugLogger.error('❌ Erreur initialisation FCM', e);
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
        
        DebugLogger.log('✅ FCM Token nettoyé pour utilisateur: $userId');
      }
      
      // 4. Supprimer le token de Firebase (optionnel)
      await _firebaseMessaging.deleteToken();
      
    } catch (e) {
      DebugLogger.error('❌ Erreur nettoyage FCM', e);
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
      
      // Log des données envoyées pour debug
      DebugLogger.log('📤 Envoi token au serveur:');
      DebugLogger.log('   URL: $_baseUrl/fcm/register-token');
      DebugLogger.log('   Device Type: ${requestBody['device_type']}');
      DebugLogger.log('   Device ID: $deviceId');
      DebugLogger.log('   Token (début): ${token.substring(0, 20)}...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/fcm/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      DebugLogger.log('📥 Réponse serveur: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        DebugLogger.log('✅ Token FCM envoyé au serveur avec succès');
      } else if (response.statusCode == 403) {
        // Utilisateur Pointage - c'est normal qu'il soit bloqué
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['code'] == 'FCM_BLOCKED_POINTAGE') {
            DebugLogger.log('ℹ️ Token FCM bloqué pour utilisateur Pointage (normal)');
          } else {
            DebugLogger.error('❌ Accès refusé: ${response.statusCode}');
            DebugLogger.log('   Réponse: ${response.body}');
          }
        } catch (e) {
          DebugLogger.error('❌ Accès refusé: ${response.statusCode}');
        }
      } else if (response.statusCode == 422) {
        // Erreur de validation
        DebugLogger.error('❌ Erreur de validation (422)');
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            DebugLogger.log('   Message: ${errorData['message'] ?? 'Erreur inconnue'}');
            if (errorData['errors'] != null) {
              DebugLogger.log('   Erreurs de validation:');
              (errorData['errors'] as Map).forEach((key, value) {
                DebugLogger.log('      - $key: ${value is List ? value.join(', ') : value}');
              });
            }
          } catch (e) {
            DebugLogger.log('   Corps brut: ${response.body}');
          }
        }
      } else {
        DebugLogger.error('❌ Erreur envoi token: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            DebugLogger.log('   Détails: ${errorData['message'] ?? 'Erreur inconnue'}');
          } catch (e) {
            DebugLogger.log('   Corps de réponse: ${response.body}');
          }
        }
      }
    } catch (e) {
      DebugLogger.error('❌ Erreur réseau envoi token', e);
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
        DebugLogger.log('✅ Token FCM désactivé sur le serveur');
      } else {
        DebugLogger.error('❌ Erreur désactivation token: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('❌ Erreur réseau désactivation token', e);
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
      
      DebugLogger.log('✅ Tous les tokens FCM nettoyés');
    } catch (e) {
      DebugLogger.error('❌ Erreur nettoyage complet', e);
    }
  }
}
