import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/error_message_helper.dart';

class PromoCodeService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  /// Lister les codes promotionnels (Super Admin et Admin uniquement)
  static Future<Map<String, dynamic>> getPromoCodes({
    String? search,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/promo-codes').replace(
        queryParameters: queryParams,
      );

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      debugPrint('🔄 [PromoCodeService] Récupération des codes promo...');
      debugPrint('🔄 [PromoCodeService] URL: $uri');

      final response = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);

      debugPrint('📡 [PromoCodeService] Réponse - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [PromoCodeService] Codes promo récupérés: ${data['data']?.length ?? 0}');
        return {
          'success': true,
          'data': data['data'],
          'pagination': data['pagination'],
        };
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        debugPrint('❌ [PromoCodeService] Accès refusé (403): ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Accès non autorisé.',
          'status_code': 403,
        };
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ [PromoCodeService] Erreur ${response.statusCode}: ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération des codes promo.',
          'status_code': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [PromoCodeService] Exception lors de la récupération des codes promo: $e');
      debugPrint('❌ [PromoCodeService] Stack trace: $stackTrace');
      return {
        'success': false,
        'message': ErrorMessageHelper.getOperationError('récupérer', error: e),
      };
    }
  }

  /// Créer un nouveau code promotionnel (Super Admin et Admin uniquement)
  static Future<Map<String, dynamic>> createPromoCode({
    required String customerName,
    String? description,
    String? expiresAt,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/promo-codes');

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final body = <String, dynamic>{
        'customer_name': customerName,
      };

      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      if (expiresAt != null && expiresAt.isNotEmpty) {
        body['expires_at'] = expiresAt;
      }

      debugPrint('🔄 [PromoCodeService] Création d\'un code promo...');
      debugPrint('🔄 [PromoCodeService] URL: $uri');
      debugPrint('🔄 [PromoCodeService] Body: $body');

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      ).timeout(ApiConfig.requestTimeout);

      debugPrint('📡 [PromoCodeService] Réponse - Status: ${response.statusCode}');
      debugPrint('📡 [PromoCodeService] Réponse - Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('✅ [PromoCodeService] Code promo créé: ${data['data']['code']}');
        return {
          'success': true,
          'message': data['message'] ?? 'Code promotionnel créé avec succès.',
          'data': data['data'],
        };
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        debugPrint('❌ [PromoCodeService] Accès refusé (403): ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Accès non autorisé.',
          'status_code': 403,
        };
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ [PromoCodeService] Erreur ${response.statusCode}: ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la création du code promo.',
          'errors': errorData['errors'],
          'status_code': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [PromoCodeService] Exception lors de la création du code promo: $e');
      debugPrint('❌ [PromoCodeService] Stack trace: $stackTrace');
      return {
        'success': false,
        'message': ErrorMessageHelper.getOperationError('créer', error: e),
      };
    }
  }

  /// Afficher les détails d'un code promotionnel (Super Admin et Admin uniquement)
  static Future<Map<String, dynamic>> getPromoCodeDetails(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/promo-codes/$id');

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      debugPrint('🔄 [PromoCodeService] Récupération des détails du code promo #$id...');
      debugPrint('🔄 [PromoCodeService] URL: $uri');

      final response = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);

      debugPrint('📡 [PromoCodeService] Réponse - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [PromoCodeService] Détails du code promo récupérés');
        return {
          'success': true,
          'data': data['data'],
        };
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        debugPrint('❌ [PromoCodeService] Accès refusé (403): ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Accès non autorisé.',
          'status_code': 403,
        };
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        debugPrint('❌ [PromoCodeService] Code promo non trouvé (404): ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Code promotionnel non trouvé.',
          'status_code': 404,
        };
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ [PromoCodeService] Erreur ${response.statusCode}: ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération des détails.',
          'status_code': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [PromoCodeService] Exception lors de la récupération des détails: $e');
      debugPrint('❌ [PromoCodeService] Stack trace: $stackTrace');
      return {
        'success': false,
        'message': ErrorMessageHelper.getOperationError('récupérer', error: e),
      };
    }
  }

  /// Supprimer un code promotionnel (Super Admin et Admin uniquement)
  static Future<Map<String, dynamic>> deletePromoCode(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/promo-codes/$id');

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      debugPrint('🔄 [PromoCodeService] Suppression du code promo #$id...');
      debugPrint('🔄 [PromoCodeService] URL: $uri');

      final response = await http.delete(uri, headers: headers).timeout(ApiConfig.requestTimeout);

      debugPrint('📡 [PromoCodeService] Réponse - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [PromoCodeService] Code promo supprimé');
        return {
          'success': true,
          'message': data['message'] ?? 'Code promotionnel supprimé avec succès.',
        };
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        debugPrint('❌ [PromoCodeService] Accès refusé (403): ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Accès non autorisé.',
          'status_code': 403,
        };
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        debugPrint('❌ [PromoCodeService] Code promo non trouvé (404): ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Code promotionnel non trouvé.',
          'status_code': 404,
        };
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ [PromoCodeService] Erreur ${response.statusCode}: ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la suppression du code promo.',
          'status_code': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [PromoCodeService] Exception lors de la suppression du code promo: $e');
      debugPrint('❌ [PromoCodeService] Stack trace: $stackTrace');
      return {
        'success': false,
        'message': ErrorMessageHelper.getOperationError('supprimer', error: e),
      };
    }
  }
}

