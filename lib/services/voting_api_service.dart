import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class VotingApiService {
  static const String baseUrl = 'https://skf-artluxurybus.com/api';

  /// Récupérer l'identifiant unique de l'appareil
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ??
          'unknown-ios-${DateTime.now().millisecondsSinceEpoch}';
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else {
      return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Récupérer les informations de l'appareil (pour security_data)
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'platform': 'ios',
        'device_model': iosInfo.model,
        'device_os': '${iosInfo.systemName} ${iosInfo.systemVersion}',
      };
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'platform': 'android',
        'device_model': '${androidInfo.manufacturer} ${androidInfo.model}',
        'device_os': 'Android ${androidInfo.version.release}',
      };
    } else {
      return {
        'platform': 'unknown',
        'device_model': 'unknown',
        'device_os': 'unknown',
      };
    }
  }

  /// Récupérer toutes les sessions de vote actives
  /// GET /api/voting/sessions
  static Future<Map<String, dynamic>> getSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/voting/sessions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Erreur: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupérer toutes les sessions (en cours, programmées, terminées)
  /// GET /api/voting/sessions/all
  static Future<Map<String, dynamic>> getSessionsAll() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/voting/sessions/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Erreur: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupérer les détails d'une session de vote
  /// GET /api/voting/sessions/{sessionId}
  static Future<Map<String, dynamic>> getSession(int sessionId) async {
    try {
      // Récupérer le device_id pour vérifier si l'utilisateur a déjà voté
      final deviceId = await getDeviceId();

      final response = await http.get(
        Uri.parse('$baseUrl/voting/sessions/$sessionId?device_id=$deviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Erreur: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Vérifier si l'utilisateur a déjà voté
  /// POST /api/voting/sessions/{sessionId}/check-vote
  static Future<Map<String, dynamic>> checkVote({
    required int sessionId,
    String? voterPhone,
  }) async {
    try {
      final deviceId = await getDeviceId();

      final response = await http.post(
        Uri.parse('$baseUrl/voting/sessions/$sessionId/check-vote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          if (voterPhone != null) 'voter_phone': voterPhone,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Erreur: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Enregistrer un vote
  /// POST /api/voting/sessions/{sessionId}/vote
  static Future<Map<String, dynamic>> vote({
    required int sessionId,
    required int candidateId,
    required String voterFullName,
    required String voterPhone,
    String? appVersion,
  }) async {
    try {
      final deviceId = await getDeviceId();
      final deviceInfo = await getDeviceInfo();

      final response = await http.post(
        Uri.parse('$baseUrl/voting/sessions/$sessionId/vote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'candidate_id': candidateId,
          'device_id': deviceId,
          'voter_full_name': voterFullName,
          'voter_phone': voterPhone,
          'app_version': appVersion,
          ...deviceInfo,
        }),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return responseData;
      } else {
        return responseData;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupérer les résultats d'une session de vote
  /// GET /api/voting/sessions/{sessionId}/results
  static Future<Map<String, dynamic>> getResults(int sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/voting/sessions/$sessionId/results'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Erreur: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }
}
