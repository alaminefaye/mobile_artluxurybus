class Trip {
  final int id;
  final String nomComplet;
  final String telephone;
  final int? siegeNumber;
  final double? prix;
  final String? embarquement;
  final String? destination;
  final bool isPassthrough;
  final bool isLoyaltyReward;
  final String dateAchat;
  final String? dateAchatFormatted;
  final bool isCancelled;
  final String? dateAnnulation;
  final DepartInfo? depart;
  final StopInfo? embarkStop;
  final StopInfo? disembarkStop;

  Trip({
    required this.id,
    required this.nomComplet,
    required this.telephone,
    this.siegeNumber,
    this.prix,
    this.embarquement,
    this.destination,
    this.isPassthrough = false,
    this.isLoyaltyReward = false,
    required this.dateAchat,
    this.dateAchatFormatted,
    this.isCancelled = false,
    this.dateAnnulation,
    this.depart,
    this.embarkStop,
    this.disembarkStop,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    // Gérer is_passthrough qui peut être int (0/1) ou bool
    bool isPassthrough = false;
    if (json['is_passthrough'] != null) {
      if (json['is_passthrough'] is bool) {
        isPassthrough = json['is_passthrough'] as bool;
      } else if (json['is_passthrough'] is int) {
        isPassthrough = (json['is_passthrough'] as int) == 1;
      } else {
        isPassthrough = json['is_passthrough'].toString() == '1' || json['is_passthrough'].toString().toLowerCase() == 'true';
      }
    }

    // Gérer is_loyalty_reward qui peut être int (0/1) ou bool
    bool isLoyaltyReward = false;
    if (json['is_loyalty_reward'] != null) {
      if (json['is_loyalty_reward'] is bool) {
        isLoyaltyReward = json['is_loyalty_reward'] as bool;
      } else if (json['is_loyalty_reward'] is int) {
        isLoyaltyReward = (json['is_loyalty_reward'] as int) == 1;
      } else {
        isLoyaltyReward = json['is_loyalty_reward'].toString() == '1' || json['is_loyalty_reward'].toString().toLowerCase() == 'true';
      }
    }

    // Gérer is_cancelled qui peut être int (0/1) ou bool
    bool isCancelled = false;
    if (json['is_cancelled'] != null) {
      if (json['is_cancelled'] is bool) {
        isCancelled = json['is_cancelled'] as bool;
      } else if (json['is_cancelled'] is int) {
        isCancelled = (json['is_cancelled'] as int) == 1;
      } else {
        isCancelled = json['is_cancelled'].toString() == '1' || json['is_cancelled'].toString().toLowerCase() == 'true';
      }
    }

    return Trip(
      id: json['id'] ?? 0,
      nomComplet: json['nom_complet'] ?? '',
      telephone: json['telephone'] ?? '',
      siegeNumber: json['siege_number'],
      prix: json['prix'] != null ? (json['prix'] as num).toDouble() : null,
      embarquement: json['embarquement'],
      destination: json['destination'],
      isPassthrough: isPassthrough,
      isLoyaltyReward: isLoyaltyReward,
      dateAchat: json['date_achat'] ?? '',
      dateAchatFormatted: json['date_achat_formatted'],
      isCancelled: isCancelled,
      dateAnnulation: json['date_annulation'],
      depart: json['depart'] != null ? DepartInfo.fromJson(json['depart']) : null,
      embarkStop: json['embark_stop'] != null ? StopInfo.fromJson(json['embark_stop']) : null,
      disembarkStop: json['disembark_stop'] != null ? StopInfo.fromJson(json['disembark_stop']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_complet': nomComplet,
      'telephone': telephone,
      'siege_number': siegeNumber,
      'prix': prix,
      'embarquement': embarquement,
      'destination': destination,
      'is_passthrough': isPassthrough,
      'is_loyalty_reward': isLoyaltyReward,
      'date_achat': dateAchat,
      'date_achat_formatted': dateAchatFormatted,
      'is_cancelled': isCancelled,
      'date_annulation': dateAnnulation,
      'depart': depart?.toJson(),
      'embark_stop': embarkStop?.toJson(),
      'disembark_stop': disembarkStop?.toJson(),
    };
  }

  // Getter pour obtenir le texte du trajet
  String get routeText {
    if (depart?.trajet != null) {
      return '${depart!.trajet!.embarquement} → ${depart!.trajet!.destination}';
    }
    if (embarquement != null && destination != null) {
      return '$embarquement → $destination';
    }
    return 'Trajet non spécifié';
  }

  // Getter pour obtenir la date formatée
  String get formattedDate {
    if (depart?.dateDepartFormatted != null) {
      return depart!.dateDepartFormatted!;
    }
    return dateAchatFormatted ?? dateAchat;
  }
}

class DepartInfo {
  final int id;
  final String? dateDepart;
  final String? dateDepartFormatted;
  final String? heureDepart;
  final double? prixDepart;
  final String? numeroDepart;
  final bool isDirect;
  final TrajetInfo? trajet;
  final BusInfo? bus;

  DepartInfo({
    required this.id,
    this.dateDepart,
    this.dateDepartFormatted,
    this.heureDepart,
    this.prixDepart,
    this.numeroDepart,
    this.isDirect = false,
    this.trajet,
    this.bus,
  });

  factory DepartInfo.fromJson(Map<String, dynamic> json) {
    // Gérer is_direct qui peut être int (0/1) ou bool
    bool isDirect = false;
    if (json['is_direct'] != null) {
      if (json['is_direct'] is bool) {
        isDirect = json['is_direct'] as bool;
      } else if (json['is_direct'] is int) {
        isDirect = (json['is_direct'] as int) == 1;
      } else {
        isDirect = json['is_direct'].toString() == '1' || json['is_direct'].toString().toLowerCase() == 'true';
      }
    }

    return DepartInfo(
      id: json['id'] ?? 0,
      dateDepart: json['date_depart'],
      dateDepartFormatted: json['date_depart_formatted'],
      heureDepart: json['heure_depart'],
      prixDepart: json['prix_depart'] != null ? (json['prix_depart'] as num).toDouble() : null,
      numeroDepart: json['numero_depart'],
      isDirect: isDirect,
      trajet: json['trajet'] != null ? TrajetInfo.fromJson(json['trajet']) : null,
      bus: json['bus'] != null ? BusInfo.fromJson(json['bus']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_depart': dateDepart,
      'date_depart_formatted': dateDepartFormatted,
      'heure_depart': heureDepart,
      'prix_depart': prixDepart,
      'numero_depart': numeroDepart,
      'is_direct': isDirect,
      'trajet': trajet?.toJson(),
      'bus': bus?.toJson(),
    };
  }
}

class TrajetInfo {
  final int id;
  final String? nom;
  final String? embarquement;
  final String? destination;

  TrajetInfo({
    required this.id,
    this.nom,
    this.embarquement,
    this.destination,
  });

  factory TrajetInfo.fromJson(Map<String, dynamic> json) {
    return TrajetInfo(
      id: json['id'] ?? 0,
      nom: json['nom'],
      embarquement: json['embarquement'],
      destination: json['destination'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'embarquement': embarquement,
      'destination': destination,
    };
  }
}

class BusInfo {
  final int id;
  final String? registrationNumber;
  final int? seatCount;
  final String? status;

  BusInfo({
    required this.id,
    this.registrationNumber,
    this.seatCount,
    this.status,
  });

  factory BusInfo.fromJson(Map<String, dynamic> json) {
    return BusInfo(
      id: json['id'] ?? 0,
      registrationNumber: json['registration_number'],
      seatCount: json['seat_count'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registration_number': registrationNumber,
      'seat_count': seatCount,
      'status': status,
    };
  }
}

class StopInfo {
  final int id;
  final String name;
  final int? orderIndex;
  final String? etaTime;

  StopInfo({
    required this.id,
    required this.name,
    this.orderIndex,
    this.etaTime,
  });

  factory StopInfo.fromJson(Map<String, dynamic> json) {
    return StopInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      orderIndex: json['order_index'],
      etaTime: json['eta_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order_index': orderIndex,
      'eta_time': etaTime,
    };
  }
}

// Réponse API pour les trajets
class TripsResponse {
  final bool success;
  final String message;
  final List<Trip> trips;
  final int count;

  TripsResponse({
    required this.success,
    required this.message,
    required this.trips,
    this.count = 0,
  });

  factory TripsResponse.fromJson(Map<String, dynamic> json) {
    return TripsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      trips: (json['trips'] as List<dynamic>? ?? [])
          .map((trip) => Trip.fromJson(trip as Map<String, dynamic>))
          .toList(),
      count: json['count'] ?? 0,
    );
  }
}

