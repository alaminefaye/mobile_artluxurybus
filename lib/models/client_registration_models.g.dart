// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_registration_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientSearchResponse _$ClientSearchResponseFromJson(
        Map<String, dynamic> json) =>
    ClientSearchResponse(
      success: json['success'] as bool,
      found: json['found'] as bool,
      message: json['message'] as String?,
      client: json['client'] == null
          ? null
          : ClientSearchData.fromJson(json['client'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClientSearchResponseToJson(
        ClientSearchResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'found': instance.found,
      'message': instance.message,
      'client': instance.client,
    };

ClientSearchData _$ClientSearchDataFromJson(Map<String, dynamic> json) =>
    ClientSearchData(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      telephone: json['telephone'] as String,
      email: json['email'] as String?,
      dateNaissance: json['date_naissance'] as String?,
      points: (json['points'] as num).toInt(),
      mailPoints: (json['mail_points'] as num).toInt(),
      hasAccount: json['has_account'] as bool,
      solde: json['solde'] == null
          ? 0.0
          : ClientSearchData._soldeFromJson(json['solde']),
    );

Map<String, dynamic> _$ClientSearchDataToJson(ClientSearchData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenom': instance.prenom,
      'telephone': instance.telephone,
      'email': instance.email,
      'date_naissance': instance.dateNaissance,
      'points': instance.points,
      'mail_points': instance.mailPoints,
      'has_account': instance.hasAccount,
      'solde': instance.solde,
    };

CreateAccountRequest _$CreateAccountRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAccountRequest(
      clientId: (json['client_id'] as num).toInt(),
      password: json['password'] as String,
      passwordConfirmation: json['password_confirmation'] as String,
      dateNaissance: json['date_naissance'] as String?,
    );

Map<String, dynamic> _$CreateAccountRequestToJson(
        CreateAccountRequest instance) =>
    <String, dynamic>{
      'client_id': instance.clientId,
      'password': instance.password,
      'password_confirmation': instance.passwordConfirmation,
      'date_naissance': instance.dateNaissance,
    };

RegisterClientRequest _$RegisterClientRequestFromJson(
        Map<String, dynamic> json) =>
    RegisterClientRequest(
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      telephone: json['telephone'] as String,
      email: json['email'] as String?,
      dateNaissance: json['date_naissance'] as String?,
      password: json['password'] as String,
      passwordConfirmation: json['password_confirmation'] as String,
    );

Map<String, dynamic> _$RegisterClientRequestToJson(
        RegisterClientRequest instance) =>
    <String, dynamic>{
      'nom': instance.nom,
      'prenom': instance.prenom,
      'telephone': instance.telephone,
      'email': instance.email,
      'date_naissance': instance.dateNaissance,
      'password': instance.password,
      'password_confirmation': instance.passwordConfirmation,
    };

ClientRegistrationResponse _$ClientRegistrationResponseFromJson(
        Map<String, dynamic> json) =>
    ClientRegistrationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] == null
          ? null
          : ClientRegistrationData.fromJson(
              json['data'] as Map<String, dynamic>),
      errors: json['errors'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ClientRegistrationResponseToJson(
        ClientRegistrationResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'errors': instance.errors,
    };

ClientRegistrationData _$ClientRegistrationDataFromJson(
        Map<String, dynamic> json) =>
    ClientRegistrationData(
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
      client: ClientData.fromJson(json['client'] as Map<String, dynamic>),
      token: json['token'] as String,
      tokenType: json['token_type'] as String,
    );

Map<String, dynamic> _$ClientRegistrationDataToJson(
        ClientRegistrationData instance) =>
    <String, dynamic>{
      'user': instance.user,
      'client': instance.client,
      'token': instance.token,
      'token_type': instance.tokenType,
    };

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      permissions: (json['permissions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'permissions': instance.permissions,
    };

ClientData _$ClientDataFromJson(Map<String, dynamic> json) => ClientData(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      telephone: json['telephone'] as String,
      email: json['email'] as String?,
      dateNaissance: json['date_naissance'] as String?,
      points: (json['points'] as num).toInt(),
      mailPoints: (json['mail_points'] as num).toInt(),
      solde: json['solde'] == null
          ? 0.0
          : ClientData._soldeFromJson(json['solde']),
    );

Map<String, dynamic> _$ClientDataToJson(ClientData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenom': instance.prenom,
      'telephone': instance.telephone,
      'email': instance.email,
      'date_naissance': instance.dateNaissance,
      'points': instance.points,
      'mail_points': instance.mailPoints,
      'solde': instance.solde,
    };
