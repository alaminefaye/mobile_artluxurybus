class LoyaltyClient {
  final int id;
  final String nomComplet;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final int pointsTickets;
  final int pointsCourriers;
  final int totalPoints;
  final bool canGetFreeTicket;
  final bool canGetFreeMail;
  final int? ticketsRequiredForFree;
  final int? mailsRequiredForFree;
  final String? memberSince;
  final String? lastActivity;
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

  factory LoyaltyClient.fromJson(Map<String, dynamic> json) {
    return LoyaltyClient(
      id: json['id'] ?? 0,
      nomComplet: json['nom_complet'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'],
      pointsTickets: json['points_tickets'] ?? 0,
      pointsCourriers: json['points_courriers'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
      canGetFreeTicket: json['can_get_free_ticket'] ?? false,
      canGetFreeMail: json['can_get_free_mail'] ?? false,
      ticketsRequiredForFree: json['tickets_required_for_free'],
      mailsRequiredForFree: json['mails_required_for_free'],
      memberSince: json['member_since'],
      lastActivity: json['last_activity'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_complet': nomComplet,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'points_tickets': pointsTickets,
      'points_courriers': pointsCourriers,
      'total_points': totalPoints,
      'can_get_free_ticket': canGetFreeTicket,
      'can_get_free_mail': canGetFreeMail,
      'tickets_required_for_free': ticketsRequiredForFree,
      'mails_required_for_free': mailsRequiredForFree,
      'member_since': memberSince,
      'last_activity': lastActivity,
      'created_at': createdAt,
    };
  }

  // Getters utiles
  int get pointsTicketsRemaining => canGetFreeTicket ? 0 : (10 - pointsTickets);
  int get pointsMailsRemaining => canGetFreeMail ? 0 : (10 - pointsCourriers);
  
  String get progressTickets => '$pointsTickets/10';
  String get progressMails => '$pointsCourriers/10';
  
  double get ticketsProgress => (pointsTickets / 10.0).clamp(0.0, 1.0);
  double get mailsProgress => (pointsCourriers / 10.0).clamp(0.0, 1.0);
}

class LoyaltyResponse {
  final bool success;
  final String message;
  final bool? exists;
  final LoyaltyClient? client;
  final String? phone;
  final bool? canRegister;
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

  factory LoyaltyResponse.fromJson(Map<String, dynamic> json) {
    return LoyaltyResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      exists: json['exists'],
      client: json['client'] != null ? LoyaltyClient.fromJson(json['client']) : null,
      phone: json['phone'],
      canRegister: json['can_register'],
      clientExists: json['client_exists'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'exists': exists,
      'client': client?.toJson(),
      'phone': phone,
      'can_register': canRegister,
      'client_exists': clientExists,
    };
  }
}

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

  factory LoyaltyRegisterRequest.fromJson(Map<String, dynamic> json) {
    return LoyaltyRegisterRequest(
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
    };
  }
}

class LoyaltyCheckRequest {
  final String phone;

  const LoyaltyCheckRequest({
    required this.phone,
  });

  factory LoyaltyCheckRequest.fromJson(Map<String, dynamic> json) {
    return LoyaltyCheckRequest(
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
    };
  }
}

// Classes pour l'historique
class LoyaltyHistory {
  final List<LoyaltyTicket> recentTickets;
  final List<LoyaltyMail> recentMails;
  final int totalTicketsCount;
  final int totalMailsCount;

  const LoyaltyHistory({
    required this.recentTickets,
    required this.recentMails,
    required this.totalTicketsCount,
    required this.totalMailsCount,
  });

  factory LoyaltyHistory.fromJson(Map<String, dynamic> json) {
    return LoyaltyHistory(
      recentTickets: (json['recent_tickets'] as List? ?? [])
          .map((item) => LoyaltyTicket.fromJson(item))
          .toList(),
      recentMails: (json['recent_mails'] as List? ?? [])
          .map((item) => LoyaltyMail.fromJson(item))
          .toList(),
      totalTicketsCount: json['total_tickets_count'] ?? 0,
      totalMailsCount: json['total_mails_count'] ?? 0,
    );
  }
}

class LoyaltyTicket {
  final int id;
  final String trajet;
  final String embarquement;
  final String destination;
  final int prix;
  final String dateDepart;
  final bool isPassthrough;
  final String createdAt;

  const LoyaltyTicket({
    required this.id,
    required this.trajet,
    required this.embarquement,
    required this.destination,
    required this.prix,
    required this.dateDepart,
    required this.isPassthrough,
    required this.createdAt,
  });

  factory LoyaltyTicket.fromJson(Map<String, dynamic> json) {
    return LoyaltyTicket(
      id: json['id'] ?? 0,
      trajet: json['trajet'] ?? '',
      embarquement: json['embarquement'] ?? '',
      destination: json['destination'] ?? '',
      prix: json['prix'] ?? 0,
      dateDepart: json['date_depart'] ?? '',
      isPassthrough: json['is_passthrough'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class LoyaltyMail {
  final int id;
  final String destinataire;
  final String villeDestination;
  final int prix;
  final String statut;
  final bool isLoyaltyMail;
  final String createdAt;

  const LoyaltyMail({
    required this.id,
    required this.destinataire,
    required this.villeDestination,
    required this.prix,
    required this.statut,
    required this.isLoyaltyMail,
    required this.createdAt,
  });

  factory LoyaltyMail.fromJson(Map<String, dynamic> json) {
    return LoyaltyMail(
      id: json['id'] ?? 0,
      destinataire: json['destinataire'] ?? '',
      villeDestination: json['ville_destination'] ?? '',
      prix: json['prix'] ?? 0,
      statut: json['statut'] ?? '',
      isLoyaltyMail: json['is_loyalty_mail'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class LoyaltyProfileResponse extends LoyaltyResponse {
  final LoyaltyHistory? history;

  const LoyaltyProfileResponse({
    required super.success,
    required super.message,
    super.client,
    this.history,
  });

  factory LoyaltyProfileResponse.fromJson(Map<String, dynamic> json) {
    return LoyaltyProfileResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      client: json['client'] != null ? LoyaltyClient.fromJson(json['client']) : null,
      history: json['history'] != null ? LoyaltyHistory.fromJson(json['history']) : null,
    );
  }
}

class LoyaltyStats {
  final int totalClients;
  final int clientsWithTicketPoints;
  final int clientsWithMailPoints;
  final int clientsEligibleFreeTicket;
  final int clientsEligibleFreeMail;
  final int totalTicketPointsDistributed;
  final int totalMailPointsDistributed;
  final int totalPointsDistributed;

  const LoyaltyStats({
    required this.totalClients,
    required this.clientsWithTicketPoints,
    required this.clientsWithMailPoints,
    required this.clientsEligibleFreeTicket,
    required this.clientsEligibleFreeMail,
    required this.totalTicketPointsDistributed,
    required this.totalMailPointsDistributed,
    required this.totalPointsDistributed,
  });

  factory LoyaltyStats.fromJson(Map<String, dynamic> json) {
    return LoyaltyStats(
      totalClients: json['total_clients'] ?? 0,
      clientsWithTicketPoints: json['clients_with_ticket_points'] ?? 0,
      clientsWithMailPoints: json['clients_with_mail_points'] ?? 0,
      clientsEligibleFreeTicket: json['clients_eligible_free_ticket'] ?? 0,
      clientsEligibleFreeMail: json['clients_eligible_free_mail'] ?? 0,
      totalTicketPointsDistributed: json['total_ticket_points_distributed'] ?? 0,
      totalMailPointsDistributed: json['total_mail_points_distributed'] ?? 0,
      totalPointsDistributed: json['total_points_distributed'] ?? 0,
    );
  }
}

class LoyaltyStatsResponse {
  final bool success;
  final String message;
  final LoyaltyStats? stats;

  const LoyaltyStatsResponse({
    required this.success,
    required this.message,
    this.stats,
  });

  factory LoyaltyStatsResponse.fromJson(Map<String, dynamic> json) {
    return LoyaltyStatsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      stats: json['stats'] != null ? LoyaltyStats.fromJson(json['stats']) : null,
    );
  }
}
