import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service pour gérer l'UUID unique de l'installation de l'application
class UuidService {
  static final UuidService _instance = UuidService._internal();
  factory UuidService() => _instance;
  UuidService._internal();

  static const String _prefKey = 'app_device_uuid';
  static const Uuid _uuidGenerator = Uuid();
  
  String? _cachedUuid;

  /// Obtenir l'UUID unique de cette installation
  /// Génère un UUID si c'est la première fois, sinon récupère celui stocké
  Future<String> getUuid() async {
    // Retourner depuis le cache si disponible
    if (_cachedUuid != null) {
      return _cachedUuid!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Récupérer l'UUID stocké
      String? storedUuid = prefs.getString(_prefKey);
      
      if (storedUuid != null && storedUuid.isNotEmpty) {
        _cachedUuid = storedUuid;
        debugPrint('📱 [UuidService] UUID récupéré depuis le stockage: $storedUuid');
        return storedUuid;
      }
      
      // Générer un nouvel UUID si aucun n'existe
      final newUuid = _uuidGenerator.v4();
      await prefs.setString(_prefKey, newUuid);
      _cachedUuid = newUuid;
      
      debugPrint('🆕 [UuidService] Nouvel UUID généré: $newUuid');
      return newUuid;
    } catch (e) {
      debugPrint('❌ [UuidService] Erreur lors de la récupération/génération de l\'UUID: $e');
      // En cas d'erreur, générer un UUID temporaire (mais ne pas le sauvegarder)
      final tempUuid = _uuidGenerator.v4();
      debugPrint('⚠️ [UuidService] UUID temporaire généré: $tempUuid');
      return tempUuid;
    }
  }

  /// Réinitialiser l'UUID (générer un nouveau)
  /// Utile pour les tests ou en cas de problème
  Future<String> resetUuid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newUuid = _uuidGenerator.v4();
      
      await prefs.setString(_prefKey, newUuid);
      _cachedUuid = newUuid;
      
      debugPrint('🔄 [UuidService] UUID réinitialisé: $newUuid');
      return newUuid;
    } catch (e) {
      debugPrint('❌ [UuidService] Erreur lors de la réinitialisation de l\'UUID: $e');
      rethrow;
    }
  }

  /// Vérifier si un UUID existe déjà
  Future<bool> hasUuid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUuid = prefs.getString(_prefKey);
      return storedUuid != null && storedUuid.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [UuidService] Erreur lors de la vérification de l\'UUID: $e');
      return false;
    }
  }

  /// Réinitialiser le cache en mémoire (utile pour les tests)
  void clearCache() {
    _cachedUuid = null;
    debugPrint('🧹 [UuidService] Cache réinitialisé');
  }
}

