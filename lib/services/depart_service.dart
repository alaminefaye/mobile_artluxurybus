import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class DepartService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  /// Rechercher des départs disponibles
  /// 
  /// Paramètres:
  /// - embarquement: Ville d'embarquement
  /// - destination: Ville de destination
  /// - dateDepart: Date de départ (format: YYYY-MM-DD)
  /// - nombreSieges: Nombre de sièges requis (optionnel, limite à 5 résultats si spécifié)
  static Future<Map<String, dynamic>> searchDeparts({
    String? embarquement,
    String? destination,
    String? dateDepart,
    int? nombreSieges,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/departs/search').replace(
        queryParameters: {
          if (embarquement != null && embarquement.isNotEmpty) 'embarquement': embarquement,
          if (destination != null && destination.isNotEmpty) 'destination': destination,
          if (dateDepart != null && dateDepart.isNotEmpty) 'date_depart': dateDepart,
          if (nombreSieges != null && nombreSieges > 0) 'nombre_sieges': nombreSieges.toString(),
        },
      );

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la recherche: ${response.statusCode}',
          'data': [],
          'count': 0,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
        'data': [],
        'count': 0,
      };
    }
  }

  /// Récupérer la liste des villes d'embarquement disponibles
  static Future<List<String>> getEmbarquements() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/departs/embarquements');
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<String>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Récupérer la liste des destinations disponibles
  static Future<List<String>> getDestinations() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/departs/destinations');
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<String>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

