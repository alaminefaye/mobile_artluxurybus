import 'package:flutter/foundation.dart';

/// Classe helper pour valider les structures de réponse API
class ApiResponseValidator {
  /// Vérifie que la réponse du dashboard contient toutes les données nécessaires
  static bool validateDashboardResponse(Map<String, dynamic> json) {
    try {
      // Vérifier la structure stats
      if (!json.containsKey('stats')) {
        debugPrint('❌ Validation: Clé "stats" manquante');
        return false;
      }
      
      final stats = json['stats'] as Map<String, dynamic>?;
      if (stats == null) {
        debugPrint('❌ Validation: "stats" est null');
        return false;
      }
      
      // Vérifier les champs requis dans stats
      final requiredStatsFields = [
        'total_buses',
        'active_buses',
        'maintenance_needed',
        'insurance_expiring',
        'technical_visit_expiring',
        'vidange_needed',
      ];
      
      for (final field in requiredStatsFields) {
        if (!stats.containsKey(field)) {
          debugPrint('❌ Validation: Champ "$field" manquant dans stats');
          return false;
        }
      }
      
      // Vérifier recent_breakdowns
      if (!json.containsKey('recent_breakdowns')) {
        debugPrint('❌ Validation: Clé "recent_breakdowns" manquante');
        return false;
      }
      
      final recentBreakdowns = json['recent_breakdowns'];
      if (recentBreakdowns is! List) {
        debugPrint('❌ Validation: "recent_breakdowns" n\'est pas une liste');
        return false;
      }
      
      debugPrint('✅ Validation dashboard: OK');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la validation: $e');
      return false;
    }
  }
  
  /// Vérifie la structure de réponse paginée
  static bool validatePaginatedResponse(Map<String, dynamic> json) {
    try {
      final requiredFields = [
        'current_page',
        'data',
        'last_page',
        'per_page',
        'total',
        'path',
        'to',
      ];
      
      for (final field in requiredFields) {
        if (!json.containsKey(field)) {
          debugPrint('❌ Validation: Champ "$field" manquant dans la réponse paginée');
          return false;
        }
      }
      
      // Vérifier que data est une liste
      if (json['data'] is! List) {
        debugPrint('❌ Validation: "data" n\'est pas une liste');
        return false;
      }
      
      debugPrint('✅ Validation pagination: OK');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la validation: $e');
      return false;
    }
  }
  
  /// Vérifie le format des dates
  static bool validateDateFormat(String? dateString) {
    if (dateString == null) return true; // null est acceptable
    
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      debugPrint('❌ Format de date invalide: $dateString');
      return false;
    }
  }
  
  /// Affiche la structure JSON pour déboguer
  static void logJsonStructure(Map<String, dynamic> json, {String prefix = ''}) {
    json.forEach((key, value) {
      if (value is Map) {
        debugPrint('$prefix$key: {Map}');
        logJsonStructure(value as Map<String, dynamic>, prefix: '$prefix  ');
      } else if (value is List) {
        debugPrint('$prefix$key: [List length=${value.length}]');
        if (value.isNotEmpty && value.first is Map) {
          debugPrint('$prefix  Premier élément:');
          logJsonStructure(value.first as Map<String, dynamic>, prefix: '$prefix    ');
        }
      } else {
        debugPrint('$prefix$key: ${value.runtimeType} = $value');
      }
    });
  }
}
