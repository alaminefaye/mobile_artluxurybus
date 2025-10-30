import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationApiService {
  static const String baseUrl = 'https://gestion-compagny.universaltechnologiesafrica.com/api';
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

      // Essayer d'abord l'endpoint temporaire qui fonctionne
      var uri = Uri.parse('$baseUrl/notifications/all').replace(queryParameters: queryParams);
      
      var response = await http.get(uri, headers: _headers);
      
      // Si l'endpoint /all ne fonctionne pas, essayer l'original
      if (response.statusCode == 404) {
        uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);
        response = await http.get(uri, headers: _headers);
      }
      
      final data = jsonDecode(response.body);
      
      // API call successful

      if (response.statusCode == 200) {
        return NotificationResponse.fromJson(data);
      } else {
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
