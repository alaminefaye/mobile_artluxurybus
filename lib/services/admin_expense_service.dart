import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';

class AdminExpenseService {
  static final AuthService _authService = AuthService();

  static Future<Map<String, String>> get _headers async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Récupérer la liste des dépenses admin
  static Future<Map<String, dynamic>> getAdminExpenses({
    String? search,
    String? typeDepense,
    String? dateStart,
    String? dateEnd,
    bool allDates = false,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (typeDepense != null && typeDepense.isNotEmpty) 'type_depense': typeDepense,
        if (dateStart != null && dateStart.isNotEmpty) 'date_start': dateStart,
        if (dateEnd != null && dateEnd.isNotEmpty) 'date_end': dateEnd,
        if (allDates) 'all_dates': '1',
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/admin-expenses')
          .replace(queryParameters: queryParams);

      debugPrint('🔍 [ADMIN EXPENSE SERVICE] Récupération des dépenses admin: $uri');

      final response = await http.get(uri, headers: await _headers);

      debugPrint('📡 [ADMIN EXPENSE SERVICE] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Accès non autorisé',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la récupération des dépenses admin',
        };
      }
    } catch (e) {
      debugPrint('❌ [ADMIN EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Créer une nouvelle dépense admin
  static Future<Map<String, dynamic>> createAdminExpense({
    required String typeDepense,
    required String titre,
    required double montant,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{
        'type_depense': typeDepense,
        'titre': titre,
        'montant': montant,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/admin-expenses');

      debugPrint('➕ [ADMIN EXPENSE SERVICE] Création d\'une dépense admin: $uri');
      debugPrint('📦 [ADMIN EXPENSE SERVICE] Body: $body');

      final response = await http.post(
        uri,
        headers: await _headers,
        body: jsonEncode(body),
      );

      debugPrint('📡 [ADMIN EXPENSE SERVICE] Status: ${response.statusCode}');
      debugPrint('📄 [ADMIN EXPENSE SERVICE] Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Dépense admin créée avec succès',
          'data': data['data'],
        };
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Accès non autorisé',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la création de la dépense admin',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      debugPrint('❌ [ADMIN EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupérer les détails d'une dépense admin
  static Future<Map<String, dynamic>> getAdminExpenseDetails(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/admin-expenses/$id');

      debugPrint('🔍 [ADMIN EXPENSE SERVICE] Récupération des détails de la dépense admin: $uri');

      final response = await http.get(uri, headers: await _headers);

      debugPrint('📡 [ADMIN EXPENSE SERVICE] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Accès non autorisé',
        };
      } else if (response.statusCode == 404) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Dépense admin non trouvée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la récupération des détails',
        };
      }
    } catch (e) {
      debugPrint('❌ [ADMIN EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Mettre à jour une dépense admin
  static Future<Map<String, dynamic>> updateAdminExpense({
    required int id,
    required String typeDepense,
    required String titre,
    required double montant,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{
        'type_depense': typeDepense,
        'titre': titre,
        'montant': montant,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/admin-expenses/$id');

      debugPrint('✏️ [ADMIN EXPENSE SERVICE] Mise à jour de la dépense admin: $uri');
      debugPrint('📦 [ADMIN EXPENSE SERVICE] Body: $body');

      final response = await http.put(
        uri,
        headers: await _headers,
        body: jsonEncode(body),
      );

      debugPrint('📡 [ADMIN EXPENSE SERVICE] Status: ${response.statusCode}');
      debugPrint('📄 [ADMIN EXPENSE SERVICE] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Dépense admin mise à jour avec succès',
          'data': data['data'],
        };
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Accès non autorisé',
        };
      } else if (response.statusCode == 404) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Dépense admin non trouvée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour de la dépense admin',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      debugPrint('❌ [ADMIN EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Supprimer une dépense admin
  static Future<Map<String, dynamic>> deleteAdminExpense(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/admin-expenses/$id');

      debugPrint('🗑️ [ADMIN EXPENSE SERVICE] Suppression de la dépense admin: $uri');

      final response = await http.delete(uri, headers: await _headers);

      debugPrint('📡 [ADMIN EXPENSE SERVICE] Status: ${response.statusCode}');
      debugPrint('📄 [ADMIN EXPENSE SERVICE] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Dépense admin supprimée avec succès',
        };
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Accès non autorisé',
        };
      } else if (response.statusCode == 404) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Dépense admin non trouvée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la suppression de la dépense admin',
        };
      }
    } catch (e) {
      debugPrint('❌ [ADMIN EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupérer les statistiques des dépenses admin
  static Future<Map<String, dynamic>> getStatistics({
    String? search,
    String? typeDepense,
    String? dateStart,
    String? dateEnd,
    bool allDates = false,
  }) async {
    try {
      final queryParams = <String, String>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (typeDepense != null && typeDepense.isNotEmpty) 'type_depense': typeDepense,
        if (dateStart != null && dateStart.isNotEmpty) 'date_start': dateStart,
        if (dateEnd != null && dateEnd.isNotEmpty) 'date_end': dateEnd,
        if (allDates) 'all_dates': '1',
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/admin-expenses/statistics')
          .replace(queryParameters: queryParams);

      debugPrint('📊 [ADMIN EXPENSE SERVICE] Récupération des statistiques: $uri');

      final response = await http.get(uri, headers: await _headers);

      debugPrint('📡 [ADMIN EXPENSE SERVICE] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Accès non autorisé',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la récupération des statistiques',
        };
      }
    } catch (e) {
      debugPrint('❌ [ADMIN EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }
}

