// import 'package:json_annotation/json_annotation.dart';
// part 'loyalty_client.g.dart';

// ⚠️ FICHIER OBSOLÈTE ⚠️
// Ce fichier n'est plus utilisé dans l'application.
// Utiliser simple_loyalty_models.dart à la place pour toutes les fonctionnalités de fidélité.
// Ce fichier est conservé temporairement pour éviter les conflits de compilation.

// @JsonSerializable()
class LoyaltyClient {
  final int id;
  
  // @JsonKey(name: 'nom_complet')
  final String nomComplet;
  
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  
  // @JsonKey(name: 'points_tickets')
  final int pointsTickets;
  
  // @JsonKey(name: 'points_courriers')
  final int pointsCourriers;
  
  // @JsonKey(name: 'total_points')
  final int totalPoints;
  
  // @JsonKey(name: 'can_get_free_ticket')
  final bool canGetFreeTicket;
  
  // @JsonKey(name: 'can_get_free_mail')
  final bool canGetFreeMail;
  
  // @JsonKey(name: 'tickets_required_for_free')
  final int? ticketsRequiredForFree;
  
  // @JsonKey(name: 'mails_required_for_free')
  final int? mailsRequiredForFree;
  
  // @JsonKey(name: 'member_since')
  final String? memberSince;
  
  // @JsonKey(name: 'last_activity')
  final String? lastActivity;
  
  // @JsonKey(name: 'created_at')
  final String createdAt;

  const LoyaltyClient({
    required this.id,
    required this.nomComplet,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    required this.pointsTickets,
    required this.pointsCourriers,
    required this.totalPoints,
    required this.canGetFreeTicket,
    required this.canGetFreeMail,
    this.ticketsRequiredForFree,
    this.mailsRequiredForFree,
    this.memberSince,
    this.lastActivity,
    required this.createdAt,
  });

  // factory LoyaltyClient.fromJson(Map<String, dynamic> json) =>
  //     _$LoyaltyClientFromJson(json);
  // Map<String, dynamic> toJson() => _$LoyaltyClientToJson(this);

  // Getters utiles
  int get pointsTicketsRemaining => canGetFreeTicket ? 0 : (10 - pointsTickets);
  int get pointsMailsRemaining => canGetFreeMail ? 0 : (10 - pointsCourriers);
  
  String get progressTickets => '$pointsTickets/10';
  String get progressMails => '$pointsCourriers/10';
  
  double get ticketsProgress => pointsTickets / 10.0;
  double get mailsProgress => pointsCourriers / 10.0;
}

// @JsonSerializable()
class LoyaltyResponse {
  final bool success;
  final String message;
  final bool? exists;
  final LoyaltyClient? client;
  final String? phone;
  
  // @JsonKey(name: 'can_register')
  final bool? canRegister;
  
  // @JsonKey(name: 'client_exists')
  final bool? clientExists;

  const LoyaltyResponse({
    required this.success,
    required this.message,
    this.exists,
    this.client,
    this.phone,
    this.canRegister,
    this.clientExists,
  });

  // factory LoyaltyResponse.fromJson(Map<String, dynamic> json) =>
  //     _$LoyaltyResponseFromJson(json);
  // Map<String, dynamic> toJson() => _$LoyaltyResponseToJson(this);
}

// @JsonSerializable()
class LoyaltyRegisterRequest {
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;

  const LoyaltyRegisterRequest({
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
  });

  // factory LoyaltyRegisterRequest.fromJson(Map<String, dynamic> json) =>
  //     _$LoyaltyRegisterRequestFromJson(json);
  // Map<String, dynamic> toJson() => _$LoyaltyRegisterRequestToJson(this);
}

// @JsonSerializable()
class LoyaltyCheckRequest {
  final String phone;

  const LoyaltyCheckRequest({
    required this.phone,
  });

  // factory LoyaltyCheckRequest.fromJson(Map<String, dynamic> json) =>
  //     _$LoyaltyCheckRequestFromJson(json);
  // Map<String, dynamic> toJson() => _$LoyaltyCheckRequestToJson(this);
}
