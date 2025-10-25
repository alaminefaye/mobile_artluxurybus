import 'package:json_annotation/json_annotation.dart';

part 'client_registration_models.g.dart';

/// Réponse de recherche de client
@JsonSerializable()
class ClientSearchResponse {
  final bool success;
  final bool found;
  final String? message;
  final ClientSearchData? client;

  ClientSearchResponse({
    required this.success,
    required this.found,
    this.message,
    this.client,
  });

  factory ClientSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$ClientSearchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ClientSearchResponseToJson(this);
}

/// Données du client trouvé
@JsonSerializable()
class ClientSearchData {
  final int id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  @JsonKey(name: 'date_naissance')
  final String? dateNaissance;
  final int points;
  @JsonKey(name: 'mail_points')
  final int mailPoints;
  @JsonKey(name: 'has_account')
  final bool hasAccount;

  ClientSearchData({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    this.dateNaissance,
    required this.points,
    required this.mailPoints,
    required this.hasAccount,
  });

  String get nomComplet => '$nom $prenom';

  factory ClientSearchData.fromJson(Map<String, dynamic> json) =>
      _$ClientSearchDataFromJson(json);

  Map<String, dynamic> toJson() => _$ClientSearchDataToJson(this);
}

/// Requête de création de compte pour client existant
@JsonSerializable()
class CreateAccountRequest {
  @JsonKey(name: 'client_id')
  final int clientId;
  final String password;
  @JsonKey(name: 'password_confirmation')
  final String passwordConfirmation;
  @JsonKey(name: 'date_naissance')
  final String? dateNaissance;

  CreateAccountRequest({
    required this.clientId,
    required this.password,
    required this.passwordConfirmation,
    this.dateNaissance,
  });

  factory CreateAccountRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAccountRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAccountRequestToJson(this);
}

/// Requête d'inscription complète (nouveau client)
@JsonSerializable()
class RegisterClientRequest {
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  @JsonKey(name: 'date_naissance')
  final String? dateNaissance;
  final String password;
  @JsonKey(name: 'password_confirmation')
  final String passwordConfirmation;

  RegisterClientRequest({
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    this.dateNaissance,
    required this.password,
    required this.passwordConfirmation,
  });

  factory RegisterClientRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterClientRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterClientRequestToJson(this);
}

/// Réponse d'inscription (création compte ou inscription complète)
@JsonSerializable()
class ClientRegistrationResponse {
  final bool success;
  final String message;
  final ClientRegistrationData? data;
  final Map<String, dynamic>? errors;

  ClientRegistrationResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ClientRegistrationResponse.fromJson(Map<String, dynamic> json) =>
      _$ClientRegistrationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ClientRegistrationResponseToJson(this);
}

/// Données de l'inscription réussie
@JsonSerializable()
class ClientRegistrationData {
  final UserData user;
  final ClientData client;
  final String token;
  @JsonKey(name: 'token_type')
  final String tokenType;

  ClientRegistrationData({
    required this.user,
    required this.client,
    required this.token,
    required this.tokenType,
  });

  factory ClientRegistrationData.fromJson(Map<String, dynamic> json) =>
      _$ClientRegistrationDataFromJson(json);

  Map<String, dynamic> toJson() => _$ClientRegistrationDataToJson(this);
}

/// Données utilisateur
@JsonSerializable()
class UserData {
  final int id;
  final String name;
  final String email;
  final String role;
  final List<String> permissions;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
  });

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}

/// Données client
@JsonSerializable()
class ClientData {
  final int id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  @JsonKey(name: 'date_naissance')
  final String? dateNaissance;
  final int points;
  @JsonKey(name: 'mail_points')
  final int mailPoints;

  ClientData({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    this.dateNaissance,
    required this.points,
    required this.mailPoints,
  });

  String get nomComplet => '$nom $prenom';

  factory ClientData.fromJson(Map<String, dynamic> json) =>
      _$ClientDataFromJson(json);

  Map<String, dynamic> toJson() => _$ClientDataToJson(this);
}
