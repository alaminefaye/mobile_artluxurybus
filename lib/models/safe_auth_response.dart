// Version ultra-sécurisée de AuthResponse pour éviter tous les problèmes de cast
class SafeAuthResponse {
  final bool success;
  final String message;
  final SafeAuthData? data;
  final Map<String, dynamic>? errors;

  SafeAuthResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory SafeAuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      return SafeAuthResponse(
        success: _parseBool(json['success']),
        message: _parseString(json['message']),
        data: json['data'] != null ? SafeAuthData.fromJson(json['data']) : null,
        errors: json['errors'] is Map<String, dynamic> ? json['errors'] : null,
      );
    } catch (e) {
      // En cas d'erreur de parsing, retourner une réponse d'erreur
      return SafeAuthResponse(
        success: false,
        message: 'Erreur de parsing: $e',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data?.toJson(),
    'errors': errors,
  };

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return false;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}

class SafeAuthData {
  final SafeUser user;
  final String token;
  final String tokenType;

  SafeAuthData({
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory SafeAuthData.fromJson(Map<String, dynamic> json) {
    try {
      return SafeAuthData(
        user: SafeUser.fromJson(json['user'] ?? {}),
        token: _parseString(json['token']),
        tokenType: _parseString(json['token_type'] ?? 'Bearer'),
      );
    } catch (e) {
      throw Exception('Erreur parsing AuthData: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'token': token,
    'token_type': tokenType,
  };

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}

class SafeUser {
  final int id;
  final String name;
  final String email;
  final String? profilePhoto;
  final List<String>? cities;
  final String? displayName;
  final String? displayRole;
  final List<String>? roles;
  final List<String>? permissions;

  SafeUser({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
    this.cities,
    this.displayName,
    this.displayRole,
    this.roles,
    this.permissions,
  });

  factory SafeUser.fromJson(Map<String, dynamic> json) {
    try {
      return SafeUser(
        id: _parseInt(json['id']),
        name: _parseString(json['name']),
        email: _parseString(json['email']),
        profilePhoto: json['profile_photo']?.toString(),
        cities: _parseStringList(json['cities']),
        displayName: json['display_name']?.toString(),
        displayRole: json['display_role']?.toString(),
        roles: _parseStringList(json['roles']),
        permissions: _parseStringList(json['permissions']),
      );
    } catch (e) {
      throw Exception('Erreur parsing User: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'profile_photo': profilePhoto,
    'cities': cities,
    'display_name': displayName,
    'display_role': displayRole,
    'roles': roles,
    'permissions': permissions,
  };

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is Map) {
      return value.values.map((e) => e.toString()).toList();
    }
    return null;
  }

  SafeUser copyWith({
    int? id,
    String? name,
    String? email,
    String? profilePhoto,
    List<String>? cities,
    String? displayName,
    String? displayRole,
    List<String>? roles,
    List<String>? permissions,
  }) {
    return SafeUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      cities: cities ?? this.cities,
      displayName: displayName ?? this.displayName,
      displayRole: displayRole ?? this.displayRole,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
    );
  }
}
