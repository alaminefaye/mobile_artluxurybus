import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart'; // 🌍 Traduction automatique
import '../models/message_model.dart';
import '../screens/announcement_display_screen.dart';
import 'audio_focus_manager.dart';
import 'navigator_service.dart';

/// Service pour gérer les annonces vocales répétées
class VoiceAnnouncementService {
  static final VoiceAnnouncementService _instance =
      VoiceAnnouncementService._internal();
  factory VoiceAnnouncementService() => _instance;
  VoiceAnnouncementService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final GoogleTranslator _translator = GoogleTranslator(); // 🌍 Traducteur
  final Map<int, Timer> _activeTimers = {};
  final Map<int, MessageModel> _activeAnnouncements = {};
  final Map<int, OverlayEntry?> _activeOverlays =
      {}; // Pour garder les overlays/dialogues affichés (nullable car on utilise maintenant showDialog)
  final Map<int, BuildContext?> _activeDialogContexts =
      {}; // Pour garder les contextes des dialogues affichés (pour fermeture auto)
  final Map<int, bool> _shouldContinue =
      {}; // Pour contrôler si l'annonce doit continuer
  final Map<int, int> _repeatCounters = {}; // 🌍 Compteur de répétitions pour alternance FR/EN
  final AudioFocusManager _audioFocusManager = AudioFocusManager();

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
      
      // ⭐ CRITICAL: Activer l'attente synchrone de la fin de lecture
      await _flutterTts.awaitSpeakCompletion(true);

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

      _flutterTts.setPauseHandler(() {
        debugPrint('⏸️ [VoiceService] Annonce mise en pause');
      });

      _flutterTts.setContinueHandler(() {
        debugPrint('▶️ [VoiceService] Annonce reprise');
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        debugPrint('⏹️ [VoiceService] Annonce annulée');
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

    // Ajouter aux annonces actives
    _activeAnnouncements[message.id] = message;
    _shouldContinue[message.id] = true;
    _repeatCounters[message.id] = 0; // Initialiser le compteur à 0

    debugPrint(
        ' [VoiceService] Démarrage annonce #${message.id}: "${message.titre}"');

    // ✅ PRIORITÉ 1: Utiliser le contexte fourni (si valide)
    // ✅ PRIORITÉ 2: Utiliser le Navigator global (accessible partout, même pour totems)
    BuildContext? validContext = context;
    
    if (validContext == null || !validContext.mounted) {
      // ✅ Si aucun contexte fourni ou non monté, utiliser le Navigator global
      validContext = NavigatorService().getGlobalContext();
      if (validContext != null) {
        debugPrint('✅ [VoiceService] Contexte global Navigator utilisé (accessible partout, totems OK)');
      }
    } else {
      debugPrint('✅ [VoiceService] Context fourni et monté - utilisation du contexte local');
    }
    
    // Afficher la belle page d'annonce si un contexte valide est disponible
    if (validContext != null && validContext.mounted) {
      debugPrint('✅ [VoiceService] Affichage du dialogue d\'annonce');
      _showAnnouncementDisplay(validContext, message);
    } else {
      debugPrint('⚠️ [VoiceService] Aucun contexte valide disponible - AUDIO SEULEMENT (pas d\'overlay visuel)');
      debugPrint('   ℹ️ Le dialogue s\'affichera quand le Navigator sera disponible');
    }

    // Notifier AudioFocusManager pour mettre en pause les vidéos
    _audioFocusManager.startVoiceAnnouncement();

    // Démarrer la boucle de lecture : lire → attendre fin → pause 5s → recommencer
    _startAnnouncementLoop(message);

    debugPrint(' [VoiceService] Annonce programmée avec boucle continue');
  }

  /// Boucle de lecture d'annonce : lit tout le texte, pause 5s, recommence
  Future<void> _startAnnouncementLoop(MessageModel message) async {
    while (_shouldContinue[message.id] == true) {
      // Vérifier si les annonces vocales sont toujours activées
      if (!await isEnabled()) {
        debugPrint(' [VoiceService] Annonces vocales désactivées, arrêt');
        await stopAnnouncement(message.id);
        break;
      }

      // Vérifier si l'annonce est encore active (pas expirée) avec vérification en temps réel
      final now = DateTime.now();
      final isExpired = message.dateFin != null && now.isAfter(message.dateFin!);
      final isNotStarted = message.dateDebut != null && now.isBefore(message.dateDebut!);
      
      if (!message.active || isExpired || isNotStarted) {
        debugPrint(' [VoiceService] Annonce #${message.id} expirée ou inactive, arrêt automatique');
        debugPrint('   - active: ${message.active}');
        debugPrint('   - isExpired: $isExpired (dateFin: ${message.dateFin})');
        debugPrint('   - isNotStarted: $isNotStarted (dateDebut: ${message.dateDebut})');
        debugPrint('   - now: $now');
        await stopAnnouncement(message.id);
        break;
      }

      debugPrint(' [VoiceService] Lecture COMPLÈTE de l\'annonce #${message.id}...');

      // Déterminer la langue selon le compteur de répétitions
      int counter = _repeatCounters[message.id] ?? 0;
      bool isFrench = (counter ~/ 2) % 2 == 0; // 0-1: FR, 2-3: EN, 4-5: FR, etc.
      String language = isFrench ? 'fr-FR' : 'en-US';
      
      debugPrint(' [VoiceService] Lecture COMPLÈTE #${counter + 1} en ${isFrench ? "français" : "anglais"}...');

      // Lire l'annonce COMPLÈTEMENT dans la langue appropriée
      await _speakAnnouncement(message, language);
      
      // Incrémenter le compteur
      _repeatCounters[message.id] = counter + 1;
      
      debugPrint(' [VoiceService] Lecture TERMINÉE pour annonce #${message.id}');

      // Si on doit toujours continuer, pause de 5 secondes avant la prochaine répétition
      if (_shouldContinue[message.id] == true) {
        debugPrint(' [VoiceService] Pause de 5 secondes avant répétition...');
        
        // Pause intelligente avec vérification d'expiration (1 seconde à la fois)
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(seconds: 1));
          
          // Vérifier pendant la pause si l'annonce est toujours active avec vérification en temps réel
          final now = DateTime.now();
          final isExpired = message.dateFin != null && now.isAfter(message.dateFin!);
          final isNotStarted = message.dateDebut != null && now.isBefore(message.dateDebut!);
          
          if (_shouldContinue[message.id] != true || !message.active || isExpired || isNotStarted) {
            debugPrint(' [VoiceService] Annonce expirée pendant la pause, arrêt automatique');
            debugPrint('   - active: ${message.active}');
            debugPrint('   - isExpired: $isExpired (dateFin: ${message.dateFin})');
            debugPrint('   - now: $now');
            await stopAnnouncement(message.id);
            return; // Sortir complètement de la boucle
          }
        }
      }
    }
  }

  /// 🌍 Configurer la voix selon la langue (voix de qualité)
  Future<void> _configureVoiceForLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      
      if (language == 'en-US') {
        // 🎙️ Configuration pour une BELLE VOIX ANGLAISE (naturelle et lente)
        await _flutterTts.setVolume(0.85); // Volume réduit pour plus de douceur
        await _flutterTts.setPitch(0.9); // Pitch légèrement plus bas pour voix plus grave et naturelle
        await _flutterTts.setSpeechRate(0.38); // Vitesse RALENTIE pour meilleure compréhension
        
        // Essayer de sélectionner une voix féminine de qualité sur Android/iOS
        // Sur Android: com.google.android.tts (Google Text-to-Speech)
        // Sur iOS: com.apple.ttsbundle.Samantha-compact / com.apple.speech.synthesis.voice.samantha
        debugPrint('🎙️ [VoiceService] Voix anglaise configurée (naturelle et lente)');
      } else {
        // 🎙️ Configuration pour le français (AMÉLIORÉE - plus naturelle)
        await _flutterTts.setVolume(0.85); // Volume doux et agréable
        await _flutterTts.setPitch(0.88); // Pitch plus bas pour voix masculine naturelle et chaleureuse
        await _flutterTts.setSpeechRate(0.40); // Vitesse ralentie pour meilleure articulation
        debugPrint('🎙️ [VoiceService] Voix française configurée (naturelle et fluide)');
      }
    } catch (e) {
      debugPrint('⚠️ [VoiceService] Erreur configuration voix: $e');
    }
  }

  /// Lire une annonce vocale COMPLÈTEMENT jusqu'à la fin dans la langue spécifiée
  Future<void> _speakAnnouncement(MessageModel message, String language) async {
    // Arrêter toute lecture en cours
    if (_isSpeaking) {
      debugPrint(' [VoiceService] Arrêt de l\'annonce en cours...');
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 500));
      _isSpeaking = false;
    }

    try {
      // 🌍 Configurer la langue et la voix
      await _configureVoiceForLanguage(language);
      
      // 🌍 Traduire le contenu si nécessaire
      String titre = message.titre;
      String contenu = message.contenu;
      
      if (language == 'en-US') {
        // Traduire en anglais
        try {
          debugPrint('🌍 [VoiceService] Traduction en anglais...');
          var titreTranslated = await _translator.translate(titre, from: 'fr', to: 'en');
          var contenuTranslated = await _translator.translate(contenu, from: 'fr', to: 'en');
          titre = titreTranslated.text;
          contenu = contenuTranslated.text;
          debugPrint('✅ [VoiceService] Traduction réussie');
          debugPrint('   Titre EN: $titre');
        } catch (e) {
          debugPrint('⚠️ [VoiceService] Erreur traduction: $e - Utilisation texte original');
        }
      }
      
      // Construire le texte à lire de manière plus naturelle
      String textToSpeak = '';

      // Ajouter un préfixe court et naturel selon la langue
      if (language == 'fr-FR') {
        textToSpeak += 'Attention, ';
      } else {
        textToSpeak += 'Attention, '; // "Attention" fonctionne en anglais aussi
      }

      // Ajouter le titre traduit avec une pause
      textToSpeak += '$titre... ';

      // Nettoyer le contenu pour le rendre plus naturel
      // Remplacer les sauts de ligne par des pauses
      contenu = contenu.replaceAll('\n', '... ');
      contenu = contenu.replaceAll('\r', '');
      // Ajouter des pauses après les points
      contenu = contenu.replaceAll('.', '... ');
      // Ajouter des pauses après les virgules
      contenu = contenu.replaceAll(',', ', ');

      textToSpeak += contenu;

      debugPrint('🔊 [VoiceService] Début lecture: "$textToSpeak"');
      debugPrint('📏 [VoiceService] Longueur texte: ${textToSpeak.length} caractères');

      // Marquer le début de la lecture
      _isSpeaking = true;

      // ⭐ CRITICAL: Cette ligne attend maintenant COMPLÈTEMENT la fin de la lecture
      // grâce à awaitSpeakCompletion(true) configuré dans initialize()
      await _flutterTts.speak(textToSpeak);
      
      // La lecture est maintenant COMPLÈTEMENT terminée
      _isSpeaking = false;
      debugPrint('✅ [VoiceService] Lecture terminée avec succès');
      
    } catch (e) {
      _isSpeaking = false;
      debugPrint('❌ [VoiceService] Erreur lors de la lecture: $e');
    }
  }

  /// Afficher la belle page d'annonce via Dialog (plus fiable qu'Overlay)
  void _showAnnouncementDisplay(BuildContext context, MessageModel message) {
    try {
      debugPrint('📱 [VoiceService] Tentative affichage dialogue pour annonce #${message.id}');
      debugPrint('   - Context mounted: ${context.mounted}');
      debugPrint('   - Has Navigator: ${Navigator.maybeOf(context) != null}');

      // Vérifier que le contexte est valide et monté
      if (!context.mounted) {
        debugPrint('❌ [VoiceService] Context non monté - impossible d\'afficher le dialogue');
        return;
      }

      // Vérifier qu'un Navigator existe
      final navigator = Navigator.maybeOf(context);
      if (navigator == null) {
        debugPrint('❌ [VoiceService] Aucun Navigator trouvé dans le contexte');
        return;
      }

      // Utiliser showDialog au lieu d'Overlay (plus fiable)
      showDialog(
        context: context,
        barrierDismissible: false, // Ne peut pas être fermé en touchant dehors
        barrierColor: Colors.black54, // Fond semi-transparent
        builder: (dialogContext) {
          debugPrint('✅ [VoiceService] Builder du dialogue appelé pour annonce #${message.id}');
          _activeDialogContexts[message.id] = dialogContext; // Stocker le contexte pour fermeture auto
          
          return PopScope(
            canPop: false, // Empêcher le retour arrière
            child: AnnouncementDisplayScreen(
              message: message,
              onClose: () {
                debugPrint('🔴 [VoiceService] Utilisateur ferme le dialogue #${message.id}');
                // L'utilisateur ferme manuellement
                Navigator.of(dialogContext).pop();
                // Arrêter aussi l'annonce vocale
                stopAnnouncement(message.id);
              },
            ),
          );
        },
      ).then((_) {
        // Nettoyage quand le dialogue se ferme
        _activeOverlays.remove(message.id);
        _activeDialogContexts.remove(message.id);
        debugPrint('🔴 [VoiceService] Dialogue fermé pour annonce #${message.id}');
      }).catchError((e) {
        debugPrint('❌ [VoiceService] ERREUR lors de la fermeture du dialogue: $e');
        _activeOverlays.remove(message.id);
        _activeDialogContexts.remove(message.id);
      });

      // Marquer comme affiché (pas besoin de OverlayEntry, juste un flag)
      _activeOverlays[message.id] = null; // On utilise la map juste comme tracker

      debugPrint('✅ [VoiceService] showDialog appelé avec succès pour annonce #${message.id}');
    } catch (e, stackTrace) {
      debugPrint('❌ [VoiceService] ERREUR affichage dialogue: $e');
      debugPrint('   Stack trace: $stackTrace');
      // Ne pas bloquer l'annonce vocale en cas d'erreur d'affichage
    }
  }

  /// Arrêter une annonce spécifique
  Future<void> stopAnnouncement(int messageId) async {
    debugPrint(' [VoiceService] Demande d\'arrêt de l\'annonce #$messageId...');
    
    // Marquer qu'on doit arrêter la boucle
    _shouldContinue[messageId] = false;

    // Si une annonce est en cours de lecture, attendre qu'elle termine
    // avant d'arrêter complètement (respect de la demande utilisateur)
    if (_isSpeaking) {
      debugPrint(' [VoiceService] Attente de la fin de la lecture en cours...');
      // Attendre max 3 secondes que la lecture actuelle se termine
      int waitCounter = 0;
      while (_isSpeaking && waitCounter < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCounter++;
      }
      
      // Si toujours en cours après 3s, forcer l'arrêt
      if (_isSpeaking) {
        debugPrint(' [VoiceService] Timeout - Arrêt forcé de la lecture');
        await _flutterTts.stop();
        _isSpeaking = false;
      } else {
        debugPrint(' [VoiceService] Lecture terminée proprement');
      }
    }

    // Nettoyer les timers
    if (_activeTimers.containsKey(messageId)) {
      _activeTimers[messageId]?.cancel();
      _activeTimers.remove(messageId);
    }

    // Retirer de la liste des annonces actives
    _activeAnnouncements.remove(messageId);

    // Si plus aucune annonce active, reprendre les vidéos
    if (_activeAnnouncements.isEmpty) {
      _audioFocusManager.stopVoiceAnnouncement();
    }

    // ✅ Fermer automatiquement le dialogue si l'annonce n'est plus active
    if (_activeDialogContexts.containsKey(messageId)) {
      try {
        final dialogContext = _activeDialogContexts[messageId];
        if (dialogContext != null && dialogContext.mounted) {
          debugPrint('🔴 [VoiceService] Fermeture automatique du dialogue #$messageId (annonce non active)');
          Navigator.of(dialogContext).pop();
          _activeDialogContexts.remove(messageId);
        } else {
          debugPrint('⚠️ [VoiceService] Contexte du dialogue non monté ou null pour message #$messageId');
          _activeDialogContexts.remove(messageId);
        }
      } catch (e) {
        debugPrint('❌ [VoiceService] Erreur fermeture automatique dialogue: $e');
        _activeDialogContexts.remove(messageId);
      }
    }

    // Fermer l'overlay, même si il n'y avait pas de timer
    if (_activeOverlays.containsKey(messageId)) {
      try {
        _activeOverlays[messageId]?.remove();
        _activeOverlays.remove(messageId);
        debugPrint(' [VoiceService] Overlay fermé pour message #$messageId');
      } catch (e) {
        debugPrint(' [VoiceService] Erreur fermeture overlay: $e');
        // Forcer le nettoyage même en cas d'erreur
        _activeOverlays.remove(messageId);
      }
    }

    // Nettoyer les données
    _activeTimers.remove(messageId);
    _activeAnnouncements.remove(messageId);
    _activeOverlays.remove(messageId);
    _activeDialogContexts.remove(messageId);
    _shouldContinue.remove(messageId);
    _repeatCounters.remove(messageId); // Nettoyer le compteur

    debugPrint(' [VoiceService] Annonce #$messageId complètement arrêtée');
  }

  /// Arrêter toutes les annonces
  Future<void> stopAllAnnouncements() async {
    debugPrint(
        ' [VoiceService] Arrêt de toutes les annonces (${_activeTimers.length})');

    // Arrêter toutes les boucles
    for (var messageId in _shouldContinue.keys.toList()) {
      _shouldContinue[messageId] = false;
    }

    for (var timer in _activeTimers.values) {
      timer.cancel();
    }

    // ✅ Fermer tous les dialogues automatiquement
    for (var entry in _activeDialogContexts.entries) {
      try {
        final dialogContext = entry.value;
        if (dialogContext != null && dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }
      } catch (e) {
        debugPrint('❌ [VoiceService] Erreur fermeture dialogue #${entry.key}: $e');
      }
    }
    _activeDialogContexts.clear();

    // Fermer tous les overlays/dialogues (les dialogues se ferment automatiquement)
    for (var overlay in _activeOverlays.values) {
      try {
        overlay?.remove(); // Utiliser ?. car maintenant nullable (dialogues n'ont pas de OverlayEntry)
      } catch (e) {
        debugPrint(' [VoiceService] Erreur fermeture overlay: $e');
      }
    }

    _activeTimers.clear();
    _activeAnnouncements.clear();
    _activeOverlays.clear();
    _shouldContinue.clear();
    _repeatCounters.clear(); // Nettoyer tous les compteurs

    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    // Reprendre tous les audios
    // 🔊 Reprendre tous les audios
    _audioFocusManager.stopVoiceAnnouncement();
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
