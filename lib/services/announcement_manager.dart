import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_api_service.dart';
import '../services/voice_announcement_service.dart';
import '../services/device_info_service.dart';

/// Gestionnaire pour synchroniser les annonces vocales avec les messages actifs
class AnnouncementManager {
  static final AnnouncementManager _instance = AnnouncementManager._internal();
  factory AnnouncementManager() => _instance;
  AnnouncementManager._internal();

  final MessageApiService _messageService = MessageApiService();
  final VoiceAnnouncementService _voiceService = VoiceAnnouncementService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  
  final Set<int> _processedMessageIds = {};
  bool _isRunning = false;
  String? _deviceId;
  BuildContext? _context;
  Timer? _checkTimer; // Timer pour vérifier régulièrement les annonces

  /// Définir le contexte pour l'affichage des annonces
  void setContext(BuildContext context) {
    _context = context;
    debugPrint('📱 [AnnouncementManager] Contexte défini');
  }

  /// Démarre la surveillance des annonces
  Future<void> start() async {
    if (_isRunning) return;
    
    _isRunning = true;
    _deviceId = await _deviceInfoService.getDeviceId();
    
    if (kDebugMode) {
      print('📢 AnnouncementManager démarré pour l\'appareil: $_deviceId');
    }
    
    await refresh();
    
    // Vérifier toutes les 10 secondes si les annonces sont toujours actives
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _checkActiveAnnouncements();
    });
  }
  
  /// Vérifie si les annonces en cours sont toujours actives ET détecte les nouvelles
  Future<void> _checkActiveAnnouncements() async {
    if (!_isRunning || _deviceId == null) return;
    
    try {
      if (kDebugMode) {
        print('🔄 [AnnouncementManager] Vérification des annonces...');
      }
      
      // Utiliser getActiveMessages qui récupère les messages pour mobile ET pour ce device
      final messages = await _messageService.getActiveMessages();
      
      final activeMessages = messages
          .where((m) => 
              m.type == 'annonce' && 
              m.active &&
              !m.isExpired &&
              _isForThisDevice(m))
          .toList();
      
      if (kDebugMode && activeMessages.isNotEmpty) {
        debugPrint('✅ [AnnouncementManager] ${activeMessages.length} annonce(s) active(s) trouvée(s)');
      }
      
      // Récupérer les IDs des messages actifs
      final activeIds = activeMessages.map((m) => m.id).toSet();
      
      // Arrêter les annonces qui ne sont plus actives
      final idsToStop = _processedMessageIds.where((id) => !activeIds.contains(id)).toList();
      for (final id in idsToStop) {
        if (kDebugMode) {
          debugPrint('🛑 Arrêt de l\'annonce $id (plus active)');
        }
        _voiceService.stopAnnouncement(id);
        _processedMessageIds.remove(id);
      }
      
      // Démarrer les nouvelles annonces
      for (final message in activeMessages) {
        if (!_processedMessageIds.contains(message.id)) {
          if (kDebugMode) {
            debugPrint('🎤 Nouvelle annonce détectée: ${message.titre} (ID: ${message.id})');
          }
          _processedMessageIds.add(message.id);
          _voiceService.startAnnouncement(message, _context);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la vérification des annonces: $e');
      }
    }
  }

  /// Traiter les annonces actives
  Future<void> _processActiveAnnouncements() async {
    try {
      debugPrint('🔍 [AnnouncementManager] Récupération des annonces actives...');
      
      // Récupérer les messages actifs
      final messages = await _messageService.getActiveMessages();
      
      debugPrint('📋 [AnnouncementManager] Messages récupérés: ${messages.length}');
      
      // Debug: analyser tous les messages
      for (var m in messages) {
        debugPrint('📄 Message #${m.id}: isAnnonce=${m.isAnnonce}, active=${m.isCurrentlyActive}, appareil="${m.appareil}", titre="${m.titre}"');
      }
      
      // Filtrer uniquement les annonces destinées à cet appareil mobile
      final annonces = messages.where((m) => 
        m.isAnnonce && 
        m.isCurrentlyActive &&
        _isForThisDevice(m)
      ).toList();
      
      debugPrint('📢 [AnnouncementManager] ${annonces.length} annonce(s) active(s) trouvée(s) pour cet appareil');

      // Obtenir les annonces vocales déjà actives
      final activeVoiceAnnouncements = _voiceService.getActiveAnnouncements();
      final activeVoiceIds = activeVoiceAnnouncements.map((m) => m.id).toSet();

      // Démarrer les nouvelles annonces
      for (var annonce in annonces) {
        if (!activeVoiceIds.contains(annonce.id) && !_processedMessageIds.contains(annonce.id)) {
          debugPrint('🎙️ [AnnouncementManager] Démarrage annonce #${annonce.id}: "${annonce.titre}"');
          await _voiceService.startAnnouncement(annonce, _context);
          _processedMessageIds.add(annonce.id);
        }
      }

      // Arrêter les annonces qui ne sont plus actives
      final currentAnnonceIds = annonces.map((m) => m.id).toSet();
      for (var voiceAnnouncement in activeVoiceAnnouncements) {
        // Vérifier si l'annonce n'est plus dans la liste des annonces actives
        if (!currentAnnonceIds.contains(voiceAnnouncement.id)) {
          debugPrint('⏹️ [AnnouncementManager] Arrêt annonce #${voiceAnnouncement.id} (plus active)');
          await _voiceService.stopAnnouncement(voiceAnnouncement.id);
          _processedMessageIds.remove(voiceAnnouncement.id);
        } else {
          // Vérifier si l'annonce est toujours active en temps réel
          if (!voiceAnnouncement.isCurrentlyActive) {
            debugPrint('⏹️ [AnnouncementManager] Arrêt annonce #${voiceAnnouncement.id} (expirée en temps réel)');
            await _voiceService.stopAnnouncement(voiceAnnouncement.id);
            _processedMessageIds.remove(voiceAnnouncement.id);
          }
        }
      }

    } catch (e) {
      debugPrint('❌ [AnnouncementManager] Erreur lors du traitement: $e');
    }
  }

  /// Rafraîchir les annonces (vérifier les nouvelles et arrêter les anciennes)
  Future<void> refresh() async {
    if (!_isRunning) {
      debugPrint('⚠️ [AnnouncementManager] Non démarré, appeler start() d\'abord');
      return;
    }

    debugPrint('🔄 [AnnouncementManager] Rafraîchissement...');
    await _processActiveAnnouncements();
  }

  /// Vérifier si le message est destiné à cet appareil mobile
  bool _isForThisDevice(MessageModel message) {
    final appareil = message.appareil?.trim();
    
    // Si pas d'appareil spécifié ou 'tous', l'annonce concerne tout le monde
    if (appareil == null || appareil.isEmpty || appareil.toLowerCase() == 'tous') {
      return true;
    }
    
    // Vérifier si c'est la catégorie 'mobile'
    if (appareil.toLowerCase() == 'mobile') {
      return true;
    }
    
    // Vérifier si c'est l'identifiant unique de CET appareil
    if (_deviceId != null && appareil == _deviceId) {
      debugPrint('✅ [AnnouncementManager] Annonce #${message.id} destinée à cet appareil spécifique');
      return true;
    }
    
    // Vérifier si l'identifiant est dans une liste séparée par des virgules
    if (appareil.contains(',')) {
      final deviceIds = appareil.split(',').map((e) => e.trim()).toList();
      if (_deviceId != null && deviceIds.contains(_deviceId)) {
        debugPrint('✅ [AnnouncementManager] Annonce #${message.id} destinée à cet appareil (liste multiple)');
        return true;
      }
    }
    
    // Sinon (ecran_tv, ecran_led, ou autre device_id), ne pas traiter sur mobile
    debugPrint('⚠️ [AnnouncementManager] Annonce #${message.id} non destinée à cet appareil (appareil: $appareil, device_id: $_deviceId)');
    return false;
  }

  /// Traiter un nouveau message reçu via notification push
  Future<void> handleNewMessage(MessageModel message) async {
    if (!_isRunning) {
      await start();
    }

    if (!message.isAnnonce || !message.isCurrentlyActive) {
      debugPrint('⚠️ [AnnouncementManager] Message ignoré (pas une annonce active)');
      return;
    }

    // Vérifier si l'annonce concerne cet appareil
    if (!_isForThisDevice(message)) {
      debugPrint('⚠️ [AnnouncementManager] Annonce #${message.id} ignorée (pas pour cet appareil)');
      return;
    }

    if (_processedMessageIds.contains(message.id)) {
      debugPrint('ℹ️ [AnnouncementManager] Annonce #${message.id} déjà traitée');
      return;
    }

    debugPrint('🆕 [AnnouncementManager] Nouvelle annonce reçue #${message.id}');
    await _voiceService.startAnnouncement(message);
    _processedMessageIds.add(message.id);
  }

  /// Arrêter toutes les annonces
  Future<void> stopAll() async {
    debugPrint('⏹️ [AnnouncementManager] Arrêt de toutes les annonces');
    await _voiceService.stopAllAnnouncements();
    _processedMessageIds.clear();
  }

  /// Arrête la surveillance des annonces
  Future<void> stop() async {
    _isRunning = false;
    _checkTimer?.cancel();
    _checkTimer = null;
    _voiceService.stopAllAnnouncements();
    _processedMessageIds.clear();
    
    if (kDebugMode) {
      print('📢 AnnouncementManager arrêté');
    }
  }

  /// Vérifier si le gestionnaire est en cours d'exécution
  bool get isRunning => _isRunning;

  /// Obtenir le nombre d'annonces actives
  int get activeAnnouncementsCount => _voiceService.getActiveAnnouncements().length;
}
