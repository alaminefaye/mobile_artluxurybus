import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import 'package:flutter/foundation.dart';

class ExpenseService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Récupérer la liste des dépenses
  static Future<Map<String, dynamic>> getExpenses({
    String? search,
    String? status,
    int? employeeId,
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
        if (status != null && status.isNotEmpty) 'status': status,
        if (employeeId != null) 'employee_id': employeeId.toString(),
        if (dateStart != null && dateStart.isNotEmpty) 'date_start': dateStart,
        if (dateEnd != null && dateEnd.isNotEmpty) 'date_end': dateEnd,
        if (allDates) 'all_dates': '1',
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/expenses')
          .replace(queryParameters: queryParams);

      debugPrint('🔍 [EXPENSE SERVICE] Récupération des dépenses: $uri');

      final response = await http.get(uri, headers: _headers);

      debugPrint('📡 [EXPENSE SERVICE] Status: ${response.statusCode}');

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
          'message': data['message'] ?? 'Erreur lors de la récupération des dépenses',
        };
      }
    } catch (e) {
      debugPrint('❌ [EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupérer la liste des dépenses en attente
  static Future<Map<String, dynamic>> getPendingExpenses({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/expenses/pending')
          .replace(queryParameters: queryParams);

      debugPrint('🔍 [EXPENSE SERVICE] Récupération des dépenses en attente: $uri');

      final response = await http.get(uri, headers: _headers);

      debugPrint('📡 [EXPENSE SERVICE] Status: ${response.statusCode}');

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
          'message': data['message'] ?? 'Erreur lors de la récupération des dépenses en attente',
        };
      }
    } catch (e) {
      debugPrint('❌ [EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Créer une nouvelle dépense
  static Future<Map<String, dynamic>> createExpense({
    required String motif,
    required double montant,
    required String type,
    String? commentaire,
    int? employeeId,
  }) async {
    try {
      final body = <String, dynamic>{
        'motif': motif,
        'montant': montant,
        'type': type,
        if (commentaire != null && commentaire.isNotEmpty) 'commentaire': commentaire,
        if (employeeId != null) 'employee_id': employeeId,
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/expenses');

      debugPrint('➕ [EXPENSE SERVICE] Création d\'une dépense: $uri');
      debugPrint('📦 [EXPENSE SERVICE] Body: $body');

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );

      debugPrint('📡 [EXPENSE SERVICE] Status: ${response.statusCode}');
      debugPrint('📄 [EXPENSE SERVICE] Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Dépense créée avec succès',
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
          'message': data['message'] ?? 'Erreur lors de la création de la dépense',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      debugPrint('❌ [EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupérer les détails d'une dépense
  static Future<Map<String, dynamic>> getExpenseDetails(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/expenses/$id');

      debugPrint('🔍 [EXPENSE SERVICE] Récupération des détails de la dépense: $uri');

      final response = await http.get(uri, headers: _headers);

      debugPrint('📡 [EXPENSE SERVICE] Status: ${response.statusCode}');

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
          'message': data['message'] ?? 'Dépense non trouvée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la récupération des détails',
        };
      }
    } catch (e) {
      debugPrint('❌ [EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Valider une dépense
  static Future<Map<String, dynamic>> validateExpense({
    required int id,
    String? commentaire,
  }) async {
    try {
      final body = <String, dynamic>{
        if (commentaire != null && commentaire.isNotEmpty) 'commentaire': commentaire,
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/expenses/$id/validate');

      debugPrint('✅ [EXPENSE SERVICE] Validation de la dépense: $uri');
      debugPrint('📦 [EXPENSE SERVICE] Body: $body');

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );

      debugPrint('📡 [EXPENSE SERVICE] Status: ${response.statusCode}');
      debugPrint('📄 [EXPENSE SERVICE] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Dépense validée avec succès',
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
          'message': data['message'] ?? 'Dépense non trouvée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la validation de la dépense',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      debugPrint('❌ [EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Rejeter une dépense
  static Future<Map<String, dynamic>> rejectExpense({
    required int id,
    required String commentaire,
  }) async {
    try {
      final body = <String, dynamic>{
        'commentaire': commentaire,
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/expenses/$id/reject');

      debugPrint('❌ [EXPENSE SERVICE] Rejet de la dépense: $uri');
      debugPrint('📦 [EXPENSE SERVICE] Body: $body');

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );

      debugPrint('📡 [EXPENSE SERVICE] Status: ${response.statusCode}');
      debugPrint('📄 [EXPENSE SERVICE] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Dépense rejetée avec succès',
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
          'message': data['message'] ?? 'Dépense non trouvée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du rejet de la dépense',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      debugPrint('❌ [EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Supprimer une dépense
  static Future<Map<String, dynamic>> deleteExpense(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/expenses/$id');

      debugPrint('🗑️ [EXPENSE SERVICE] Suppression de la dépense: $uri');

      final response = await http.delete(uri, headers: _headers);

      debugPrint('📡 [EXPENSE SERVICE] Status: ${response.statusCode}');
      debugPrint('📄 [EXPENSE SERVICE] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Dépense supprimée avec succès',
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
          'message': data['message'] ?? 'Dépense non trouvée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la suppression de la dépense',
        };
      }
    } catch (e) {
      debugPrint('❌ [EXPENSE SERVICE] Erreur: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }
}

