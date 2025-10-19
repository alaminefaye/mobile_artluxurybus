import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/simple_loyalty_models.dart';
import '../utils/api_config.dart';

class LoyaltyService {
  // Debug uniquement en mode développement
  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[LoyaltyService] $message');
    }
  }
  static const String _baseUrl = '${ApiConfig.baseUrl}/loyalty';

  // Vérifier les points d'un client
  static Future<LoyaltyResponse> checkPoints(String phone) async {
    try {
      final request = LoyaltyCheckRequest(phone: phone);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/check-points'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      _debugLog('Check Points Response: ${response.statusCode}');
      _debugLog('Response body: ${response.body}');

      final Map<String, dynamic> data = json.decode(response.body);
      return LoyaltyResponse.fromJson(data);
      
    } catch (e) {
      _debugLog('Error checking points: $e');
      return const LoyaltyResponse(
        success: false,
        message: 'Erreur de connexion au service de fidélité',
      );
    }
  }

  // Inscrire un nouveau client
  static Future<LoyaltyResponse> registerClient({
    required String nom,
    required String prenom,
    required String telephone,
    String? email,
  }) async {
    try {
      final request = LoyaltyRegisterRequest(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
      );
      
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      _debugLog('Register Client Response: ${response.statusCode}');
      _debugLog('Response body: ${response.body}');

      final Map<String, dynamic> data = json.decode(response.body);
      return LoyaltyResponse.fromJson(data);
      
    } catch (e) {
      _debugLog('Error registering client: $e');
      return const LoyaltyResponse(
        success: false,
        message: 'Erreur lors de l\'inscription au programme fidélité',
      );
    }
  }

  // Récupérer le profil complet avec historique
  static Future<LoyaltyProfileResponse> getProfile(String phone) async {
    try {
      final request = LoyaltyCheckRequest(phone: phone);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      _debugLog('Get Profile Response: ${response.statusCode}');
      _debugLog('Response body: ${response.body}');

      final Map<String, dynamic> data = json.decode(response.body);
      return LoyaltyProfileResponse.fromJson(data);
      
    } catch (e) {
      _debugLog('Error getting profile: $e');
      return const LoyaltyProfileResponse(
        success: false,
        message: 'Erreur lors de la récupération du profil',
      );
    }
  }

  // Mettre à jour les informations client
  static Future<LoyaltyResponse> updateClient({
    required String phone,
    String? nom,
    String? prenom,
    String? email,
  }) async {
    try {
      final requestData = {
        'phone': phone,
        if (nom != null) 'nom': nom,
        if (prenom != null) 'prenom': prenom,
        if (email != null) 'email': email,
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      _debugLog('Update Client Response: ${response.statusCode}');
      _debugLog('Response body: ${response.body}');

      final Map<String, dynamic> data = json.decode(response.body);
      return LoyaltyResponse.fromJson(data);
      
    } catch (e) {
      _debugLog('Error updating client: $e');
      return const LoyaltyResponse(
        success: false,
        message: 'Erreur lors de la mise à jour des informations',
      );
    }
  }

  // Obtenir les statistiques générales
  static Future<LoyaltyStatsResponse> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats'),
        headers: {
          'Accept': 'application/json',
        },
      );

      _debugLog('Get Stats Response: ${response.statusCode}');
      _debugLog('Response body: ${response.body}');

      final Map<String, dynamic> data = json.decode(response.body);
      return LoyaltyStatsResponse.fromJson(data);
      
    } catch (e) {
      _debugLog('Error getting stats: $e');
      return const LoyaltyStatsResponse(
        success: false,
        message: 'Erreur lors de la récupération des statistiques',
      );
    }
  }
}

// Les classes sont maintenant dans simple_loyalty_models.dart
