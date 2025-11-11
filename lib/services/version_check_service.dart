import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/api_config.dart';

class VersionCheckService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// Vérifier la version de l'application
  static Future<Map<String, dynamic>> checkVersion() async {
    try {
      // Récupérer la version actuelle
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // Ex: "1.0.0"
      final currentBuildNumber = int.parse(packageInfo.buildNumber); // Ex: 1

      // Déterminer la plateforme
      final platform = Platform.isAndroid ? 'android' : 'ios';

      debugPrint('📱 [VERSION CHECK] Vérification version - platform: $platform, version: $currentVersion, build: $currentBuildNumber');

      // Appeler l'API
      final uri = Uri.parse('$baseUrl/app/version-check').replace(
        queryParameters: {
          'platform': platform,
          'version': currentVersion,
          'version_code': currentBuildNumber.toString(),
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('La requête a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [VERSION CHECK] Réponse reçue: ${data.toString()}');
        return data;
      } else {
        debugPrint('❌ [VERSION CHECK] Erreur HTTP: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erreur lors de la vérification de version',
        };
      }
    } on SocketException {
      debugPrint('❌ [VERSION CHECK] Pas de connexion internet');
      return {
        'success': false,
        'message': 'Pas de connexion internet',
      };
    } on TimeoutException {
      debugPrint('❌ [VERSION CHECK] Timeout');
      return {
        'success': false,
        'message': 'La requête a pris trop de temps',
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [VERSION CHECK] Erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Erreur lors de la vérification de version: $e',
      };
    }
  }

  /// Obtenir les informations de version de l'application
  static Future<Map<String, String>> getAppVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
        'appName': packageInfo.appName,
      };
    } catch (e) {
      debugPrint('❌ [VERSION CHECK] Erreur récupération version: $e');
      return {
        'version': '1.0.0',
        'buildNumber': '1',
        'packageName': 'unknown',
        'appName': 'ART MOBILE',
      };
    }
  }
}

