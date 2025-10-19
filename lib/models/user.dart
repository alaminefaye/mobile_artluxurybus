// import 'package:json_annotation/json_annotation.dart';
// part 'user.g.dart';

// @JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;
  // @JsonKey(name: 'profile_photo')
  final String? profilePhoto;
  // @JsonKey(fromJson: _citiesFromJson, toJson: _citiesToJson)
  final List<String>? cities;
  // @JsonKey(name: 'display_name')
  // final String? displayName;
  // @JsonKey(name: 'display_role')
  // final String? displayRole;
  // @JsonKey(fromJson: _rolesFromJson, toJson: _rolesToJson)
  // final List<String>? roles;
  // @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  // @JsonKey(name: 'created_at')
  final String? createdAt;
  // @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final String? role;
  // @JsonKey(fromJson: _permissionsFromJson, toJson: _permissionsToJson)
  final List<String>? permissions;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
    this.cities,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
    this.role,
    this.permissions,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePhoto: json['profile_photo'],
      cities: json['cities'] != null ? List<String>.from(json['cities']) : null,
      phoneNumber: json['phone_number'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      role: json['role'],
      permissions: json['permissions'] != null ? List<String>.from(json['permissions']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_photo': profilePhoto,
      'cities': cities,
      'phone_number': phoneNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'role': role,
      'permissions': permissions,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? profilePhoto,
    List<String>? cities,
    String? phoneNumber,
    String? createdAt,
    String? updatedAt,
    String? role,
    List<String>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      cities: cities ?? this.cities,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
    );
  }

  // Getters pour compatibilité avec l'ancien code
  String? get displayName => name;
  String? get displayRole => role;
  List<String>? get roles => permissions;
}

// Note: Fonctions de conversion supprimées car plus utilisées avec les nouvelles méthodes fromJson/toJson manuelles
