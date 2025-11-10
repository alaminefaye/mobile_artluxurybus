import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import 'auth_service.dart';

class EmbarkmentService {
  /// Récupérer le token d'authentification (dynamique)
  static Future<String?> _getToken() async {
    final authService = AuthService();
    return await authService.getToken();
  }

  /// Récupérer tous les départs disponibles pour l'embarquement
  static Future<Map<String, dynamic>> getDepartsForEmbarkment() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/embarkment/departs');
      final token = await _getToken();

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': data['message'] ?? 'Départs récupérés avec succès',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération des départs',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
        'data': [],
      };
    }
  }

  /// Récupérer les détails d'un départ avec ses statistiques
  static Future<Map<String, dynamic>> getDepartDetails(int departId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/embarkment/departs/$departId');
      final token = await _getToken();

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Détails récupérés avec succès',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération des détails',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Scanner un ticket QR code et le marquer comme utilisé
  static Future<Map<String, dynamic>> scanTicket({
    required int departId,
    required String qrCode,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/embarkment/departs/$departId/scan-ticket');
      final token = await _getToken();

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = json.encode({
        'qr_code': qrCode,
      });

      final response = await http.post(uri, headers: headers, body: body)
          .timeout(ApiConfig.requestTimeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Ticket scanné avec succès',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du scan du ticket',
          'data': null,
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Récupérer la liste des tickets scannés pour un départ
  static Future<Map<String, dynamic>> getScannedTickets(int departId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/embarkment/departs/$departId/scanned-tickets');
      final token = await _getToken();

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': data['message'] ?? 'Tickets récupérés avec succès',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération des tickets',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
        'data': [],
      };
    }
  }

  /// Rechercher des tickets par siège ou téléphone pour un départ
  static Future<Map<String, dynamic>> searchTickets({
    required int departId,
    required String searchTerm,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/embarkment/departs/$departId/search-tickets')
          .replace(queryParameters: {'search': searchTerm});
      final token = await _getToken();

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': data['message'] ?? 'Tickets trouvés avec succès',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la recherche',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
        'data': [],
      };
    }
  }
}

