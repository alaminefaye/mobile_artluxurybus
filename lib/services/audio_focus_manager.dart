import 'dart:async';
import 'package:flutter/foundation.dart';

/// Gestionnaire global pour gérer les conflits audio
/// Met en pause les vidéos quand une annonce vocale est active
class AudioFocusManager {
  static final AudioFocusManager _instance = AudioFocusManager._internal();
  factory AudioFocusManager() => _instance;
  AudioFocusManager._internal();

  // Stream pour notifier les changements d'état audio
  final StreamController<bool> _voiceAnnouncementActiveController = 
      StreamController<bool>.broadcast();
  
  Stream<bool> get voiceAnnouncementActiveStream => 
      _voiceAnnouncementActiveController.stream;

  bool _isVoiceAnnouncementActive = false;
  
  /// Liste des callbacks pour mettre en pause/reprendre les vidéos
  final Set<VoidCallback> _pauseCallbacks = {};
  final Set<VoidCallback> _resumeCallbacks = {};

  /// Vérifier si une annonce vocale est active
  bool get isVoiceAnnouncementActive => _isVoiceAnnouncementActive;

  /// Notifier qu'une annonce vocale commence
  void startVoiceAnnouncement() {
    if (_isVoiceAnnouncementActive) return;
    
    _isVoiceAnnouncementActive = true;
    debugPrint('🔇 [AudioFocus] Annonce vocale démarrée - Mise en pause de tous les audios');
    
    // Notifier via stream
    _voiceAnnouncementActiveController.add(true);
    
    // Appeler tous les callbacks de pause
    for (var callback in _pauseCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('⚠️ [AudioFocus] Erreur callback pause: $e');
      }
    }
  }

  /// Notifier qu'une annonce vocale se termine
  void stopVoiceAnnouncement() {
    if (!_isVoiceAnnouncementActive) return;
    
    _isVoiceAnnouncementActive = false;
    debugPrint('🔊 [AudioFocus] Annonce vocale terminée - Reprise des audios');
    
    // Notifier via stream
    _voiceAnnouncementActiveController.add(false);
    
    // Appeler tous les callbacks de reprise
    for (var callback in _resumeCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('⚠️ [AudioFocus] Erreur callback resume: $e');
      }
    }
  }

  /// Enregistrer un callback de pause (appelé quand annonce démarre)
  void registerPauseCallback(VoidCallback callback) {
    _pauseCallbacks.add(callback);
    debugPrint('📌 [AudioFocus] Callback pause enregistré (${_pauseCallbacks.length} total)');
  }

  /// Enregistrer un callback de reprise (appelé quand annonce termine)
  void registerResumeCallback(VoidCallback callback) {
    _resumeCallbacks.add(callback);
    debugPrint('📌 [AudioFocus] Callback resume enregistré (${_resumeCallbacks.length} total)');
  }

  /// Désenregistrer les callbacks
  void unregisterCallbacks(VoidCallback? pauseCallback, VoidCallback? resumeCallback) {
    if (pauseCallback != null) {
      _pauseCallbacks.remove(pauseCallback);
    }
    if (resumeCallback != null) {
      _resumeCallbacks.remove(resumeCallback);
    }
    debugPrint('📌 [AudioFocus] Callbacks désenregistrés');
  }

  /// Nettoyer tous les callbacks
  void clearAllCallbacks() {
    _pauseCallbacks.clear();
    _resumeCallbacks.clear();
    debugPrint('🧹 [AudioFocus] Tous les callbacks nettoyés');
  }

  /// Dispose
  void dispose() {
    _voiceAnnouncementActiveController.close();
    clearAllCallbacks();
  }
}
