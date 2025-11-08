import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';

class RechargeService {
  static const String baseUrl = 'https://skf-artluxurybus.com/api';
  static String? _token;

  static void setToken(String token) {
    _token = token;
    debugPrint('🔑 RechargeService - Token défini: ✅');
  }

  // Récupérer le token dynamiquement depuis AuthService
  static Future<String?> _getAuthToken() async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token != null) {
      _token = token;
      debugPrint('🔑 RechargeService - Token récupéré depuis AuthService: ✅');
    } else {
      debugPrint('🔑 RechargeService - Token récupéré depuis AuthService: ❌ (null)');
    }
    return token ?? _token;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Initier un paiement Wave pour recharger le solde
  static Future<Map<String, dynamic>> recharge({
    required double montant,
    required String modePaiement,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/recharge');
      
      final body = jsonEncode({
        'montant': montant,
        'mode_paiement': modePaiement,
      });

      debugPrint('💰 [RechargeService] Initiation du paiement Wave...');
      debugPrint('💰 Montant: $montant FCFA');
      debugPrint('💰 Mode de paiement: $modePaiement');

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 [RechargeService] Réponse API - Status: ${response.statusCode}');
      debugPrint('📡 [RechargeService] Réponse API - Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        debugPrint('✅ [RechargeService] Paiement Wave initié');
        final paymentUrl = data['data']?['payment_url'];
        
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          // Ouvrir l'URL de paiement Wave
          final uri = Uri.parse(paymentUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            debugPrint('✅ [RechargeService] URL de paiement Wave ouverte');
          } else {
            debugPrint('❌ [RechargeService] Impossible d\'ouvrir l\'URL de paiement');
            return {
              'success': false,
              'message': 'Impossible d\'ouvrir la page de paiement Wave',
            };
          }
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Paiement Wave initié avec succès',
          'data': data['data'],
        };
      } else {
        final errorMessage = data['message'] ?? 
            data['error'] ?? 
            'Erreur lors de l\'initiation du paiement';
        debugPrint('❌ [RechargeService] Erreur d\'initiation: $errorMessage');
        debugPrint('❌ [RechargeService] Code status: ${response.statusCode}');
        debugPrint('❌ [RechargeService] Données complètes: $data');
        
        return {
          'success': false,
          'message': errorMessage.toString(),
          'errors': data['errors'],
          'error': data['error'],
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('❌ [RechargeService] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion. Vérifiez votre connexion internet.',
        'error': e.toString(),
      };
    }
  }

  /// Récupérer le solde actuel
  static Future<Map<String, dynamic>> getSolde() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/recharge/solde');

      debugPrint('💰 [RechargeService] Récupération du solde...');
      debugPrint('💰 [RechargeService] URL: $uri');
      debugPrint('💰 [RechargeService] Headers: ${headers.keys.toList()}');

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 [RechargeService] Réponse - Status: ${response.statusCode}');
      debugPrint('📡 [RechargeService] Réponse - Body: ${response.body}');

      // Vérifier si la réponse est vide
      if (response.body.isEmpty) {
        debugPrint('❌ [RechargeService] Réponse vide');
        return {
          'success': false,
          'solde': 0.0,
          'message': 'Réponse serveur vide',
        };
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('❌ [RechargeService] Erreur de parsing JSON: $e');
        debugPrint('❌ [RechargeService] Body brut: ${response.body}');
        return {
          'success': false,
          'solde': 0.0,
          'message': 'Erreur de format de réponse',
          'error': e.toString(),
        };
      }

      if (response.statusCode == 200 && data['success'] == true) {
        final solde = data['solde'];
        debugPrint('✅ [RechargeService] Solde récupéré: $solde FCFA (type: ${solde.runtimeType})');
        return {
          'success': true,
          'solde': solde ?? 0.0,
          'client': data['client'],
        };
      } else {
        final errorMessage = data['message'] ?? 
            data['error'] ?? 
            'Erreur lors de la récupération du solde';
        debugPrint('❌ [RechargeService] Erreur de récupération du solde');
        debugPrint('❌ [RechargeService] Code status: ${response.statusCode}');
        debugPrint('❌ [RechargeService] Message: $errorMessage');
        debugPrint('❌ [RechargeService] Données complètes: $data');
        
        return {
          'success': false,
          'solde': 0.0,
          'message': errorMessage.toString(),
          'error': data['error'],
          'status_code': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [RechargeService] Exception lors de la récupération du solde: $e');
      debugPrint('❌ [RechargeService] Stack trace: $stackTrace');
      return {
        'success': false,
        'solde': 0.0,
        'message': 'Erreur de connexion. Vérifiez votre connexion internet.',
        'error': e.toString(),
      };
    }
  }
}

