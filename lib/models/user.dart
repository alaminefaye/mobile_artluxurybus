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
  final List<String>? rolesList; // Liste des rôles depuis l'API

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
    this.rolesList,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Récupérer le rôle depuis display_role, roles[0], ou role (pour compatibilité)
    String? role;
    if (json['display_role'] != null && json['display_role'].toString().isNotEmpty) {
      role = json['display_role'].toString();
    } else if (json['roles'] != null && 
                json['roles'] is List && 
                (json['roles'] as List).isNotEmpty) {
      role = (json['roles'] as List).first.toString();
    } else if (json['role'] != null) {
      role = json['role'].toString();
    }
    
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePhoto: json['profile_photo'],
      cities: json['cities'] != null ? List<String>.from(json['cities']) : null,
      phoneNumber: json['phone_number'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      role: role,
      permissions: json['permissions'] != null ? List<String>.from(json['permissions']) : null,
      rolesList: json['roles'] != null ? List<String>.from(json['roles']) : null,
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
      'roles': rolesList,
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
    List<String>? rolesList,
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
      rolesList: rolesList ?? this.rolesList,
    );
  }

  // Getters pour compatibilité avec l'ancien code
  String? get displayName => name;
  String? get displayRole => role;
  List<String>? get roles => rolesList ?? permissions; // Préférer rolesList, sinon permissions
  String? get phone => phoneNumber;
  
  // Getter pour l'URL complète de la photo de profil
  String? get profilePhotoUrl {
    if (profilePhoto == null) return null;
    // Si c'est déjà une URL complète, la retourner telle quelle
    if (profilePhoto!.startsWith('http')) return profilePhoto;
    // Sinon, construire l'URL complète
    return 'https://skf-artluxurybus.com/storage/$profilePhoto';
  }
}

// Note: Fonctions de conversion supprimées car plus utilisées avec les nouvelles méthodes fromJson/toJson manuelles
