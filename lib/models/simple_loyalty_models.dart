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
    final ticketsList = (json['recent_tickets'] ?? json['tickets'] ?? json['recentTickets'] ?? []) as List? ?? [];
    final mailsList = (json['recent_mails'] ?? json['mails'] ?? json['recentMails'] ?? json['recent_courriers'] ?? []) as List? ?? [];
    return LoyaltyHistory(
      recentTickets: ticketsList.map((item) => LoyaltyTicket.fromJson(item as Map<String, dynamic>)).toList(),
      recentMails: mailsList.map((item) => LoyaltyMail.fromJson(item as Map<String, dynamic>)).toList(),
      totalTicketsCount: json['total_tickets_count'] ?? json['tickets_count'] ?? 0,
      totalMailsCount: json['total_mails_count'] ?? json['mails_count'] ?? json['courriers_count'] ?? 0,
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
  final bool isLoyaltyReward;
  final String createdAt;

  const LoyaltyTicket({
    required this.id,
    required this.trajet,
    required this.embarquement,
    required this.destination,
    required this.prix,
    required this.dateDepart,
    required this.isPassthrough,
    required this.isLoyaltyReward,
    required this.createdAt,
  });

  factory LoyaltyTicket.fromJson(Map<String, dynamic> json) {
    // Helper pour parser le prix (peut être String ou int)
    int parsePrix(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed?.toInt() ?? 0;
      }
      return 0;
    }
    
    // Helper pour parser les booléens (peut être 0/1 ou true/false)
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }
    
    return LoyaltyTicket(
      id: json['id'] ?? 0,
      trajet: json['trajet'] ?? json['route'] ?? '',
      embarquement: json['embarquement'] ?? json['ville_depart'] ?? json['from'] ?? '',
      destination: json['destination'] ?? json['ville_destination'] ?? json['to'] ?? '',
      prix: parsePrix(json['prix'] ?? json['price'] ?? json['amount']),
      dateDepart: json['date_depart'] ?? json['date'] ?? json['depart_at'] ?? '',
      isPassthrough: parseBool(json['is_passthrough'] ?? json['passthrough']),
      isLoyaltyReward: parseBool(json['is_loyalty_reward'] ?? json['loyalty_reward'] ?? json['is_free']),
      createdAt: json['created_at'] ?? json['createdAt'] ?? json['created'] ?? json['date'] ?? '',
    );
  }
}

class LoyaltyMail {
  final int id;
  final String? mailNumber;
  final String destinataire;
  final String villeDestination;
  final int prix;
  final bool isCollected;
  final bool isLoyaltyMail;
  final String createdAt;

  const LoyaltyMail({
    required this.id,
    this.mailNumber,
    required this.destinataire,
    required this.villeDestination,
    required this.prix,
    required this.isCollected,
    required this.isLoyaltyMail,
    required this.createdAt,
  });

  factory LoyaltyMail.fromJson(Map<String, dynamic> json) {
    // Helper pour parser le prix (peut être String ou int)
    int parsePrix(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed?.toInt() ?? 0;
      }
      return 0;
    }
    
    // Helper pour parser les booléens (peut être 0/1 ou true/false)
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }
    
    return LoyaltyMail(
      id: json['id'] ?? 0,
      mailNumber: json['mail_number'],
      destinataire: json['recipient_name'] ?? json['destinataire'] ?? json['recipient'] ?? '',
      villeDestination: json['destination'] ?? json['ville_destination'] ?? json['to'] ?? '',
      prix: parsePrix(json['amount'] ?? json['prix'] ?? json['price']),
      isCollected: parseBool(json['is_collected'] ?? json['collected']),
      isLoyaltyMail: parseBool(json['is_loyalty_mail'] ?? json['loyalty']),
      createdAt: json['created_at'] ?? json['createdAt'] ?? json['date'] ?? '',
    );
  }
  
  String get statut => isCollected ? 'Collecté' : 'En attente';
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
    // Certaines réponses peuvent être enveloppées dans { success, message, data: { client, history } }
    final Map<String, dynamic> root = json;
    final Map<String, dynamic> data = (json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : root;

    final clientJson = (data['client'] ?? root['client']);
    final historyJson = (data['history'] ?? root['history']);

    return LoyaltyProfileResponse(
      success: (root['success'] ?? data['success'] ?? true) as bool,
      message: (root['message'] ?? data['message'] ?? '') as String,
      client: (clientJson is Map<String, dynamic>) ? LoyaltyClient.fromJson(clientJson) : null,
      history: (historyJson is Map<String, dynamic>) ? LoyaltyHistory.fromJson(historyJson) : null,
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
