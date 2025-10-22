import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/attendance_models.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

class AttendanceApiService {
  static final AuthService _authService = AuthService();
  static final _log = Logger('AttendanceApiService');

  /// Scanner un QR code pour pointer
  static Future<Map<String, dynamic>> scanQrCode({
    required String qrCode,
    required double latitude,
    required double longitude,
    required ActionType actionType,
    String? deviceInfo,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/attendance/scan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'qr_code': qrCode,
          'latitude': latitude,
          'longitude': longitude,
          'action_type': actionType.value,
          'device_info': deviceInfo ?? Platform.operatingSystem,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Obtenir l'historique des pointages
  static Future<List<AttendanceRecord>> getMyAttendances({
    int perPage = 50,
    int page = 1,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      var url = '${ApiConfig.baseUrl}/attendance/my-attendances?per_page=$perPage&page=$page';
      if (startDate != null) {
        url += '&start_date=$startDate';
      }
      if (endDate != null) {
        url += '&end_date=$endDate';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> attendancesData = data['data'] ?? [];
        return attendancesData
            .map((json) => AttendanceRecord.fromJson(json))
            .toList();
      } else {
        throw Exception('Erreur lors de la récupération de l\'historique');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Obtenir les statistiques de pointage
  static Future<AttendanceStats?> getMyStats({
    int? month,
    int? year,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      var url = '${ApiConfig.baseUrl}/attendance/my-stats';
      final params = <String>[];
      if (month != null) params.add('month=$month');
      if (year != null) params.add('year=$year');
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AttendanceStats.fromJson(data['data']);
      } else {
        throw Exception('Erreur lors de la récupération des statistiques');
      }
    } catch (e) {
      _log.warning('Erreur getMyStats: $e');
      return null;
    }
  }

  /// Vérifier le statut actuel de présence
  static Future<CurrentStatus?> getCurrentStatus() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/current-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CurrentStatus.fromJson(data['data']);
      } else {
        throw Exception('Erreur lors de la vérification du statut');
      }
    } catch (e) {
      _log.warning('Erreur getCurrentStatus: $e');
      return null;
    }
  }

  /// Obtenir la liste des locations disponibles
  static Future<List<AttendanceLocation>> getLocations() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/locations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> locationsData = data['data'] ?? [];
        return locationsData
            .map((json) => AttendanceLocation.fromJson(json))
            .toList();
      } else {
        throw Exception('Erreur lors de la récupération des locations');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
}
