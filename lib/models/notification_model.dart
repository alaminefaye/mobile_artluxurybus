import 'dart:convert';

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

  /// Helper pour convertir une valeur en booléen
  /// Gère les cas : bool, int (0/1), String ("true"/"false")
  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  /// Helper pour parser les données (peut être Map, String JSON, ou null)
  static Map<String, dynamic>? _parseData(dynamic dataValue) {
    if (dataValue == null) return null;
    if (dataValue is Map) return Map<String, dynamic>.from(dataValue);
    if (dataValue is String) {
      try {
        final decoded = jsonDecode(dataValue);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        // Si le parsing échoue, retourner null
        return null;
      }
    }
    return null;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Déterminer si la notification est lue
    // Peut être is_read ou read_at != null
    final isReadValue = json['is_read'];
    final readAtValue = json['read_at'];
    final isRead = isReadValue != null 
        ? _toBool(isReadValue) 
        : (readAtValue != null && readAtValue != '');

    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? json['contenu']?.toString() ?? '',
      data: _parseData(json['data']),
      isRead: isRead,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      readAt: readAtValue != null && readAtValue != '' 
          ? DateTime.tryParse(readAtValue.toString()) 
          : null,
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
    
    // Helper pour convertir en int
    int _toInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    // Helper pour parser les notifications
    List<NotificationModel> _parseNotifications(List list) {
      return list.map((notif) {
        if (notif is Map) {
          return NotificationModel.fromJson(Map<String, dynamic>.from(notif));
        }
        return NotificationModel(
          id: 0,
          type: 'general',
          title: '',
          message: '',
          createdAt: DateTime.now(),
        );
      }).toList();
    }
    
    final dataTotal = json['data']?['total'] ?? json['total'] ?? 0;
    final dataUnreadCount = json['data']?['unread_count'] ?? json['unread_count'] ?? 0;
    
    return NotificationResponse(
      success: NotificationModel._toBool(json['success']),
      message: json['message']?.toString() ?? '',
      notifications: _parseNotifications(notificationsList as List),
      total: _toInt(dataTotal),
      unreadCount: _toInt(dataUnreadCount),
    );
  }
}
