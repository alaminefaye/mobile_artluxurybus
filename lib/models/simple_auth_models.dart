import 'user.dart';

class AuthResponse {
  final bool success;
  final String message;
  final AuthData? data;
  final Map<String, dynamic>? errors;

  AuthResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: _successFromJson(json['success']),
      message: json['message'] ?? '',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
      'errors': errors,
    };
  }
}

class AuthData {
  final User user;
  final String token;
  final String tokenType;

  AuthData({
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      user: User.fromJson(json['user'] ?? {}),
      token: _stringFromJson(json['token']),
      tokenType: _stringFromJson(json['token_type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'token_type': tokenType,
    };
  }
}

// Fonctions de conversion pour gérer différents types de données
bool _successFromJson(dynamic json) {
  if (json == null) return false;
  if (json is bool) return json;
  if (json is String) return json.toLowerCase() == 'true';
  if (json is int) return json != 0;
  return false;
}

String _stringFromJson(dynamic json) {
  if (json == null) return '';
  return json.toString();
}

// Classes pour les requêtes
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
