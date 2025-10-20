class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  /// Obtenir l'icône en fonction du type de notification
  String getIconType() {
    switch (type.toLowerCase()) {
      case 'new_feedback':
        return 'feedback';
      case 'feedback_status':
        return 'status';
      case 'promotion':
      case 'offer':
        return 'offer';
      case 'reminder':
      case 'travel':
        return 'travel';
      case 'loyalty':
      case 'points':
        return 'points';
      case 'alert':
      case 'urgent':
        return 'alert';
      default:
        return 'general';
    }
  }

  /// Obtenir le temps écoulé en format lisible
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'maintenant';
    }
  }
}

/// Réponse API pour les notifications
class NotificationResponse {
  final bool success;
  final String message;
  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;

  NotificationResponse({
    required this.success,
    required this.message,
    required this.notifications,
    this.total = 0,
    this.unreadCount = 0,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final notificationsList = json['data']?['notifications'] ?? json['notifications'] ?? [];
    
    return NotificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      notifications: (notificationsList as List)
          .map((notif) => NotificationModel.fromJson(notif))
          .toList(),
      total: json['data']?['total'] ?? json['total'] ?? 0,
      unreadCount: json['data']?['unread_count'] ?? json['unread_count'] ?? 0,
    );
  }
}
