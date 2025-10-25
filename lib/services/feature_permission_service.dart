import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/feature_permission_model.dart';
import 'auth_service.dart';

class FeaturePermissionService {
  static const String baseUrl = 'https://gestion-compagny.universaltechnologiesafrica.com';
  final AuthService _authService = AuthService();

  /// Récupérer toutes les permissions de l'utilisateur
  Future<FeaturePermissionsResponse> getUserPermissions() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/features/permissions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📋 [PERMISSIONS] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return FeaturePermissionsResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la récupération des permissions');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PERMISSIONS] Erreur: $e');
      rethrow;
    }
  }

  /// Vérifier si une fonctionnalité est activée
  Future<bool> isFeatureEnabled(String featureCode) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/features/check/$featureCode'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return data['data']['is_enabled'] ?? false;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ [PERMISSION CHECK] Erreur pour $featureCode: $e');
      return false;
    }
  }

  /// Synchroniser les permissions (au démarrage de l'app)
  Future<FeaturePermissionsResponse> syncPermissions() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/user/features/sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('🔄 [SYNC PERMISSIONS] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          debugPrint('✅ [SYNC PERMISSIONS] Permissions synchronisées');
          return FeaturePermissionsResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la synchronisation');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SYNC PERMISSIONS] Erreur: $e');
      rethrow;
    }
  }
}
