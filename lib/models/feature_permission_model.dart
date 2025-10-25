/// Modèle pour les permissions de fonctionnalités
class FeaturePermission {
  final String featureCode;
  final String featureName;
  final String? description;
  final String category;
  final String? icon;
  final String? color;
  final bool isEnabled;
  final bool requiresAdmin;

  FeaturePermission({
    required this.featureCode,
    required this.featureName,
    this.description,
    required this.category,
    this.icon,
    this.color,
    required this.isEnabled,
    required this.requiresAdmin,
  });

  factory FeaturePermission.fromJson(Map<String, dynamic> json) {
    return FeaturePermission(
      featureCode: json['feature_code'] ?? '',
      featureName: json['feature_name'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'general',
      icon: json['icon'],
      color: json['color'],
      isEnabled: json['is_enabled'] ?? false,
      requiresAdmin: json['requires_admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feature_code': featureCode,
      'feature_name': featureName,
      'description': description,
      'category': category,
      'icon': icon,
      'color': color,
      'is_enabled': isEnabled,
      'requires_admin': requiresAdmin,
    };
  }

  FeaturePermission copyWith({
    String? featureCode,
    String? featureName,
    String? description,
    String? category,
    String? icon,
    String? color,
    bool? isEnabled,
    bool? requiresAdmin,
  }) {
    return FeaturePermission(
      featureCode: featureCode ?? this.featureCode,
      featureName: featureName ?? this.featureName,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isEnabled: isEnabled ?? this.isEnabled,
      requiresAdmin: requiresAdmin ?? this.requiresAdmin,
    );
  }
}

/// Réponse de l'API pour les permissions
class FeaturePermissionsResponse {
  final List<FeaturePermission> permissions;
  final int userId;
  final String userName;
  final String? userRole;

  FeaturePermissionsResponse({
    required this.permissions,
    required this.userId,
    required this.userName,
    this.userRole,
  });

  factory FeaturePermissionsResponse.fromJson(Map<String, dynamic> json) {
    return FeaturePermissionsResponse(
      permissions: (json['permissions'] as List?)
              ?.map((p) => FeaturePermission.fromJson(p))
              .toList() ??
          [],
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      userRole: json['user_role'],
    );
  }
}

/// Codes de fonctionnalités (constantes)
class FeatureCodes {
  // Client
  static const String reservation = 'reservation';
  static const String mesOffres = 'mes_offres';
  static const String loyalty = 'loyalty';
  static const String feedback = 'feedback';
  static const String gares = 'gares';
  static const String payment = 'payment';
  static const String horaires = 'horaires';
  static const String support = 'support';

  // Admin
  static const String busManagement = 'bus_management';
  static const String courrier = 'courrier';
  static const String userManagement = 'user_management';
  static const String notificationsAdmin = 'notifications_admin';

  // Général
  static const String messages = 'messages';
  static const String notifications = 'notifications';
}
