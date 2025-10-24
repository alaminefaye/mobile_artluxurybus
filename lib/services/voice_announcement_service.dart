import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';

/// Service pour gérer les annonces vocales répétées
class VoiceAnnouncementService {
  static final VoiceAnnouncementService _instance = VoiceAnnouncementService._internal();
  factory VoiceAnnouncementService() => _instance;
  VoiceAnnouncementService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final Map<int, Timer> _activeTimers = {};
  final Map<int, MessageModel> _activeAnnouncements = {};
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  // Configuration par défaut
  static const int defaultRepeatIntervalMinutes = 5; // Répéter toutes les 5 minutes
  static const String prefKeyVoiceEnabled = 'voice_announcements_enabled';
  static const String prefKeyRepeatInterval = 'voice_repeat_interval';
  static const String prefKeyLanguage = 'voice_language';
  static const String prefKeyVolume = 'voice_volume';
  static const String prefKeyPitch = 'voice_pitch';
  static const String prefKeyRate = 'voice_rate';

  /// Initialiser le service TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔊 [VoiceService] Initialisation...');
      
      // Charger les préférences
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString(prefKeyLanguage) ?? 'fr-FR';
      final volume = prefs.getDouble(prefKeyVolume) ?? 1.0;
      final pitch = prefs.getDouble(prefKeyPitch) ?? 1.0;
      final rate = prefs.getDouble(prefKeyRate) ?? 0.5;

      // Configurer TTS
      await _flutterTts.setLanguage(language);
      await _flutterTts.setVolume(volume);
      await _flutterTts.setPitch(pitch);
      await _flutterTts.setSpeechRate(rate);

      // Callbacks
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('🔊 [VoiceService] Début de l\'annonce vocale');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('✅ [VoiceService] Annonce vocale terminée');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('❌ [VoiceService] Erreur TTS: $msg');
      });

      _isInitialized = true;
      debugPrint('✅ [VoiceService] Initialisé avec succès');
      debugPrint('   Langue: $language, Volume: $volume, Pitch: $pitch, Rate: $rate');
    } catch (e) {
      debugPrint('❌ [VoiceService] Erreur d\'initialisation: $e');
    }
  }

  /// Vérifier si les annonces vocales sont activées
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKeyVoiceEnabled) ?? true; // Activé par défaut
  }

  /// Activer/Désactiver les annonces vocales
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyVoiceEnabled, enabled);
    
    if (!enabled) {
      // Arrêter toutes les annonces en cours
      await stopAllAnnouncements();
    }
    
    debugPrint('🔊 [VoiceService] Annonces vocales ${enabled ? "activées" : "désactivées"}');
  }

  /// Obtenir l'intervalle de répétition (en minutes)
  Future<int> getRepeatInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(prefKeyRepeatInterval) ?? defaultRepeatIntervalMinutes;
  }

  /// Définir l'intervalle de répétition (en minutes)
  Future<void> setRepeatInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefKeyRepeatInterval, minutes);
    debugPrint('🔊 [VoiceService] Intervalle de répétition: $minutes minutes');
  }

  /// Démarrer l'annonce vocale répétée pour un message
  Future<void> startAnnouncement(MessageModel message) async {
    if (!await isEnabled()) {
      debugPrint('⚠️ [VoiceService] Annonces vocales désactivées');
      return;
    }

    if (!message.isAnnonce) {
      debugPrint('⚠️ [VoiceService] Message n\'est pas une annonce');
      return;
    }

    if (!message.isCurrentlyActive) {
      debugPrint('⚠️ [VoiceService] Annonce non active');
      return;
    }

    await initialize();

    // Arrêter l'annonce existante si elle existe
    await stopAnnouncement(message.id);

    // Sauvegarder l'annonce
    _activeAnnouncements[message.id] = message;

    debugPrint('🔊 [VoiceService] Démarrage annonce #${message.id}: "${message.titre}"');

    // Lire immédiatement
    await _speakAnnouncement(message);

    // Programmer les répétitions
    final intervalMinutes = await getRepeatInterval();
    final interval = Duration(minutes: intervalMinutes);

    _activeTimers[message.id] = Timer.periodic(interval, (timer) async {
      // Vérifier si l'annonce est toujours active
      if (!message.isCurrentlyActive) {
        debugPrint('⏹️ [VoiceService] Annonce #${message.id} n\'est plus active, arrêt');
        await stopAnnouncement(message.id);
        return;
      }

      // Vérifier si les annonces vocales sont toujours activées
      if (!await isEnabled()) {
        debugPrint('⏹️ [VoiceService] Annonces vocales désactivées, arrêt');
        await stopAnnouncement(message.id);
        return;
      }

      // Lire l'annonce
      await _speakAnnouncement(message);
    });

    debugPrint('✅ [VoiceService] Annonce programmée (répétition: $intervalMinutes min)');
  }

  /// Lire une annonce vocale
  Future<void> _speakAnnouncement(MessageModel message) async {
    if (_isSpeaking) {
      debugPrint('⏳ [VoiceService] Annonce en cours, attente...');
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      // Construire le texte à lire
      String textToSpeak = '';
      
      // Ajouter un préfixe selon le type
      textToSpeak += 'Annonce importante. ';
      
      // Ajouter le titre
      textToSpeak += '${message.titre}. ';
      
      // Ajouter le contenu
      textToSpeak += message.contenu;
      
      // Ajouter la gare si disponible
      if (message.gare != null) {
        textToSpeak += '. Gare de ${message.gare!.nom}';
      }

      debugPrint('🔊 [VoiceService] Lecture: "$textToSpeak"');
      
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      debugPrint('❌ [VoiceService] Erreur lors de la lecture: $e');
    }
  }

  /// Arrêter une annonce spécifique
  Future<void> stopAnnouncement(int messageId) async {
    if (_activeTimers.containsKey(messageId)) {
      _activeTimers[messageId]?.cancel();
      _activeTimers.remove(messageId);
      _activeAnnouncements.remove(messageId);
      debugPrint('⏹️ [VoiceService] Annonce #$messageId arrêtée');
    }
  }

  /// Arrêter toutes les annonces
  Future<void> stopAllAnnouncements() async {
    debugPrint('⏹️ [VoiceService] Arrêt de toutes les annonces (${_activeTimers.length})');
    
    for (var timer in _activeTimers.values) {
      timer.cancel();
    }
    
    _activeTimers.clear();
    _activeAnnouncements.clear();
    
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
  }

  /// Obtenir la liste des annonces actives
  List<MessageModel> getActiveAnnouncements() {
    return _activeAnnouncements.values.toList();
  }

  /// Vérifier si une annonce est en cours
  bool isAnnouncementActive(int messageId) {
    return _activeTimers.containsKey(messageId);
  }

  /// Lire un texte immédiatement (sans répétition)
  Future<void> speakOnce(String text) async {
    await initialize();
    
    if (!await isEnabled()) {
      debugPrint('⚠️ [VoiceService] Annonces vocales désactivées');
      return;
    }

    if (_isSpeaking) {
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    await _flutterTts.speak(text);
  }

  /// Arrêter la lecture en cours
  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
  }

  /// Mettre en pause
  Future<void> pause() async {
    if (_isSpeaking) {
      await _flutterTts.pause();
    }
  }

  /// Obtenir les langues disponibles
  Future<List<dynamic>> getAvailableLanguages() async {
    await initialize();
    return await _flutterTts.getLanguages;
  }

  /// Définir la langue
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyLanguage, language);
    debugPrint('🔊 [VoiceService] Langue changée: $language');
  }

  /// Définir le volume (0.0 à 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(prefKeyVolume, volume);
  }

  /// Définir le pitch (0.5 à 2.0)
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(prefKeyPitch, pitch);
  }

  /// Définir la vitesse (0.0 à 1.0)
  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(prefKeyRate, rate);
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    await stopAllAnnouncements();
    _isInitialized = false;
  }
}
