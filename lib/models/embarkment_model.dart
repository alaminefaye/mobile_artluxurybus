class EmbarkmentDepart {
  final int id;
  final String? dateDepart;
  final String? dateDepartFormatted;
  final String? heureDepart;
  final double? prix;
  final String? numeroDepart;
  final bool isDirect;
  final TrajetInfo? trajet;
  final BusInfo? bus;
  final int nombrePlaces;
  final int placesReservees;
  final int placesDisponibles;
  final int ticketsScannes;
  final bool isReadyForEmbarkment; // Si c'est l'heure d'embarquer

  EmbarkmentDepart({
    required this.id,
    this.dateDepart,
    this.dateDepartFormatted,
    this.heureDepart,
    this.prix,
    this.numeroDepart,
    this.isDirect = false,
    this.trajet,
    this.bus,
    required this.nombrePlaces,
    required this.placesReservees,
    required this.placesDisponibles,
    required this.ticketsScannes,
    this.isReadyForEmbarkment = false,
  });

  factory EmbarkmentDepart.fromJson(Map<String, dynamic> json) {
    // Gérer is_direct qui peut être int (0/1) ou bool
    bool isDirect = false;
    if (json['is_direct'] != null) {
      if (json['is_direct'] is bool) {
        isDirect = json['is_direct'] as bool;
      } else if (json['is_direct'] is int) {
        isDirect = (json['is_direct'] as int) == 1;
      } else {
        isDirect = json['is_direct'].toString() == '1' ||
            json['is_direct'].toString().toLowerCase() == 'true';
      }
    }

    return EmbarkmentDepart(
      id: json['id'] ?? 0,
      dateDepart: json['date_depart'],
      dateDepartFormatted: json['date_depart_formatted'],
      heureDepart: json['heure_depart'],
      prix: json['prix'] != null ? (json['prix'] as num).toDouble() : null,
      numeroDepart: json['numero_depart'],
      isDirect: isDirect,
      trajet: json['trajet'] != null
          ? TrajetInfo.fromJson(json['trajet'])
          : null,
      bus: json['bus'] != null ? BusInfo.fromJson(json['bus']) : null,
      nombrePlaces: json['nombre_places'] ?? json['places_total'] ?? 0,
      placesReservees: json['places_reservees'] ?? json['reservations_count'] ?? 0,
      placesDisponibles: json['places_disponibles'] ?? 0,
      ticketsScannes: json['tickets_scannes'] ?? json['scanned_count'] ?? 0,
      isReadyForEmbarkment: json['is_ready_for_embarkment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_depart': dateDepart,
      'date_depart_formatted': dateDepartFormatted,
      'heure_depart': heureDepart,
      'prix': prix,
      'numero_depart': numeroDepart,
      'is_direct': isDirect,
      'trajet': trajet?.toJson(),
      'bus': bus?.toJson(),
      'nombre_places': nombrePlaces,
      'places_reservees': placesReservees,
      'places_disponibles': placesDisponibles,
      'tickets_scannes': ticketsScannes,
      'is_ready_for_embarkment': isReadyForEmbarkment,
    };
  }

  String get routeText {
    if (trajet != null) {
      return '${trajet!.embarquement} → ${trajet!.destination}';
    }
    return 'Trajet non spécifié';
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
      registrationNumber: json['registration_number'] ??
          json['numero'] ??
          json['numero_bus'],
      seatCount: json['seat_count'] ?? json['nombre_places'],
      status: json['status'] ?? json['statut'],
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

class ScannedTicket {
  final int id;
  final String nomComplet;
  final String telephone;
  final int? siegeNumber;
  final String scannedAt;
  final String? scannedAtFormatted;
  final bool isUsed;

  ScannedTicket({
    required this.id,
    required this.nomComplet,
    required this.telephone,
    this.siegeNumber,
    required this.scannedAt,
    this.scannedAtFormatted,
    this.isUsed = true,
  });

  factory ScannedTicket.fromJson(Map<String, dynamic> json) {
    bool isUsed = true;
    if (json['is_used'] != null) {
      if (json['is_used'] is bool) {
        isUsed = json['is_used'] as bool;
      } else if (json['is_used'] is int) {
        isUsed = (json['is_used'] as int) == 1;
      } else {
        isUsed = json['is_used'].toString() == '1' ||
            json['is_used'].toString().toLowerCase() == 'true';
      }
    }

    return ScannedTicket(
      id: json['id'] ?? 0,
      nomComplet: json['nom_complet'] ?? json['nom'] ?? '',
      telephone: json['telephone'] ?? json['phone'] ?? '',
      siegeNumber: json['siege_number'] ?? json['siege'],
      scannedAt: json['scanned_at'] ?? json['used_at'] ?? '',
      scannedAtFormatted: json['scanned_at_formatted'] ?? json['used_at_formatted'],
      isUsed: isUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_complet': nomComplet,
      'telephone': telephone,
      'siege_number': siegeNumber,
      'scanned_at': scannedAt,
      'scanned_at_formatted': scannedAtFormatted,
      'is_used': isUsed,
    };
  }
}

