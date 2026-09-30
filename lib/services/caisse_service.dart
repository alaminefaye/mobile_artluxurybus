import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/api_config.dart';
import '../utils/error_message_helper.dart';

class CaisseService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/caisse'), headers: _headers)
          .timeout(ApiConfig.requestTimeout);
      return _decode(response, 'charger la caisse');
    } catch (e) {
      return _error('charger la caisse', e);
    }
  }

  static Future<Map<String, dynamic>> createRecharge({
    required double montant,
    String? description,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/caisse/recharges'),
            headers: _headers,
            body: json.encode({
              'montant': montant,
              if (description != null && description.isNotEmpty)
                'description': description,
            }),
          )
          .timeout(ApiConfig.requestTimeout);
      return _decode(response, 'enregistrer la recharge');
    } catch (e) {
      return _error('enregistrer la recharge', e);
    }
  }

  static Future<Map<String, dynamic>> createDepense({
    required String motif,
    required double montant,
    String? description,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/caisse/depenses'),
            headers: _headers,
            body: json.encode({
              'motif': motif,
              'montant': montant,
              if (description != null && description.isNotEmpty)
                'description': description,
            }),
          )
          .timeout(ApiConfig.requestTimeout);
      return _decode(response, 'enregistrer la dépense');
    } catch (e) {
      return _error('enregistrer la dépense', e);
    }
  }

  static Future<Map<String, dynamic>> deleteRecharge(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/caisse/recharges/$id'),
            headers: _headers,
          )
          .timeout(ApiConfig.requestTimeout);
      return _decode(response, 'supprimer la recharge');
    } catch (e) {
      return _error('supprimer la recharge', e);
    }
  }

  static Future<Map<String, dynamic>> deleteDepense(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/caisse/depenses/$id'),
            headers: _headers,
          )
          .timeout(ApiConfig.requestTimeout);
      return _decode(response, 'supprimer la dépense');
    } catch (e) {
      return _error('supprimer la dépense', e);
    }
  }

  static Map<String, dynamic> _decode(http.Response response, String action) {
    final data = json.decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': data['success'] == true,
        'message': data['message'],
        'data': data['data'],
        'can_manage': data['can_manage'] == true,
      };
    }
    return {
      'success': false,
      'message': data['message'] ?? 'Erreur lors de l\'opération.',
    };
  }

  static Map<String, dynamic> _error(String action, Object error) {
    debugPrint('CaisseService $action: $error');
    return {
      'success': false,
      'message': ErrorMessageHelper.getOperationError(action, error: error),
    };
  }
}
