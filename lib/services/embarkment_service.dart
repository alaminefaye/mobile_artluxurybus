import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class EmbarkmentService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  /// Récupérer tous les départs disponibles pour l'embarquement
  static Future<Map<String, dynamic>> getDepartsForEmbarkment() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/embarkment/departs');

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
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

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
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

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
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

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
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
}

