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
        // Extraire un message d'erreur convivial
        String errorMessage = _extractUserFriendlyError(data, response.statusCode);
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('Pas de connexion internet. Veuillez vérifier votre connexion.');
    } on FormatException {
      throw Exception('Erreur de format des données. Veuillez réessayer.');
    } catch (e) {
      // Nettoyer le message d'erreur pour l'utilisateur
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      // Éviter d'afficher les erreurs SQL brutes
      if (errorMsg.contains('SQLSTATE') || errorMsg.contains('Integrity constraint')) {
        errorMsg = 'Une erreur s\'est produite. Veuillez vérifier vos informations et réessayer.';
      }
      throw Exception(errorMsg);
    }
  }

  /// Extraire un message d'erreur convivial depuis la réponse API
  static String _extractUserFriendlyError(Map<String, dynamic> data, int statusCode) {
    // Vérifier les différents formats de messages d'erreur
    
    // 1. Message direct
    if (data['message'] != null && data['message'] is String) {
      String msg = data['message'];
      // Éviter les messages SQL
      if (!msg.contains('SQLSTATE') && !msg.contains('Integrity constraint')) {
        return msg;
      }
    }
    
    // 2. Erreurs de validation Laravel
    if (data['errors'] != null && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      if (errors.isNotEmpty) {
        // Prendre la première erreur
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        return firstError.toString();
      }
    }
    
    // 3. Erreur dans data.error
    if (data['error'] != null) {
      return data['error'].toString();
    }
    
    // 4. Messages par défaut selon le code HTTP
    switch (statusCode) {
      case 400:
        return 'Données invalides. Veuillez vérifier les informations saisies.';
      case 401:
        return 'Non autorisé. Veuillez vous reconnecter.';
      case 403:
        return 'Accès refusé.';
      case 404:
        return 'Service non trouvé. Veuillez réessayer plus tard.';
      case 422:
        return 'Données invalides. Veuillez vérifier tous les champs requis.';
      case 500:
        return 'Erreur serveur. Veuillez réessayer dans quelques instants.';
      case 503:
        return 'Service temporairement indisponible. Veuillez réessayer plus tard.';
      default:
        return 'Une erreur s\'est produite. Veuillez réessayer.';
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
