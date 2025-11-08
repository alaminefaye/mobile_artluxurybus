import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationApiService {
  static const String baseUrl = 'https://skf-artluxurybus.com/api';
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Récupérer toutes les notifications de l'utilisateur
  static Future<NotificationResponse> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (unreadOnly) 'unread_only': '1',
      };

      debugPrint('🔔 [API] Récupération des notifications');
      debugPrint('🔔 [API] Page: $page, Limit: $limit, UnreadOnly: $unreadOnly');
      debugPrint('🔑 [API] Token: ${_token != null ? "Défini" : "NON DÉFINI"}');

      // Utiliser l'endpoint principal /notifications
      var uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);
      debugPrint('🌐 [API] URL: $uri');
      
      var response = await http.get(uri, headers: _headers);
      
      debugPrint('📡 [API] Status: ${response.statusCode}');
      debugPrint('📄 [API] Body: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        debugPrint('✅ [API] Notifications récupérées avec succès');
        if (data['data'] != null && data['data']['notifications'] != null) {
          final notifications = data['data']['notifications'] as List;
          debugPrint('📋 [API] Nombre de notifications: ${notifications.length}');
          if (notifications.isNotEmpty) {
            debugPrint('📋 [API] Types de notifications: ${notifications.map((n) => n['type']).toSet().join(", ")}');
            debugPrint('📋 [API] Première notification: type=${notifications[0]['type']}, title=${notifications[0]['title']}');
          }
        }
        return NotificationResponse.fromJson(data);
      } else {
        debugPrint('❌ [API] Erreur: ${data['message'] ?? 'Erreur inconnue'}');
        return NotificationResponse(
          success: false,
          message: data['message'] ?? 'Service de notifications en cours de mise à jour',
          notifications: [],
        );
      }
    } on SocketException {
      return NotificationResponse(
        success: false,
        message: 'Pas de connexion internet',
        notifications: [],
      );
    } catch (e) {
      return NotificationResponse(
        success: false,
        message: 'Erreur: $e',
        notifications: [],
      );
    }
  }

  /// Marquer une notification comme lue
  static Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      debugPrint('🔔 [API] Marquage notification $notificationId comme lue');
      debugPrint('🔑 [API] Token: ${_token != null ? "Défini (${_token!.substring(0, 10)}...)" : "NON DÉFINI"}');
      
      final url = '$baseUrl/notifications/$notificationId/read';
      debugPrint('🌐 [API] URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
      );
      
      debugPrint('📡 [API] Status: ${response.statusCode}');
      debugPrint('📄 [API] Body: ${response.body}');
      
      if (response.statusCode == 401) {
        debugPrint('❌ [API] NON AUTORISÉ - Token invalide ou expiré');
      }
      
      if (response.statusCode == 404) {
        debugPrint('❌ [API] NOTIFICATION INTROUVABLE');
      }
      
      if (response.statusCode == 403) {
        debugPrint('❌ [API] ACCÈS REFUSÉ - Notification d\'un autre utilisateur');
      }

      return jsonDecode(response.body);
    } on SocketException {
      debugPrint('❌ [API] Pas de connexion internet');
      return {'success': false, 'message': 'Pas de connexion internet'};
    } catch (e) {
      debugPrint('❌ [API] Exception: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Marquer toutes les notifications comme lues
  static Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      debugPrint('🔔 [API] Marquage de TOUTES les notifications comme lues');
      debugPrint('🔑 [API] Token: ${_token != null ? "Défini" : "NON DÉFINI"}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: _headers,
      );
      
      debugPrint('📡 [API] Status: ${response.statusCode}');
      debugPrint('📄 [API] Body: ${response.body}');

      return jsonDecode(response.body);
    } on SocketException {
      debugPrint('❌ [API] Pas de connexion internet');
      return {'success': false, 'message': 'Pas de connexion internet'};
    } catch (e) {
      debugPrint('❌ [API] Exception: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Supprimer une notification
  static Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      debugPrint('🗑️ [API] Suppression notification $notificationId');
      debugPrint('🔑 [API] Token: ${_token != null ? "Défini" : "NON DÉFINI"}');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: _headers,
      );
      
      debugPrint('📡 [API] Status: ${response.statusCode}');
      debugPrint('📄 [API] Body: ${response.body}');

      return jsonDecode(response.body);
    } on SocketException {
      debugPrint('❌ [API] Pas de connexion internet');
      return {'success': false, 'message': 'Pas de connexion internet'};
    } catch (e) {
      debugPrint('❌ [API] Exception: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Supprimer toutes les notifications
  static Future<Map<String, dynamic>> deleteAllNotifications() async {
    try {
      debugPrint('🗑️ [API] Suppression de TOUTES les notifications');
      debugPrint('🔑 [API] Token: ${_token != null ? "Défini (${_token!.substring(0, 10)}...)" : "NON DÉFINI"}');
      debugPrint('🌐 [API] URL: $baseUrl/notifications/delete-all');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/delete-all'),
        headers: _headers,
      );
      
      debugPrint('📡 [API] Status: ${response.statusCode}');
      debugPrint('📄 [API] Body: ${response.body}');

      if (response.statusCode == 401) {
        debugPrint('❌ [API] NON AUTORISÉ - Token invalide ou expiré');
        return {'success': false, 'message': 'Vous devez vous reconnecter'};
      }

      if (response.statusCode == 404) {
        debugPrint('❌ [API] Route non trouvée');
        return {'success': false, 'message': 'Route non trouvée. Veuillez vérifier la configuration du serveur.'};
      }

      final data = jsonDecode(response.body);
      return data;
    } on SocketException {
      debugPrint('❌ [API] Pas de connexion internet');
      return {'success': false, 'message': 'Pas de connexion internet'};
    } catch (e) {
      debugPrint('❌ [API] Exception: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Obtenir le nombre de notifications non lues
  static Future<int> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
