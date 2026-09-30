import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_stats.dart';
import '../utils/error_message_helper.dart';
import 'package:flutter/foundation.dart';

class DashboardApiService {
  final String baseUrl;
  final String token;

  DashboardApiService({required this.baseUrl, required this.token});

  /// Récupérer les statistiques du dashboard pour aujourd'hui
  Future<DashboardStats> getDashboardStats() async {
    try {
      final url = Uri.parse('$baseUrl/dashboard');
      debugPrint('🔗 [DashboardAPI] URL: $url');
      debugPrint('🔑 [DashboardAPI] Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📡 [DashboardAPI] Status Code: ${response.statusCode}');
      debugPrint(
          '📄 [DashboardAPI] Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        debugPrint('✅ [DashboardAPI] JSON décodé avec succès');
        debugPrint('🔍 [DashboardAPI] Success: ${jsonResponse['success']}');

        if (jsonResponse['success'] == true) {
          debugPrint('🎯 [DashboardAPI] Parsing DashboardStats...');
          try {
            final stats = DashboardStats.fromJson(jsonResponse);
            debugPrint('✅ [DashboardAPI] DashboardStats créé avec succès');
            return stats;
          } catch (parseError, stackTrace) {
            debugPrint('❌ [DashboardAPI] Erreur parsing: $parseError');
            debugPrint('📄 [DashboardAPI] Stack trace: $stackTrace');
            debugPrint('📦 [DashboardAPI] JSON complet: $jsonResponse');
            rethrow;
          }
        } else {
          final msg = jsonResponse['message'] ??
              'Erreur lors de la récupération des statistiques';
          debugPrint('❌ [DashboardAPI] Réponse success=false: $msg');
          throw Exception(msg);
        }
      } else if (response.statusCode == 403) {
        debugPrint('⛔ [DashboardAPI] 403 Forbidden: ${response.body}');
        throw Exception(
            'Accès non autorisé. Réservé aux Super Admin, Admin et PDG.');
      } else if (response.statusCode == 401) {
        debugPrint('🔒 [DashboardAPI] 401 Unauthorized: ${response.body}');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        debugPrint(
            '❌ [DashboardAPI] Erreur serveur ${response.statusCode}: ${response.body}');
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [DashboardAPI] Exception catchée: $e');
      debugPrint('📄 [DashboardAPI] Stack trace: $stackTrace');
      throw Exception(ErrorMessageHelper.getOperationError(
        'récupérer les statistiques',
        error: e,
      ));
    }
  }

  /// Récupérer les statistiques par période
  /// [period] peut être: 'day', 'week', 'month', 'year'
  Future<Map<String, dynamic>> getStatisticsByPeriod(String period) async {
    try {
      final url = Uri.parse('$baseUrl/dashboard/stats?period=$period');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'];
        } else {
          throw Exception(jsonResponse['message'] ??
              'Erreur lors de la récupération des statistiques');
        }
      } else if (response.statusCode == 403) {
        throw Exception(
            'Accès non autorisé. Réservé aux Super Admin, Admin et PDG.');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(ErrorMessageHelper.getOperationError(
        'récupérer les statistiques par période',
        error: e,
      ));
    }
  }

  /// Revenus mensuels du guichet et de l'application pour l'année en cours.
  Future<MonthlyRevenue> getMonthlyRevenue() async {
    try {
      final url = Uri.parse('$baseUrl/dashboard/monthly-revenue');
      debugPrint('🔗 [DashboardAPI] URL Monthly Revenue: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📡 [DashboardAPI] Monthly Revenue Status: ${response.statusCode}');
      debugPrint('📝 [DashboardAPI] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        debugPrint('📊 [DashboardAPI] JSON Response: $jsonResponse');
        
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'] as Map<String, dynamic>;
          final art = jsonResponse['art'] as Map<String, dynamic>? ?? {};
          debugPrint('📊 [DashboardAPI] Data received: $data');

          final monthlyData = _parseMonthlyMap(data);
          final artData = _parseMonthlyMap(art);

          debugPrint('✅ [DashboardAPI] Monthly data final: $monthlyData');
          debugPrint('✅ [DashboardAPI] Art monthly data: $artData');
          return MonthlyRevenue(guichet: monthlyData, application: artData);
        } else {
          throw Exception(jsonResponse['message'] ??
              'Erreur lors de la récupération des revenus mensuels');
        }
      } else if (response.statusCode == 403) {
        throw Exception(
            'Accès non autorisé. Réservé aux Super Admin, Admin et PDG.');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [DashboardAPI] Exception monthly revenue: $e');
      debugPrint('💥 [DashboardAPI] Stack trace: $stackTrace');
      return MonthlyRevenue.empty();
    }
  }

  Map<int, double> _parseMonthlyMap(Map<String, dynamic> data) {
    final monthlyData = <int, double>{};

    data.forEach((key, value) {
      final month = int.tryParse(key) ?? 0;
      double revenue = 0.0;
      if (value is num) {
        revenue = value.toDouble();
      } else if (value is String) {
        revenue = double.tryParse(value) ?? 0.0;
      }

      if (month > 0 && month <= 12) {
        monthlyData[month] = revenue;
      }
    });

    for (int i = 1; i <= 12; i++) {
      monthlyData.putIfAbsent(i, () => 0.0);
    }

    return monthlyData;
  }
}

class MonthlyRevenue {
  final Map<int, double> guichet;
  final Map<int, double> application;

  const MonthlyRevenue({
    required this.guichet,
    required this.application,
  });

  factory MonthlyRevenue.empty() {
    return MonthlyRevenue(
      guichet: {for (int i = 1; i <= 12; i++) i: 0.0},
      application: {for (int i = 1; i <= 12; i++) i: 0.0},
    );
  }
}
