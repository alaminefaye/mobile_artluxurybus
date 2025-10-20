import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class FeedbackApiService {
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

  /// Créer une suggestion/préoccupation (endpoint public)
  static Future<Map<String, dynamic>> createFeedback({
    required String name,
    required String phone,
    required String subject,
    required String message,
    String? email,
    String? station,
    String? route,
    String? seatNumber,
    String? departureNumber,
    String? photoBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feedbacks'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'subject': subject,
          'message': message,
          if (email != null) 'email': email,
          if (station != null) 'station': station,
          if (route != null) 'route': route,
          if (seatNumber != null) 'seat_number': seatNumber,
          if (departureNumber != null) 'departure_number': departureNumber,
          if (photoBase64 != null) 'photo': photoBase64,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'envoi');
      }
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  /// Récupérer les statistiques des feedbacks (admin uniquement)
  static Future<Map<String, dynamic>> getFeedbackStats() async {
    if (_token == null) {
      throw Exception('Token d\'authentification requis');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feedbacks/admin/stats'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la récupération');
      }
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  /// Lister les feedbacks (admin uniquement)
  static Future<Map<String, dynamic>> getFeedbacks({
    int page = 1,
    int perPage = 15,
    String? status,
    String? search,
  }) async {
    if (_token == null) {
      throw Exception('Token d\'authentification requis');
    }

    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (status != null) 'status': status,
        if (search != null) 'search': search,
      };

      final uri = Uri.parse('$baseUrl/feedbacks').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la récupération');
      }
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  /// Mettre à jour le statut d'un feedback (admin uniquement)
  static Future<Map<String, dynamic>> updateFeedbackStatus(
    int feedbackId,
    String status,
  ) async {
    if (_token == null) {
      throw Exception('Token d\'authentification requis');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/feedbacks/$feedbackId/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
      }
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  /// Enregistrer token FCM pour notifications push
  static Future<Map<String, dynamic>> registerFcmToken(
    String token, {
    String? deviceType,
    String? deviceId,
  }) async {
    if (_token == null) {
      throw Exception('Token d\'authentification requis');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fcm/register-token'),
        headers: _headers,
        body: jsonEncode({
          'token': token,
          'device_type': deviceType ?? 'android',
          'device_id': deviceId,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'enregistrement');
      }
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  /// Tester la configuration des notifications
  static Future<Map<String, dynamic>> testNotificationConfig() async {
    if (_token == null) {
      throw Exception('Token d\'authentification requis');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/test-config'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Erreur de configuration');
      }
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }
}
