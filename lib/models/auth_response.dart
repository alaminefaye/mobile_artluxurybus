// import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

// part 'auth_response.g.dart';

// @JsonSerializable()
class AuthResponse {
  // @JsonKey(fromJson: _successFromJson)
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

// @JsonSerializable()
class AuthData {
  final User user;
  // @JsonKey(fromJson: _stringFromJson)
  final String token;
  // @JsonKey(name: 'token_type', fromJson: _stringFromJson)
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
