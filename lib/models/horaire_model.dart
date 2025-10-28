class Horaire {
  final int id;
  final Gare gare;
  final Trajet trajet;
  final String? busNumber; // Numéro du bus (peut être string ou objet)
  final String heure;
  final String statut; // a_l_heure, embarquement, termine  
  final String statutLibelle;
  final String? date;
  final bool actif;

  Horaire({
    required this.id,
    required this.gare,
    required this.trajet,
    this.busNumber,
    required this.heure,
    required this.statut,
    required this.statutLibelle,
    this.date,
    required this.actif,
  });

  factory Horaire.fromJson(Map<String, dynamic> json) {
    // Gérer le bus qui peut être un string ou un objet
    String? busNum;
    if (json['bus'] != null) {
      if (json['bus'] is String) {
        busNum = json['bus'];
      } else if (json['bus'] is Map) {
        busNum = json['bus']['registration_number'];
      }
    }

    // Gérer le statut qui peut être un code (a_l_heure) ou un libellé (À l'heure)
    String statutCode;
    String statutLib;
    
    if (json['statut_libelle'] != null) {
      // L'API retourne déjà les deux
      statutCode = json['statut'];
      statutLib = json['statut_libelle'];
    } else {
      // L'API retourne seulement statut, déterminer si c'est un code ou un libellé
      final statutValue = json['statut'];
      if (statutValue == 'a_l_heure' || statutValue == 'embarquement' || statutValue == 'termine') {
        // C'est un code
        statutCode = statutValue;
        statutLib = _getStatutLibelle(statutValue);
      } else {
        // C'est un libellé, inverser pour obtenir le code
        statutLib = statutValue;
        statutCode = _getStatutCode(statutValue);
      }
    }

    return Horaire(
      id: json['id'],
      gare: Gare.fromJson(json['gare']),
      trajet: Trajet.fromJson(json['trajet']),
      busNumber: busNum,
      heure: json['heure'],
      statut: statutCode,
      statutLibelle: statutLib,
      date: json['date'],
      actif: json['actif'] ?? true,
    );
  }

  // Helper pour convertir le statut en libellé
  static String _getStatutLibelle(String statut) {
    switch (statut) {
      case 'a_l_heure':
        return 'À l\'heure';
      case 'embarquement':
        return 'Embarquement';
      case 'termine':
        return 'Terminé';
      default:
        return statut;
    }
  }

  // Helper pour convertir le libellé en code statut
  static String _getStatutCode(String libelle) {
    switch (libelle) {
      case 'À l\'heure':
        return 'a_l_heure';
      case 'Embarquement':
        return 'embarquement';
      case 'Terminé':
        return 'termine';
      default:
        return libelle.toLowerCase().replaceAll(' ', '_');
    }
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
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gare && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Trajet {
  final int? id;
  final String embarquement;
  final String destination;
  final double prix;

  Trajet({
    this.id,
    required this.embarquement,
    required this.destination,
    required this.prix,
  });

  factory Trajet.fromJson(Map<String, dynamic> json) {
    return Trajet(
      id: json['id'],
      embarquement: json['embarquement'],
      destination: json['destination'],
      prix: double.parse(json['prix'].toString()),
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trajet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
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
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bus && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
