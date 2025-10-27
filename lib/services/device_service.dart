import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static String? _cachedDeviceId;

  /// Récupère l'identifiant unique de l'appareil
  static Future<String> getDeviceId() async {
    // Si déjà en cache, retourner directement
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      String deviceId;

      if (kIsWeb) {
        // Pour le web, utiliser l'info du navigateur
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceId = webInfo.userAgent ?? 'web-unknown';
      } else if (Platform.isAndroid) {
        // Pour Android, utiliser l'androidId
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Android ID unique
      } else if (Platform.isIOS) {
        // Pour iOS, utiliser l'identifierForVendor
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'ios-unknown';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceId = linuxInfo.machineId ?? 'linux-unknown';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        deviceId = macInfo.systemGUID ?? 'macos-unknown';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceId = windowsInfo.deviceId;
      } else {
        deviceId = 'unknown-platform';
      }

      // Mettre en cache
      _cachedDeviceId = deviceId;
      debugPrint('📱 Device ID récupéré: $deviceId');
      
      return deviceId;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du Device ID: $e');
      return 'error-device-id';
    }
  }

  /// Réinitialise le cache du device ID (utile pour les tests)
  static void resetCache() {
    _cachedDeviceId = null;
  }

  /// Récupère les informations complètes de l'appareil
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'deviceId': androidInfo.id,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'version': iosInfo.systemVersion,
        };
      }
      return {'platform': 'unknown'};
    } catch (e) {
      debugPrint('❌ Erreur getDeviceInfo: $e');
      return {'error': e.toString()};
    }
  }
}
