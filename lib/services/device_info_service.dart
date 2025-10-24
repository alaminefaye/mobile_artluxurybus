import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  String? _deviceId;
  String? _deviceType;
  String? _deviceModel;
  String? _deviceName;

  /// Obtenir l'ID unique de l'appareil
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceId = androidInfo.id; // Android ID unique
        _deviceType = 'android';
        _deviceModel = androidInfo.model;
        _deviceName = '${androidInfo.brand} ${androidInfo.model}';
        
        debugPrint('📱 Android Device ID: $_deviceId');
        debugPrint('📱 Model: $_deviceModel');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
        _deviceType = 'ios';
        _deviceModel = iosInfo.model;
        _deviceName = '${iosInfo.name} (${iosInfo.model})';
        
        debugPrint('📱 iOS Device ID: $_deviceId');
        debugPrint('📱 Model: $_deviceModel');
      } else {
        _deviceId = 'unknown_platform';
        _deviceType = 'unknown';
      }

      return _deviceId!;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du Device ID: $e');
      _deviceId = 'error_device_id';
      return _deviceId!;
    }
  }

  /// Obtenir le type d'appareil (android/ios)
  Future<String> getDeviceType() async {
    if (_deviceType != null) return _deviceType!;
    await getDeviceId(); // Initialise aussi le type
    return _deviceType ?? 'unknown';
  }

  /// Obtenir le modèle de l'appareil
  Future<String> getDeviceModel() async {
    if (_deviceModel != null) return _deviceModel!;
    await getDeviceId();
    return _deviceModel ?? 'Unknown Model';
  }

  /// Obtenir le nom complet de l'appareil
  Future<String> getDeviceName() async {
    if (_deviceName != null) return _deviceName!;
    await getDeviceId();
    return _deviceName ?? 'Unknown Device';
  }

  /// Obtenir toutes les informations détaillées de l'appareil
  Future<Map<String, dynamic>> getDeviceInfo() async {
    await getDeviceId(); // S'assure que tout est initialisé

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'device_id': _deviceId,
          'device_type': 'android',
          'device_name': _deviceName,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'android_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'is_physical_device': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'device_id': _deviceId,
          'device_type': 'ios',
          'device_name': _deviceName,
          'model': iosInfo.model,
          'name': iosInfo.name,
          'system_name': iosInfo.systemName,
          'system_version': iosInfo.systemVersion,
          'is_physical_device': iosInfo.isPhysicalDevice,
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur getDeviceInfo: $e');
    }

    return {
      'device_id': _deviceId ?? 'unknown',
      'device_type': _deviceType ?? 'unknown',
      'device_name': _deviceName ?? 'Unknown Device',
    };
  }

  /// Réinitialiser le cache (utile pour les tests)
  void clearCache() {
    _deviceId = null;
    _deviceType = null;
    _deviceModel = null;
    _deviceName = null;
  }

  /// Afficher les informations de l'appareil dans les logs
  Future<void> printDeviceInfo() async {
    final info = await getDeviceInfo();
    debugPrint('═══════════════════════════════════════');
    debugPrint('📱 INFORMATIONS DE L\'APPAREIL');
    debugPrint('═══════════════════════════════════════');
    info.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    debugPrint('═══════════════════════════════════════');
  }
}
