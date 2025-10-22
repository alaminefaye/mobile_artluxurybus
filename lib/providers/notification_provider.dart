import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';
import 'auth_provider.dart';

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
/// Filtre les notifications de feedback pour les utilisateurs Pointage
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(notificationProvider);
  final authState = ref.watch(authProvider);
  
  // Si pas d'utilisateur connecté, retourner 0
  if (authState.user == null) {
    return 0;
  }
  
  final user = authState.user!;
  
  // Vérifier si l'utilisateur a le rôle Pointage
  bool hasAttendanceRole = false;
  
  // 1. Vérifier d'abord le rôle (si présent)
  if (user.role != null) {
    final roleLower = user.role!.toLowerCase();
    
    // Si c'est un admin, ne pas filtrer
    if (roleLower.contains('admin') || 
        roleLower.contains('super') ||
        roleLower.contains('administrateur')) {
      return notificationState.unreadCount;
    }
    
    // Si c'est un rôle pointage
    if (roleLower.contains('pointage') || 
        roleLower.contains('attendance') ||
        roleLower.contains('employee') ||
        roleLower.contains('employé') ||
        roleLower.contains('staff')) {
      hasAttendanceRole = true;
    }
  }
  
  // 2. Si pas de rôle, vérifier les permissions
  if (user.permissions != null && user.permissions!.isNotEmpty) {
    // Vérifier si l'utilisateur a des permissions admin
    for (var permission in user.permissions!) {
      final permLower = permission.toLowerCase();
      if (permLower.contains('manage_all') || 
          permLower.contains('admin') ||
          permLower.contains('super')) {
        return notificationState.unreadCount;
      }
    }
    
    // Vérifier si l'utilisateur a UNIQUEMENT des permissions de pointage
    bool hasOnlyAttendancePermissions = true;
    for (var permission in user.permissions!) {
      final permLower = permission.toLowerCase();
      
      // Si la permission n'est pas liée au pointage/attendance, c'est un utilisateur normal
      if (!permLower.contains('attendance') && 
          !permLower.contains('pointage') &&
          !permLower.contains('qr') &&
          !permLower.contains('scan') &&
          !permLower.contains('mark_attendance') &&
          !permLower.contains('view_own_attendance') &&
          !permLower.contains('personal_dashboard') &&
          !permLower.contains('locations')) {
        hasOnlyAttendancePermissions = false;
        break;
      }
    }
    
    if (hasOnlyAttendancePermissions) {
      hasAttendanceRole = true;
    }
  }
  
  // Si c'est un utilisateur Pointage, filtrer les notifications de feedback
  if (hasAttendanceRole) {
    final filteredNotifications = notificationState.notifications.where((notif) {
      return !notif.isRead && 
             notif.type != 'feedback' && 
             notif.type != 'suggestion' &&
             notif.type != 'new_feedback' &&
             notif.type != 'urgent_feedback';
    }).length;
    
    return filteredNotifications;
  }
  
  // Pour les autres utilisateurs, retourner le compteur complet
  return notificationState.unreadCount;
});
