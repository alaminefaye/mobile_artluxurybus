class BagageModel {
  final int id;
  final String numero;
  final String? ticketNumber;
  final String nom;
  final String prenom;
  final String telephone;
  final String destination;
  final double? valeur;
  final double? poids;
  final double? montant;
  final String? contenu;
  final bool hasTicket;
  final DateTime createdAt;
  final DateTime updatedAt;

  BagageModel({
    required this.id,
    required this.numero,
    this.ticketNumber,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.destination,
    this.valeur,
    this.poids,
    this.montant,
    this.contenu,
    required this.hasTicket,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BagageModel.fromJson(Map<String, dynamic> json) {
    return BagageModel(
      id: json['id'] ?? 0,
      numero: json['numero'] ?? '',
      ticketNumber: json['ticket_number'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'] ?? '',
      destination: json['destination'] ?? '',
      valeur: json['valeur'] != null ? double.tryParse(json['valeur'].toString()) : null,
      poids: json['poids'] != null ? double.tryParse(json['poids'].toString()) : null,
      montant: json['montant'] != null ? double.tryParse(json['montant'].toString()) : null,
      contenu: json['contenu'],
      hasTicket: json['has_ticket'] == true || json['has_ticket'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'ticket_number': ticketNumber,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'destination': destination,
      'valeur': valeur,
      'poids': poids,
      'montant': montant,
      'contenu': contenu,
      'has_ticket': hasTicket,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get nomComplet => '$nom $prenom';

  BagageModel copyWith({
    int? id,
    String? numero,
    String? ticketNumber,
    String? nom,
    String? prenom,
    String? telephone,
    String? destination,
    double? valeur,
    double? poids,
    double? montant,
    String? contenu,
    bool? hasTicket,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BagageModel(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      destination: destination ?? this.destination,
      valeur: valeur ?? this.valeur,
      poids: poids ?? this.poids,
      montant: montant ?? this.montant,
      contenu: contenu ?? this.contenu,
      hasTicket: hasTicket ?? this.hasTicket,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BagageStats {
  final int total;
  final int withTicket;
  final int withoutTicket;
  final int today;
  final int thisWeek;
  final int thisMonth;
  final double totalWeight;
  final double totalValue;
  final double totalRevenue;

  BagageStats({
    required this.total,
    required this.withTicket,
    required this.withoutTicket,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.totalWeight,
    required this.totalValue,
    required this.totalRevenue,
  });

  factory BagageStats.fromJson(Map<String, dynamic> json) {
    return BagageStats(
      total: json['total'] ?? 0,
      withTicket: json['with_ticket'] ?? 0,
      withoutTicket: json['without_ticket'] ?? 0,
      today: json['today'] ?? 0,
      thisWeek: json['this_week'] ?? 0,
      thisMonth: json['this_month'] ?? 0,
      totalWeight: double.tryParse(json['total_weight'].toString()) ?? 0.0,
      totalValue: double.tryParse(json['total_value'].toString()) ?? 0.0,
      totalRevenue: double.tryParse(json['total_revenue'].toString()) ?? 0.0,
    );
  }
}

class BagageDashboard {
  final DashboardPeriod today;
  final DashboardPeriod week;
  final DashboardPeriod month;
  final List<BagageModel> recentBagages;
  final List<DestinationStat> topDestinations;

  BagageDashboard({
    required this.today,
    required this.week,
    required this.month,
    required this.recentBagages,
    required this.topDestinations,
  });

  factory BagageDashboard.fromJson(Map<String, dynamic> json) {
    return BagageDashboard(
      today: DashboardPeriod.fromJson(json['today'] ?? {}),
      week: DashboardPeriod.fromJson(json['week'] ?? {}),
      month: DashboardPeriod.fromJson(json['month'] ?? {}),
      recentBagages: (json['recent_bagages'] as List?)
              ?.map((e) => BagageModel.fromJson(e))
              .toList() ??
          [],
      topDestinations: (json['top_destinations'] as List?)
              ?.map((e) => DestinationStat.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DashboardPeriod {
  final int total;
  final int withTicket;
  final int withoutTicket;
  final double revenue;
  final double weight;

  DashboardPeriod({
    required this.total,
    required this.withTicket,
    required this.withoutTicket,
    required this.revenue,
    required this.weight,
  });

  factory DashboardPeriod.fromJson(Map<String, dynamic> json) {
    return DashboardPeriod(
      total: json['total'] ?? 0,
      withTicket: json['with_ticket'] ?? 0,
      withoutTicket: json['without_ticket'] ?? 0,
      revenue: double.tryParse(json['revenue'].toString()) ?? 0.0,
      weight: double.tryParse(json['weight'].toString()) ?? 0.0,
    );
  }
}

class DestinationStat {
  final String destination;
  final int count;

  DestinationStat({
    required this.destination,
    required this.count,
  });

  factory DestinationStat.fromJson(Map<String, dynamic> json) {
    return DestinationStat(
      destination: json['destination'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

