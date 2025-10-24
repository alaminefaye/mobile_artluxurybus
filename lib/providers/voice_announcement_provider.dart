import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/voice_announcement_service.dart';

/// Provider pour le service d'annonces vocales
final voiceAnnouncementServiceProvider = Provider<VoiceAnnouncementService>((ref) {
  return VoiceAnnouncementService();
});

/// Provider pour vérifier si les annonces vocales sont activées
final voiceAnnouncementsEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(voiceAnnouncementServiceProvider);
  return await service.isEnabled();
});

/// Provider pour obtenir l'intervalle de répétition
final voiceRepeatIntervalProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(voiceAnnouncementServiceProvider);
  return await service.getRepeatInterval();
});

/// Provider pour obtenir la liste des annonces actives
final activeVoiceAnnouncementsProvider = Provider<List<MessageModel>>((ref) {
  final service = ref.watch(voiceAnnouncementServiceProvider);
  return service.getActiveAnnouncements();
});

/// State Notifier pour gérer l'état des annonces vocales
class VoiceAnnouncementNotifier extends StateNotifier<AsyncValue<void>> {
  final VoiceAnnouncementService _service;

  VoiceAnnouncementNotifier(this._service) : super(const AsyncValue.data(null));

  /// Démarrer une annonce vocale
  Future<void> startAnnouncement(MessageModel message) async {
    state = const AsyncValue.loading();
    
    try {
      await _service.startAnnouncement(message);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Arrêter une annonce spécifique
  Future<void> stopAnnouncement(int messageId) async {
    await _service.stopAnnouncement(messageId);
  }

  /// Arrêter toutes les annonces
  Future<void> stopAllAnnouncements() async {
    await _service.stopAllAnnouncements();
  }

  /// Activer/Désactiver les annonces vocales
  Future<void> setEnabled(bool enabled) async {
    await _service.setEnabled(enabled);
  }

  /// Définir l'intervalle de répétition
  Future<void> setRepeatInterval(int minutes) async {
    await _service.setRepeatInterval(minutes);
  }

  /// Lire un texte immédiatement
  Future<void> speakOnce(String text) async {
    await _service.speakOnce(text);
  }

  /// Arrêter la lecture en cours
  Future<void> stop() async {
    await _service.stop();
  }
}

/// Provider pour le VoiceAnnouncementNotifier
final voiceAnnouncementNotifierProvider = StateNotifierProvider<VoiceAnnouncementNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(voiceAnnouncementServiceProvider);
  return VoiceAnnouncementNotifier(service);
});
