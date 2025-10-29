import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import '../screens/announcement_display_screen.dart';

/// Service pour gérer les annonces vocales répétées
class VoiceAnnouncementService {
  static final VoiceAnnouncementService _instance =
      VoiceAnnouncementService._internal();
  factory VoiceAnnouncementService() => _instance;
  VoiceAnnouncementService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final Map<int, Timer> _activeTimers = {};
  final Map<int, MessageModel> _activeAnnouncements = {};
  final Map<int, OverlayEntry> _activeOverlays =
      {}; // Pour garder les overlays affichés
  final Map<int, bool> _shouldContinue =
      {}; // Pour contrôler si l'annonce doit continuer

  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Configuration par défaut
  static const int defaultRepeatIntervalSeconds =
      5; // Répéter toutes les 5 SECONDES
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
      final volume = prefs.getDouble(prefKeyVolume) ??
          0.9; // Volume légèrement réduit pour plus de naturel
      final pitch = prefs.getDouble(prefKeyPitch) ??
          0.95; // Pitch légèrement plus bas pour voix masculine naturelle
      final rate = prefs.getDouble(prefKeyRate) ??
          0.48; // Vitesse un peu ralentie pour meilleure compréhension

      // Configurer TTS pour une voix plus naturelle
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
      debugPrint(
          '   Langue: $language, Volume: $volume, Pitch: $pitch, Rate: $rate');
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

    debugPrint(
        '🔊 [VoiceService] Annonces vocales ${enabled ? "activées" : "désactivées"}');
  }

  /// Obtenir l'intervalle de répétition (en secondes)
  Future<int> getRepeatInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(prefKeyRepeatInterval) ?? defaultRepeatIntervalSeconds;
  }

  /// Définir l'intervalle de répétition (en secondes)
  Future<void> setRepeatInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefKeyRepeatInterval, seconds);
    debugPrint('🔊 [VoiceService] Intervalle de répétition: $seconds secondes');
  }

  /// Démarrer l'annonce vocale répétée pour un message
  Future<void> startAnnouncement(MessageModel message,
      [BuildContext? context]) async {
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
      debugPrint('   - active: ${message.active}');
      debugPrint('   - isExpired: ${message.isExpired}');
      debugPrint('   - dateDebut: ${message.dateDebut}');
      debugPrint('   - dateFin: ${message.dateFin}');
      debugPrint('   - now: ${DateTime.now()}');
      return;
    }

    await initialize();

    // Arrêter l'annonce existante si elle existe
    await stopAnnouncement(message.id);

    // Sauvegarder l'annonce
    _activeAnnouncements[message.id] = message;
    _shouldContinue[message.id] = true;

    debugPrint(
        '🔊 [VoiceService] Démarrage annonce #${message.id}: "${message.titre}"');

    // 🎨 Afficher la belle page d'annonce si un contexte est fourni
    if (context != null && context.mounted) {
      _showAnnouncementDisplay(context, message);
    }

    // Démarrer la boucle de lecture : lire → attendre fin → pause 5s → recommencer
    _startAnnouncementLoop(message);

    debugPrint('✅ [VoiceService] Annonce programmée avec boucle continue');
  }

  /// Boucle de lecture d'annonce : lit tout le texte, pause 5s, recommence
  Future<void> _startAnnouncementLoop(MessageModel message) async {
    while (_shouldContinue[message.id] == true) {
      // Vérifier si l'annonce est toujours active (vérification périodique)
      if (!message.isCurrentlyActive) {
        debugPrint(
            '⏹️ [VoiceService] Annonce #${message.id} n\'est plus active, arrêt automatique');
        await stopAnnouncement(message.id);
        break;
      }

      // Vérifier si les annonces vocales sont toujours activées
      if (!await isEnabled()) {
        debugPrint('⏹️ [VoiceService] Annonces vocales désactivées, arrêt');
        await stopAnnouncement(message.id);
        break;
      }

      debugPrint('🔊 [VoiceService] Lecture de l\'annonce #${message.id}');

      // Lire l'annonce complète
      await _speakAnnouncement(message);

      // Attendre que la lecture soit terminée
      while (_isSpeaking && _shouldContinue[message.id] == true) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Si on doit toujours continuer, pause de 5 secondes avant la prochaine répétition
      if (_shouldContinue[message.id] == true) {
        debugPrint('⏸️ [VoiceService] Pause de 5 secondes avant répétition...');
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  /// Lire une annonce vocale
  Future<void> _speakAnnouncement(MessageModel message) async {
    if (_isSpeaking) {
      debugPrint('⏳ [VoiceService] Annonce en cours, attente...');
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      // Construire le texte à lire de manière plus naturelle
      String textToSpeak = '';

      // Ajouter un préfixe court et naturel
      textToSpeak += 'Attention, ';

      // Ajouter le titre avec une pause
      textToSpeak += '${message.titre}... ';

      // Nettoyer le contenu pour le rendre plus naturel
      String contenu = message.contenu;
      // Remplacer les sauts de ligne par des pauses
      contenu = contenu.replaceAll('\n', '... ');
      contenu = contenu.replaceAll('\r', '');
      // Ajouter des pauses après les points
      contenu = contenu.replaceAll('.', '... ');
      // Ajouter des pauses après les virgules
      contenu = contenu.replaceAll(',', ', ');

      textToSpeak += contenu;

      debugPrint('🔊 [VoiceService] Lecture: "$textToSpeak"');

      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      debugPrint('❌ [VoiceService] Erreur lors de la lecture: $e');
    }
  }

  /// Afficher la belle page d'annonce
  void _showAnnouncementDisplay(BuildContext context, MessageModel message) {
    try {
      debugPrint('🎨 [VoiceService] Affichage de la page d\'annonce');

      // Créer un overlay qui reste affiché tant que l'annonce est active
      final overlay = Overlay.of(context);
      OverlayEntry? overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => AnnouncementDisplayScreen(
          message: message,
          onClose: () {
            // L'utilisateur ferme manuellement
            overlayEntry?.remove();
            _activeOverlays.remove(message.id);
            // Arrêter aussi l'annonce vocale
            stopAnnouncement(message.id);
          },
        ),
      );

      // Sauvegarder la référence
      _activeOverlays[message.id] = overlayEntry;

      // Insérer l'overlay
      overlay.insert(overlayEntry);

      debugPrint(
          '✅ [VoiceService] Page d\'annonce affichée pour message #${message.id}');
    } catch (e) {
      debugPrint('❌ [VoiceService] Erreur affichage page annonce: $e');
    }
  }

  /// Arrêter une annonce spécifique
  Future<void> stopAnnouncement(int messageId) async {
    // Marquer qu'on doit arrêter la boucle
    _shouldContinue[messageId] = false;

    if (_activeTimers.containsKey(messageId)) {
      _activeTimers[messageId]?.cancel();
      _activeTimers.remove(messageId);
      _activeAnnouncements.remove(messageId);

      // Fermer aussi l'overlay si il existe
      if (_activeOverlays.containsKey(messageId)) {
        try {
          _activeOverlays[messageId]?.remove();
          _activeOverlays.remove(messageId);
          debugPrint(
              '🎨 [VoiceService] Overlay fermé pour message #$messageId');
        } catch (e) {
          debugPrint('⚠️ [VoiceService] Erreur fermeture overlay: $e');
        }
      }

      debugPrint('⏹️ [VoiceService] Annonce #$messageId arrêtée');
    }
  }

  /// Arrêter toutes les annonces
  Future<void> stopAllAnnouncements() async {
    debugPrint(
        '⏹️ [VoiceService] Arrêt de toutes les annonces (${_activeTimers.length})');

    // Arrêter toutes les boucles
    for (var messageId in _shouldContinue.keys.toList()) {
      _shouldContinue[messageId] = false;
    }

    for (var timer in _activeTimers.values) {
      timer.cancel();
    }

    // Fermer tous les overlays
    for (var overlay in _activeOverlays.values) {
      try {
        overlay.remove();
      } catch (e) {
        debugPrint('⚠️ [VoiceService] Erreur fermeture overlay: $e');
      }
    }

    _activeTimers.clear();
    _activeAnnouncements.clear();
    _activeOverlays.clear();
    _shouldContinue.clear();

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

