class Horaire {
  final int id;
  final Gare gare;
  final Trajet trajet;
  final Bus? bus;
  final String heure;
  final String statut; // a_l_heure, embarquement, termine
  final String statutLibelle;
  final String? date;
  final bool actif;

  Horaire({
    required this.id,
    required this.gare,
    required this.trajet,
    this.bus,
    required this.heure,
    required this.statut,
    required this.statutLibelle,
    this.date,
    required this.actif,
  });

  factory Horaire.fromJson(Map<String, dynamic> json) {
    return Horaire(
      id: json['id'],
      gare: Gare.fromJson(json['gare']),
      trajet: Trajet.fromJson(json['trajet']),
      bus: json['bus'] != null ? Bus.fromJson(json['bus']) : null,
      heure: json['heure'],
      statut: json['statut'],
      statutLibelle: json['statut_libelle'],
      date: json['date'],
      actif: json['actif'] ?? true,
    );
  }

  // Getter pour savoir si l'horaire est aujourd'hui
  bool get isToday {
    if (date == null) return true; // Horaire récurrent
    final today = DateTime.now();
    final horaireDate = DateTime.parse(date!);
    return horaireDate.year == today.year &&
        horaireDate.month == today.month &&
        horaireDate.day == today.day;
  }

  // Getter pour la couleur du badge selon le statut
  String get statusColor {
    switch (statut) {
      case 'a_l_heure':
        return 'blue'; // À l'heure
      case 'embarquement':
        return 'green'; // Embarquement
      case 'termine':
        return 'red'; // Terminé
      default:
        return 'grey';
    }
  }
}

class Gare {
  final int id;
  final String nom;
  final String? appareil;

  Gare({
    required this.id,
    required this.nom,
    this.appareil,
  });

  factory Gare.fromJson(Map<String, dynamic> json) {
    return Gare(
      id: json['id'],
      nom: json['nom'],
      appareil: json['appareil'],
    );
  }
}

class Trajet {
  final int id;
  final String embarquement;
  final String destination;
  final double prix;

  Trajet({
    required this.id,
    required this.embarquement,
    required this.destination,
    required this.prix,
  });

  factory Trajet.fromJson(Map<String, dynamic> json) {
    return Trajet(
      id: json['id'],
      embarquement: json['embarquement'],
      destination: json['destination'],
      prix: (json['prix'] as num).toDouble(),
    );
  }
}

class Bus {
  final int id;
  final String registrationNumber;
  final int seatCount;

  Bus({
    required this.id,
    required this.registrationNumber,
    required this.seatCount,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'],
      registrationNumber: json['registration_number'],
      seatCount: json['seat_count'],
    );
  }
}
