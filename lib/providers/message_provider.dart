import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/message_api_service.dart';

/// Provider pour le service API des messages
final messageApiServiceProvider = Provider<MessageApiService>((ref) {
  return MessageApiService();
});

/// Provider pour récupérer les messages actifs
final activeMessagesProvider = FutureProvider.autoDispose<List<MessageModel>>((ref) async {
  final service = ref.watch(messageApiServiceProvider);
  return await service.getActiveMessages();
});

/// Provider pour récupérer les messages actifs d'une gare spécifique
final activeMessagesByGareProvider = FutureProvider.autoDispose.family<List<MessageModel>, int?>((ref, gareId) async {
  final service = ref.watch(messageApiServiceProvider);
  return await service.getActiveMessages(gareId: gareId);
});

/// Provider pour récupérer uniquement les notifications
final notificationsProvider = FutureProvider.autoDispose<List<MessageModel>>((ref) async {
  final service = ref.watch(messageApiServiceProvider);
  return await service.getNotifications();
});

/// Provider pour récupérer uniquement les annonces
final annoncesProvider = FutureProvider.autoDispose<List<MessageModel>>((ref) async {
  final service = ref.watch(messageApiServiceProvider);
  return await service.getAnnonces();
});

/// Provider pour récupérer les annonces d'une gare spécifique
final annoncesByGareProvider = FutureProvider.autoDispose.family<List<MessageModel>, int?>((ref, gareId) async {
  final service = ref.watch(messageApiServiceProvider);
  return await service.getAnnonces(gareId: gareId);
});

/// Provider pour récupérer un message spécifique par ID
final messageByIdProvider = FutureProvider.autoDispose.family<MessageModel?, int>((ref, id) async {
  final service = ref.watch(messageApiServiceProvider);
  return await service.getMessage(id);
});

/// State Notifier pour gérer l'état des messages avec refresh manuel
class MessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final MessageApiService _service;
  int? _currentGareId;

  MessagesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadMessages();
  }

  /// Charger les messages
  Future<void> loadMessages({int? gareId}) async {
    _currentGareId = gareId;
    state = const AsyncValue.loading();
    
    try {
      final messages = await _service.getActiveMessages(gareId: gareId);
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Rafraîchir les messages
  Future<void> refresh() async {
    await loadMessages(gareId: _currentGareId);
  }

  /// Filtrer les messages par type
  List<MessageModel> filterByType(String type) {
    return state.maybeWhen(
      data: (messages) => messages.where((m) => m.type == type).toList(),
      orElse: () => [],
    );
  }

  /// Obtenir uniquement les notifications
  List<MessageModel> get notifications => filterByType('notification');

  /// Obtenir uniquement les annonces
  List<MessageModel> get annonces => filterByType('annonce');
}

/// Provider pour le MessagesNotifier
final messagesNotifierProvider = StateNotifierProvider<MessagesNotifier, AsyncValue<List<MessageModel>>>((ref) {
  final service = ref.watch(messageApiServiceProvider);
  return MessagesNotifier(service);
});

/// Provider pour compter les messages non lus (notifications uniquement)
final unreadMessagesCountProvider = Provider.autoDispose<int>((ref) {
  final messagesAsync = ref.watch(messagesNotifierProvider);
  
  return messagesAsync.maybeWhen(
    data: (messages) {
      // Compter uniquement les notifications (pas les annonces)
      return messages.where((m) => m.isNotification && m.isCurrentlyActive).length;
    },
    orElse: () => 0,
  );
});

/// Provider pour vérifier s'il y a de nouveaux messages
final hasNewMessagesProvider = Provider.autoDispose<bool>((ref) {
  final count = ref.watch(unreadMessagesCountProvider);
  return count > 0;
});
