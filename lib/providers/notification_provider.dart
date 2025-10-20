import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';

/// État des notifications
class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;
  final bool hasMore;
  final int currentPage;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
    this.hasMore = true,
    this.currentPage = 1,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
    bool? hasMore,
    int? currentPage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notifier pour gérer les notifications
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  /// Charger les notifications
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        notifications: [],
      );
    } else if (state.isLoading) {
      return; // Éviter les requêtes multiples
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await NotificationApiService.getNotifications(
        page: refresh ? 1 : state.currentPage,
        limit: 20,
      );

      // Notifications loaded successfully

      if (response.success) {
        final newNotifications = refresh 
          ? response.notifications
          : [...state.notifications, ...response.notifications];

        state = state.copyWith(
          notifications: newNotifications,
          isLoading: false,
          unreadCount: response.unreadCount,
          hasMore: response.notifications.length >= 20,
          currentPage: refresh ? 2 : state.currentPage + 1,
          error: null,
        );
      } else {
        // Afficher l'erreur réelle sans fallback
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de connexion: $e',
      );
    }
  }

  /// Charger plus de notifications
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadNotifications(refresh: false);
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(int notificationId) async {
    try {
      final result = await NotificationApiService.markAsRead(notificationId);
      
      if (result['success']) {
        // Mettre à jour localement
        final updatedNotifications = state.notifications.map((notif) {
          if (notif.id == notificationId && !notif.isRead) {
            return NotificationModel(
              id: notif.id,
              type: notif.type,
              title: notif.title,
              message: notif.message,
              data: notif.data,
              isRead: true,
              createdAt: notif.createdAt,
              readAt: DateTime.now(),
            );
          }
          return notif;
        }).toList();

        final newUnreadCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        );
      }
    } catch (e) {
      // Gestion d'erreur silencieuse pour ne pas perturber l'UX
      // Log l'erreur sans interrompre l'expérience utilisateur
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      final result = await NotificationApiService.markAllAsRead();
      
      if (result['success']) {
        final updatedNotifications = state.notifications.map((notif) {
          if (!notif.isRead) {
            return NotificationModel(
              id: notif.id,
              type: notif.type,
              title: notif.title,
              message: notif.message,
              data: notif.data,
              isRead: true,
              createdAt: notif.createdAt,
              readAt: DateTime.now(),
            );
          }
          return notif;
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        );
      }
    } catch (e) {
      // Gestion d'erreur silencieuse pour ne pas perturber l'UX
    }
  }

  /// Supprimer une notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final result = await NotificationApiService.deleteNotification(notificationId);
      
      if (result['success']) {
        final updatedNotifications = state.notifications
            .where((notif) => notif.id != notificationId)
            .toList();

        final deletedNotif = state.notifications
            .firstWhere((notif) => notif.id == notificationId);
        
        final newUnreadCount = deletedNotif.isRead 
          ? state.unreadCount 
          : (state.unreadCount > 0 ? state.unreadCount - 1 : 0);

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur suppression: $e');
    }
  }

  /// Rafraîchir les notifications
  Future<void> refresh() async {
    await loadNotifications(refresh: true);
  }

  /// Mettre à jour le compteur de notifications non lues
  Future<void> updateUnreadCount() async {
    try {
      final count = await NotificationApiService.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      // Gestion d'erreur silencieuse pour ne pas perturber l'UX
    }
  }

}

/// Provider pour les notifications
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);

/// Provider pour le compteur de notifications non lues uniquement
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
