/// Modèles pour les statistiques du dashboard administrateur
library;

/// Helper pour parser les doubles (gère String et num)
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

class DashboardStats {
  final String date;
  final String dateFormatted;
  final double totalDailyRevenue;
  final TicketStats tickets;
  final DepartStats departs;
  final FuelStats fuel;
  final MailStats mails;
  final BagageStats bagages;
  final EmployeeStats employees;
  final ReservationStats reservations;
  final ClientStats clients;
  final BusStats buses;

  DashboardStats({
    required this.date,
    required this.dateFormatted,
    required this.totalDailyRevenue,
    required this.tickets,
    required this.departs,
    required this.fuel,
    required this.mails,
    required this.bagages,
    required this.employees,
    required this.reservations,
    required this.clients,
    required this.buses,
  });

  // Getters pour faciliter l'accès
  int get ticketsCount => tickets.count;
  int get departsCount => departs.count;
  int get mailsCount => mails.count;
  int get bagagesCount => bagages.count;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    return DashboardStats(
      date: data['date'] ?? '',
      dateFormatted: data['date_formatted'] ?? '',
      totalDailyRevenue: _parseDouble(data['total_daily_revenue']),
      tickets: TicketStats.fromJson(data['tickets'] ?? {}),
      departs: DepartStats.fromJson(data['departs'] ?? {}),
      fuel: FuelStats.fromJson(data['fuel'] ?? {}),
      mails: MailStats.fromJson(data['mails'] ?? {}),
      bagages: BagageStats.fromJson(data['bagages'] ?? {}),
      employees: EmployeeStats.fromJson(data['employees'] ?? {}),
      reservations: ReservationStats.fromJson(data['reservations'] ?? {}),
      clients: ClientStats.fromJson(data['clients'] ?? {}),
      buses: BusStats.fromJson(data['buses'] ?? {}),
    );
  }
}

class TicketStats {
  final int count;
  final int paidCount;
  final int freeCount;
  final int loyaltyCount;
  final int promoCodeCount;
  final double totalRevenue;

  TicketStats({
    required this.count,
    required this.paidCount,
    required this.freeCount,
    required this.loyaltyCount,
    required this.promoCodeCount,
    required this.totalRevenue,
  });

  factory TicketStats.fromJson(Map<String, dynamic> json) {
    return TicketStats(
      count: json['count'] ?? 0,
      paidCount: json['paid_count'] ?? 0,
      freeCount: json['free_count'] ?? 0,
      loyaltyCount: json['loyalty_count'] ?? 0,
      promoCodeCount: json['promo_code_count'] ?? 0,
      totalRevenue: _parseDouble(json['total_revenue']),
    );
  }
}

class DepartStats {
  final int count;
  final int totalTickets;
  final double totalRevenue;

  DepartStats({
    required this.count,
    required this.totalTickets,
    required this.totalRevenue,
  });

  factory DepartStats.fromJson(Map<String, dynamic> json) {
    return DepartStats(
      count: json['count'] ?? 0,
      totalTickets: json['total_tickets'] ?? 0,
      totalRevenue: _parseDouble(json['total_revenue']),
    );
  }
}

class FuelStats {
  final double totalCost;
  final int recordsCount;
  final double averageCostPerRecord;

  FuelStats({
    required this.totalCost,
    required this.recordsCount,
    required this.averageCostPerRecord,
  });

  factory FuelStats.fromJson(Map<String, dynamic> json) {
    return FuelStats(
      totalCost: _parseDouble(json['total_cost']),
      recordsCount: json['records_count'] ?? 0,
      averageCostPerRecord: _parseDouble(json['average_cost_per_record']),
    );
  }
}

class MailStats {
  final int count;
  final int loyaltyCount;
  final int paidCount;
  final double totalRevenue;
  final int collectedCount;
  final int pendingCount;

  MailStats({
    required this.count,
    required this.loyaltyCount,
    required this.paidCount,
    required this.totalRevenue,
    required this.collectedCount,
    required this.pendingCount,
  });

  factory MailStats.fromJson(Map<String, dynamic> json) {
    return MailStats(
      count: json['count'] ?? 0,
      loyaltyCount: json['loyalty_count'] ?? 0,
      paidCount: json['paid_count'] ?? 0,
      totalRevenue: _parseDouble(json['total_revenue']),
      collectedCount: json['collected_count'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
    );
  }
}

class BagageStats {
  final int count;
  final double totalRevenue;

  BagageStats({
    required this.count,
    required this.totalRevenue,
  });

  factory BagageStats.fromJson(Map<String, dynamic> json) {
    return BagageStats(
      count: json['count'] ?? 0,
      totalRevenue: _parseDouble(json['total_revenue']),
    );
  }
}

class EmployeeStats {
  final int totalActive;
  final int presentCount;
  final int inProgressCount;
  final int departedCount;
  final int absentCount;

  EmployeeStats({
    required this.totalActive,
    required this.presentCount,
    required this.inProgressCount,
    required this.departedCount,
    required this.absentCount,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      totalActive: json['total_active'] ?? 0,
      presentCount: json['present_count'] ?? 0,
      inProgressCount: json['in_progress_count'] ?? 0,
      departedCount: json['departed_count'] ?? 0,
      absentCount: json['absent_count'] ?? 0,
    );
  }
}

class ReservationStats {
  final int ticketsCount;
  final double waveAmount;
  final double balanceAmount;
  final double totalAmount;

  ReservationStats({
    required this.ticketsCount,
    required this.waveAmount,
    required this.balanceAmount,
    required this.totalAmount,
  });

  factory ReservationStats.fromJson(Map<String, dynamic> json) {
    return ReservationStats(
      ticketsCount: json['tickets_count'] ?? 0,
      waveAmount: _parseDouble(json['wave_amount']),
      balanceAmount: _parseDouble(json['balance_amount']),
      totalAmount: _parseDouble(json['total_amount']),
    );
  }
}

class ClientStats {
  final int total;
  final int newToday;
  final int withAccounts;

  ClientStats({
    required this.total,
    required this.newToday,
    required this.withAccounts,
  });

  factory ClientStats.fromJson(Map<String, dynamic> json) {
    return ClientStats(
      total: json['total'] ?? 0,
      newToday: json['new_today'] ?? 0,
      withAccounts: json['with_accounts'] ?? 0,
    );
  }
}

class BusStats {
  final int total;
  final int active;
  final int inMaintenance;
  final int outOfService;

  BusStats({
    required this.total,
    required this.active,
    required this.inMaintenance,
    required this.outOfService,
  });

  factory BusStats.fromJson(Map<String, dynamic> json) {
    return BusStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      inMaintenance: json['in_maintenance'] ?? 0,
      outOfService: json['out_of_service'] ?? 0,
    );
  }
}
