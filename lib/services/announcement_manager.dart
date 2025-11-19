import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_api_service.dart';
import '../services/voice_announcement_service.dart';
import '../services/device_info_service.dart';
import '../services/navigator_service.dart';

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
  String? _uuid;
  BuildContext? _context;
  Timer? _checkTimer; // Timer pour vérifier régulièrement les annonces
  DateTime? _lastApiCall; // Dernière requête API pour éviter le rate limiting
  int _backoffSeconds = 10; // Intervalle entre vérifications (commence à 10s)

  /// Définir le contexte pour l'affichage des annonces
  void setContext(BuildContext context) {
    if (context.mounted) {
      _context = context;
      debugPrint(
          '📱 [AnnouncementManager] ✅ Contexte défini et prêt pour overlays (mounted: ${context.mounted})');
    } else {
      debugPrint(
          '⚠️ [AnnouncementManager] Contexte fourni mais NON monté - ignoré');
    }
  }

  /// Obtenir le contexte valide pour afficher les dialogues
  /// ✅ PRIORITÉ 1: Navigator global (accessible partout, même pour totems)
  /// ✅ PRIORITÉ 2: Contexte local (si défini)
  BuildContext? getValidContext() {
    // ✅ PRIORITÉ 1: Utiliser le Navigator global (accessible partout)
    final globalContext = NavigatorService().getGlobalContext();
    if (globalContext != null) {
      debugPrint(
          '✅ [AnnouncementManager] Contexte global Navigator utilisé (disponible partout)');
      return globalContext;
    }

    // ✅ PRIORITÉ 2: Utiliser le contexte local si disponible
    if (_context != null && _context!.mounted) {
      debugPrint('✅ [AnnouncementManager] Contexte local utilisé');
      return _context;
    }

    debugPrint(
        '⚠️ [AnnouncementManager] Aucun contexte disponible (ni global ni local)');
    return null;
  }

  /// Démarre la surveillance des annonces
  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    _deviceId = await _deviceInfoService.getDeviceId();
    _uuid = await _deviceInfoService.getUuid();

    if (kDebugMode) {
      print('📢 AnnouncementManager démarré pour l\'appareil: $_deviceId');
      print('🔑 AnnouncementManager démarré avec UUID: $_uuid');
    }

    await refresh();

    // Vérifier toutes les 10 secondes pour détecter rapidement les nouvelles annonces
    _backoffSeconds = 10; // 10 secondes par défaut pour réactivité maximale
    _checkTimer =
        Timer.periodic(Duration(seconds: _backoffSeconds), (timer) async {
      await _checkActiveAnnouncements();
    });
  }

  /// Vérifie si les annonces en cours sont toujours actives ET détecte les nouvelles
  Future<void> _checkActiveAnnouncements() async {
    if (!_isRunning || _deviceId == null) return;

    // Vérifier si on doit attendre avant la prochaine requête (throttling)
    // Minimum 5 secondes entre chaque appel pour éviter le rate limiting
    if (_lastApiCall != null) {
      final timeSinceLastCall = DateTime.now().difference(_lastApiCall!);
      if (timeSinceLastCall.inSeconds < 5) {
        if (kDebugMode) {
          debugPrint(
              '⏸️ [AnnouncementManager] Throttling - dernière requête il y a ${timeSinceLastCall.inSeconds}s (minimum 5s)');
        }
        return;
      }
    }

    try {
      if (kDebugMode) {
        print('🔄 [AnnouncementManager] Vérification des annonces...');
      }

      _lastApiCall = DateTime.now(); // Enregistrer l'heure de la requête

      // Utiliser getActiveMessages qui récupère les messages pour mobile ET pour ce device
      final messages = await _messageService.getActiveMessages();

      // Réinitialiser le backoff en cas de succès (mais garder au minimum 10s)
      if (_backoffSeconds > 10) {
        _backoffSeconds = 10;
        _restartTimerWithNewInterval();
      }

      final activeMessages = messages
          .where((m) =>
              m.type == 'annonce' &&
              m.active &&
              !m.isExpired &&
              _isForThisDevice(m))
          .toList();

      if (kDebugMode && activeMessages.isNotEmpty) {
        debugPrint(
            '✅ [AnnouncementManager] ${activeMessages.length} annonce(s) active(s) trouvée(s)');
      }

      // Récupérer les IDs des messages actifs
      final activeIds = activeMessages.map((m) => m.id).toSet();

      // Arrêter les annonces qui ne sont plus actives
      final idsToStop =
          _processedMessageIds.where((id) => !activeIds.contains(id)).toList();
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
            debugPrint(
                '🎤 Nouvelle annonce détectée: ${message.titre} (ID: ${message.id})');
          }
          _processedMessageIds.add(message.id);

          // Vérifier si le context est disponible pour l'overlay
          final validContext = getValidContext();
          if (validContext != null && validContext.mounted) {
            debugPrint(
                '✅ [AnnouncementManager] Démarrage avec overlay visuel (context OK)');
            _voiceService.startAnnouncement(message, validContext);
          } else {
            debugPrint(
                '⚠️ [AnnouncementManager] Contexte non disponible - annonce AUDIO SEULEMENT');
            _voiceService.startAnnouncement(message);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la vérification des annonces: $e');
      }

      // En cas d'erreur (probablement 429), augmenter le backoff
      if (e.toString().contains('429') || e.toString().contains('Too Many')) {
        _backoffSeconds = (_backoffSeconds * 2)
            .clamp(10, 120); // Min 10 secondes, Max 2 minutes
        debugPrint(
            '⚠️ [AnnouncementManager] Rate limit atteint - backoff à ${_backoffSeconds}s');
        _restartTimerWithNewInterval();
      }
    }
  }

  /// Redémarre le timer avec un nouvel intervalle
  void _restartTimerWithNewInterval() {
    _checkTimer?.cancel();
    if (_isRunning) {
      _checkTimer =
          Timer.periodic(Duration(seconds: _backoffSeconds), (timer) async {
        await _checkActiveAnnouncements();
      });
      debugPrint(
          '🔄 [AnnouncementManager] Timer redémarré avec intervalle de ${_backoffSeconds}s');
    }
  }

  /// Traiter les annonces actives
  Future<void> _processActiveAnnouncements() async {
    try {
      debugPrint(
          '🔍 [AnnouncementManager] Récupération des annonces actives...');

      // Récupérer les messages actifs
      final messages = await _messageService.getActiveMessages();

      debugPrint(
          '📋 [AnnouncementManager] Messages récupérés: ${messages.length}');

      // Debug: analyser tous les messages
      for (var m in messages) {
        debugPrint(
            '📄 Message #${m.id}: isAnnonce=${m.isAnnonce}, active=${m.isCurrentlyActive}, appareil="${m.appareil}", titre="${m.titre}"');
      }

      // Filtrer uniquement les annonces destinées à cet appareil mobile
      final annonces = messages
          .where(
              (m) => m.isAnnonce && m.isCurrentlyActive && _isForThisDevice(m))
          .toList();

      debugPrint(
          '📢 [AnnouncementManager] ${annonces.length} annonce(s) active(s) trouvée(s) pour cet appareil');

      // Obtenir les annonces vocales déjà actives
      final activeVoiceAnnouncements = _voiceService.getActiveAnnouncements();
      final activeVoiceIds = activeVoiceAnnouncements.map((m) => m.id).toSet();

      // Démarrer les nouvelles annonces
      for (var annonce in annonces) {
        if (!activeVoiceIds.contains(annonce.id) &&
            !_processedMessageIds.contains(annonce.id)) {
          debugPrint(
              '🎙️ [AnnouncementManager] Démarrage annonce #${annonce.id}: "${annonce.titre}"');
          final validContext = getValidContext();
          if (validContext != null && validContext.mounted) {
            await _voiceService.startAnnouncement(annonce, validContext);
          } else {
            await _voiceService.startAnnouncement(annonce);
          }
          _processedMessageIds.add(annonce.id);
        }
      }

      // Arrêter les annonces qui ne sont plus actives
      final currentAnnonceIds = annonces.map((m) => m.id).toSet();
      for (var voiceAnnouncement in activeVoiceAnnouncements) {
        // Vérifier si l'annonce n'est plus dans la liste des annonces actives
        if (!currentAnnonceIds.contains(voiceAnnouncement.id)) {
          debugPrint(
              '⏹️ [AnnouncementManager] Arrêt annonce #${voiceAnnouncement.id} (plus active)');
          await _voiceService.stopAnnouncement(voiceAnnouncement.id);
          _processedMessageIds.remove(voiceAnnouncement.id);
        } else {
          // Vérifier si l'annonce est toujours active en temps réel
          if (!voiceAnnouncement.isCurrentlyActive) {
            debugPrint(
                '⏹️ [AnnouncementManager] Arrêt annonce #${voiceAnnouncement.id} (expirée en temps réel)');
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
      debugPrint(
          '⚠️ [AnnouncementManager] Non démarré, appeler start() d\'abord');
      return;
    }

    debugPrint('🔄 [AnnouncementManager] Rafraîchissement...');
    await _processActiveAnnouncements();
  }

  /// Normaliser un device ID pour la comparaison (insensible à la casse)
  String? _normalizeDeviceId(String? deviceId) {
    if (deviceId == null || deviceId.isEmpty) return null;
    return deviceId.trim().toUpperCase();
  }

  /// Vérifier si un device ID correspond à l'appareil local
  bool _checkDeviceMatch(String appareil, int messageId, String source) {
    final normalizedAppareil = _normalizeDeviceId(appareil);
    final normalizedDeviceId = _normalizeDeviceId(_deviceId);

    // Vérifier correspondance directe
    if (normalizedDeviceId != null &&
        normalizedAppareil != null &&
        normalizedAppareil == normalizedDeviceId) {
      debugPrint(
          '✅ [AnnouncementManager] Message #$messageId: Match trouvé via $source');
      debugPrint('   - "$normalizedAppareil" == "$normalizedDeviceId"');
      return true;
    }

    // Vérifier liste séparée par virgules
    if (appareil.contains(',')) {
      final deviceIds =
          appareil.split(',').map((e) => _normalizeDeviceId(e)).toList();
      if (normalizedDeviceId != null &&
          deviceIds.contains(normalizedDeviceId)) {
        debugPrint(
            '✅ [AnnouncementManager] Message #$messageId: Match trouvé dans liste via $source');
        debugPrint('   - Liste: $deviceIds');
        return true;
      }
    }

    return false;
  }

  /// Vérifier si le message est destiné à cet appareil
  /// LOGIQUE OR: Vérifie device_id OU uuid (message ou gare)
  bool _isForThisDevice(MessageModel message) {
    final appareil = message.appareil?.trim();
    final messageUuid = message.uuid?.trim();
    final gareAppareil = message.gare?.appareil?.trim();
    final gareUuid = message.gare?.uuid?.trim();

    debugPrint('🔍 [AnnouncementManager] Vérification message #${message.id}:');
    debugPrint('   - appareil dans message: "$appareil"');
    debugPrint('   - UUID dans message: "$messageUuid"');
    debugPrint('   - appareil de la gare: "$gareAppareil"');
    debugPrint('   - UUID de la gare: "$gareUuid"');
    debugPrint('   - device ID local: "$_deviceId"');
    debugPrint('   - UUID local: "$_uuid"');
    debugPrint('   - type: ${message.type}');
    debugPrint('   - isAnnonce: ${message.isAnnonce}');

    // Si pas d'appareil spécifié ou 'tous', l'annonce concerne tout le monde
    if ((appareil == null ||
            appareil.isEmpty ||
            appareil.toLowerCase() == 'tous') &&
        (messageUuid == null || messageUuid.isEmpty) &&
        (gareAppareil == null ||
            gareAppareil.isEmpty ||
            gareAppareil.toLowerCase() == 'tous') &&
        (gareUuid == null || gareUuid.isEmpty)) {
      debugPrint(
          '✅ [AnnouncementManager] Message #${message.id} pour TOUS les appareils');
      return true;
    }

    // ✅ RÈGLE PRINCIPALE: Pour les ANNONCES, ignorer "mobile" pour appareil (mais vérifier UUID)
    if (message.isAnnonce &&
        appareil != null &&
        appareil.toLowerCase() == 'mobile' &&
        (messageUuid == null || messageUuid.isEmpty) &&
        (gareUuid == null || gareUuid.isEmpty)) {
      debugPrint(
          '❌ [AnnouncementManager] Annonce #${message.id} avec appareil="mobile" et pas d\'UUID - IGNORÉE');
      debugPrint(
          '   ℹ️ Les annonces doivent cibler un device_id SPÉCIFIQUE ou un UUID');
      return false;
    }

    // Pour les notifications normales (pas annonces), accepter "mobile"
    if (!message.isAnnonce &&
        appareil != null &&
        appareil.toLowerCase() == 'mobile') {
      debugPrint(
          '✅ [AnnouncementManager] Notification #${message.id} pour catégorie "mobile"');
      return true;
    }

    // ✅ LOGIQUE OR: Vérifier device_id OU UUID

    // 1. Vérifier device_id du message
    if (appareil != null &&
        appareil.isNotEmpty &&
        appareil.toLowerCase() != 'mobile' &&
        appareil.toLowerCase() != 'tous') {
      if (_checkDeviceMatch(appareil, message.id, 'message.appareil')) {
        debugPrint('✅ [AnnouncementManager] Match trouvé via message.appareil');
        return true;
      }
    }

    // 2. Vérifier UUID du message
    if (messageUuid != null && messageUuid.isNotEmpty && _uuid != null) {
      if (_checkUuidMatch(messageUuid, message.id, 'message.uuid')) {
        debugPrint('✅ [AnnouncementManager] Match trouvé via message.uuid');
        return true;
      }
    }

    // 3. Vérifier device_id de la gare
    if (gareAppareil != null &&
        gareAppareil.isNotEmpty &&
        gareAppareil.toLowerCase() != 'tous') {
      if (_checkDeviceMatch(gareAppareil, message.id, 'gare.appareil')) {
        debugPrint('✅ [AnnouncementManager] Match trouvé via gare.appareil');
        return true;
      }
    }

    // 4. Vérifier UUID de la gare
    if (gareUuid != null && gareUuid.isNotEmpty && _uuid != null) {
      if (_checkUuidMatch(gareUuid, message.id, 'gare.uuid')) {
        debugPrint('✅ [AnnouncementManager] Match trouvé via gare.uuid');
        return true;
      }
    }

    // Aucun match trouvé - cette annonce n'est pas pour cet appareil
    debugPrint(
        '❌ [AnnouncementManager] Annonce #${message.id} NON destinée à cet appareil');
    debugPrint('   - message.appareil: $appareil');
    debugPrint('   - message.uuid: $messageUuid');
    debugPrint('   - gare.appareil: $gareAppareil');
    debugPrint('   - gare.uuid: $gareUuid');
    debugPrint('   - device_id local: $_deviceId');
    debugPrint('   - UUID local: $_uuid');
    debugPrint(
        '   ℹ️ Pour cibler cet appareil, utilisez le device_id ou UUID exact dans l\'admin');
    return false;
  }

  /// Vérifier si un UUID correspond (comparaison insensible à la casse)
  bool _checkUuidMatch(String messageUuid, int messageId, String source) {
    final normalizedMessageUuid = messageUuid.trim().toUpperCase();
    final normalizedLocalUuid = _uuid?.trim().toUpperCase();

    if (normalizedLocalUuid != null &&
        normalizedMessageUuid == normalizedLocalUuid) {
      debugPrint(
          '✅ [AnnouncementManager] Message #$messageId: Match UUID trouvé via $source');
      debugPrint('   - "$normalizedMessageUuid" == "$normalizedLocalUuid"');
      return true;
    }

    // Vérifier liste séparée par virgules
    if (messageUuid.contains(',')) {
      final uuids =
          messageUuid.split(',').map((e) => e.trim().toUpperCase()).toList();
      if (normalizedLocalUuid != null && uuids.contains(normalizedLocalUuid)) {
        debugPrint(
            '✅ [AnnouncementManager] Message #$messageId: Match UUID trouvé dans liste via $source');
        debugPrint('   - Liste: $uuids');
        return true;
      }
    }

    return false;
  }

  /// Traiter un nouveau message reçu via notification push
  Future<void> handleNewMessage(MessageModel message) async {
    if (!_isRunning) {
      await start();
    }

    if (!message.isAnnonce || !message.isCurrentlyActive) {
      debugPrint(
          '⚠️ [AnnouncementManager] Message ignoré (pas une annonce active)');
      return;
    }

    // Vérifier si l'annonce concerne cet appareil
    if (!_isForThisDevice(message)) {
      debugPrint(
          '⚠️ [AnnouncementManager] Annonce #${message.id} ignorée (pas pour cet appareil)');
      return;
    }

    if (_processedMessageIds.contains(message.id)) {
      debugPrint(
          'ℹ️ [AnnouncementManager] Annonce #${message.id} déjà traitée');
      return;
    }

    debugPrint(
        '🆕 [AnnouncementManager] Nouvelle annonce reçue #${message.id}');

    // Vérifier si le context est disponible pour l'overlay
    if (_context != null) {
      debugPrint('✅ [AnnouncementManager] Démarrage avec overlay visuel');
      await _voiceService.startAnnouncement(message, _context);
    } else {
      debugPrint(
          '⚠️ [AnnouncementManager] Contexte non disponible - annonce AUDIO SEULEMENT (pas d\'overlay)');
      await _voiceService.startAnnouncement(message);
    }

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
  int get activeAnnouncementsCount =>
      _voiceService.getActiveAnnouncements().length;
}
