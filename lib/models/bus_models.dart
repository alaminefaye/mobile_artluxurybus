import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bus_models.g.dart';

// ===== Dashboard Stats =====
@JsonSerializable()
class BusDashboardStats {
  @JsonKey(name: 'total_buses')
  final int totalBuses;
  
  @JsonKey(name: 'active_buses')
  final int activeBuses;
  
  @JsonKey(name: 'maintenance_needed')
  final int maintenanceNeeded;
  
  @JsonKey(name: 'insurance_expiring')
  final int insuranceExpiring;
  
  @JsonKey(name: 'technical_visit_expiring')
  final int technicalVisitExpiring;
  
  @JsonKey(name: 'vidange_needed')
  final int vidangeNeeded;

  BusDashboardStats({
    required this.totalBuses,
    required this.activeBuses,
    required this.maintenanceNeeded,
    required this.insuranceExpiring,
    required this.technicalVisitExpiring,
    required this.vidangeNeeded,
  });

  factory BusDashboardStats.fromJson(Map<String, dynamic> json) =>
      _$BusDashboardStatsFromJson(json);
  
  Map<String, dynamic> toJson() => _$BusDashboardStatsToJson(this);
}

@JsonSerializable()
class BusDashboard {
  final BusDashboardStats stats;
  
  @JsonKey(name: 'recent_breakdowns')
  final List<BusBreakdown> recentBreakdowns;

  BusDashboard({
    required this.stats,
    required this.recentBreakdowns,
  });

  factory BusDashboard.fromJson(Map<String, dynamic> json) =>
      _$BusDashboardFromJson(json);
  
  Map<String, dynamic> toJson() => _$BusDashboardToJson(this);
}

// ===== Bus Model =====
@JsonSerializable()
class Bus {
  final int id;
  
  @JsonKey(name: 'registration_number')
  final String? registrationNumber;
  
  final String? brand;
  final String? model;
  final int? year;
  
  @JsonKey(name: 'seat_count')
  final int? capacity;
  
  final String? status;
  
  @JsonKey(name: 'current_mileage')
  final double? currentMileage;
  
  @JsonKey(name: 'chassis_number')
  final String? chassisNumber;
  
  @JsonKey(name: 'engine_number')
  final String? engineNumber;
  
  final String? color;
  final String? notes;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  
  // Relations optionnelles
  @JsonKey(name: 'maintenance_records')
  final List<MaintenanceRecord>? maintenanceRecords;
  
  @JsonKey(name: 'fuel_records')
  final List<FuelRecord>? fuelRecords;
  
  @JsonKey(name: 'technical_visits')
  final List<TechnicalVisit>? technicalVisits;
  
  @JsonKey(name: 'insurance_records')
  final List<InsuranceRecord>? insuranceRecords;
  
  final List<Patent>? patents;
  final List<BusBreakdown>? breakdowns;
  final List<BusVidange>? vidanges;

  Bus({
    required this.id,
    this.registrationNumber,
    this.brand,
    this.model,
    this.year,
    this.capacity,
    this.status,
    this.currentMileage,
    this.chassisNumber,
    this.engineNumber,
    this.color,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.maintenanceRecords,
    this.fuelRecords,
    this.technicalVisits,
    this.insuranceRecords,
    this.patents,
    this.breakdowns,
    this.vidanges,
  });

  factory Bus.fromJson(Map<String, dynamic> json) => _$BusFromJson(json);
  
  Map<String, dynamic> toJson() => _$BusToJson(this);
}

// ===== Maintenance Record =====
@JsonSerializable()
class MaintenanceRecord {
  final int id;
  
  @JsonKey(name: 'bus_id')
  final int busId;
  
  @JsonKey(name: 'maintenance_type')
  final String? maintenanceType;
  
  @JsonKey(name: 'maintenance_date')
  final DateTime maintenanceDate;
  
  @JsonKey(name: 'next_maintenance_date')
  final DateTime? nextMaintenanceDate;
  
  final String? description;
  final double? cost;
  
  @JsonKey(name: 'service_provider')
  final String? serviceProvider;
  
  final double? mileage;
  final String? notes;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  MaintenanceRecord({
    required this.id,
    required this.busId,
    this.maintenanceType,
    required this.maintenanceDate,
    this.nextMaintenanceDate,
    this.description,
    this.cost,
    this.serviceProvider,
    this.mileage,
    this.notes,
    this.createdAt,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceRecordFromJson(json);
  
  Map<String, dynamic> toJson() => _$MaintenanceRecordToJson(this);
}

// ===== Fuel Record =====
@JsonSerializable()
class FuelRecord {
  @JsonKey(fromJson: _intFromJson)
  final int id;
  
  @JsonKey(name: 'bus_id', fromJson: _intFromJson)
  final int busId;
  
  final DateTime date;
  
  @JsonKey(fromJson: _costFromJson)
  final double cost;
  
  @JsonKey(name: 'invoice_photo')
  final String? invoicePhoto;
  
  final String? notes;
  
  @JsonKey(name: 'fueled_at')
  final DateTime fueledAt;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  FuelRecord({
    required this.id,
    required this.busId,
    required this.date,
    required this.cost,
    this.invoicePhoto,
    this.notes,
    required this.fueledAt,
    this.createdAt,
  });
  
  // Convertir String ou num en int
  static int _intFromJson(dynamic value) {
    if (value is String) {
      return int.parse(value);
    }
    return (value as num).toInt();
  }
  
  // Convertir String ou num en double
  static double _costFromJson(dynamic value) {
    if (value is String) {
      return double.parse(value);
    }
    return (value as num).toDouble();
  }

  factory FuelRecord.fromJson(Map<String, dynamic> json) =>
      _$FuelRecordFromJson(json);
  
  Map<String, dynamic> toJson() => _$FuelRecordToJson(this);
}

// ===== Fuel Stats =====
@JsonSerializable()
class FuelStats {
  @JsonKey(name: 'total_cost', fromJson: _doubleFromJson)
  final double totalConsumption;
  
  @JsonKey(name: 'average_cost', fromJson: _nullableDoubleFromJson)
  final double? averageConsumption;
  
  @JsonKey(name: 'last_month_cost', fromJson: _doubleFromJson)
  final double lastMonthConsumption;
  
  @JsonKey(name: 'last_refill')
  final FuelRecord? lastRefill;

  FuelStats({
    required this.totalConsumption,
    this.averageConsumption,
    required this.lastMonthConsumption,
    this.lastRefill,
  });
  
  // Convertir String ou num en double
  static double _doubleFromJson(dynamic value) {
    if (value is String) {
      return double.parse(value);
    }
    return (value as num).toDouble();
  }
  
  // Version nullable
  static double? _nullableDoubleFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return double.parse(value);
    }
    return (value as num).toDouble();
  }

  factory FuelStats.fromJson(Map<String, dynamic> json) =>
      _$FuelStatsFromJson(json);
  
  Map<String, dynamic> toJson() => _$FuelStatsToJson(this);
}

// ===== Technical Visit =====
@JsonSerializable()
class TechnicalVisit {
  final int id;
  
  @JsonKey(name: 'bus_id')
  final int busId;
  
  @JsonKey(name: 'visit_date')
  final DateTime visitDate;
  
  @JsonKey(name: 'expiration_date')
  final DateTime expirationDate;
  
  @JsonKey(name: 'document_photo')
  final String? documentPhoto;
  
  final String? notes;
  
  @JsonKey(name: 'is_notified')
  final bool isNotified;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  TechnicalVisit({
    required this.id,
    required this.busId,
    required this.visitDate,
    required this.expirationDate,
    this.documentPhoto,
    this.notes,
    required this.isNotified,
    this.createdAt,
    this.updatedAt,
  });

  factory TechnicalVisit.fromJson(Map<String, dynamic> json) =>
      _$TechnicalVisitFromJson(json);
  
  Map<String, dynamic> toJson() => _$TechnicalVisitToJson(this);
}

// ===== Insurance Record =====
@JsonSerializable()
class InsuranceRecord {
  final int id;
  
  @JsonKey(name: 'bus_id')
  final int busId;
  
  @JsonKey(name: 'policy_number')
  final String policyNumber;
  
  @JsonKey(name: 'insurance_company')
  final String insuranceCompany;
  
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  
  @JsonKey(name: 'end_date')
  final DateTime expiryDate;
  
  final double cost;
  
  @JsonKey(name: 'document_photo')
  final String? documentPhoto;
  
  final String? notes;
  
  @JsonKey(name: 'is_notified')
  final bool isNotified;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  InsuranceRecord({
    required this.id,
    required this.busId,
    required this.policyNumber,
    required this.insuranceCompany,
    required this.startDate,
    required this.expiryDate,
    required this.cost,
    this.documentPhoto,
    this.notes,
    required this.isNotified,
    this.createdAt,
    this.updatedAt,
  });

  factory InsuranceRecord.fromJson(Map<String, dynamic> json) =>
      _$InsuranceRecordFromJson(json);
  
  Map<String, dynamic> toJson() => _$InsuranceRecordToJson(this);
}

// Convertisseurs globaux pour Patent
int _intFromJson(dynamic value) {
  if (value is int) {
    return value;
  } else if (value is String) {
    return int.parse(value);
  } else if (value is num) {
    return value.toInt();
  }
  return 0;
}

double _costFromJsonGlobal(dynamic value) {
  if (value is num) {
    return value.toDouble();
  } else if (value is String) {
    return double.parse(value);
  }
  return 0.0;
}

// ===== Patent =====
@JsonSerializable()
class Patent {
  @JsonKey(fromJson: _intFromJson)
  final int id;
  
  @JsonKey(name: 'bus_id', fromJson: _intFromJson)
  final int busId;
  
  @JsonKey(name: 'patent_number')
  final String patentNumber;
  
  @JsonKey(name: 'issue_date')
  final DateTime issueDate;
  
  @JsonKey(name: 'expiry_date')
  final DateTime expiryDate;
  
  @JsonKey(fromJson: _costFromJsonGlobal)
  final double cost;
  final String? notes;
  
  @JsonKey(name: 'document_path')
  final String? documentPath;
  
  @JsonKey(name: 'document_url')
  final String? documentUrl;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Patent({
    required this.id,
    required this.busId,
    required this.patentNumber,
    required this.issueDate,
    required this.expiryDate,
    required this.cost,
    this.notes,
    this.documentPath,
    this.documentUrl,
    this.createdAt,
  });

  factory Patent.fromJson(Map<String, dynamic> json) =>
      _$PatentFromJson(json);
  
  Map<String, dynamic> toJson() => _$PatentToJson(this);

  // Calculer les jours restants avant expiration
  int get daysUntilExpiration {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    return difference.inDays;
  }

  // Vérifier si expiré
  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }

  // Vérifier si expire bientôt (30 jours)
  bool get isExpiringSoon {
    return daysUntilExpiration <= 30 && !isExpired;
  }

  // Obtenir le statut
  String get status {
    if (isExpired) return 'Expiré';
    if (isExpiringSoon) return 'Expire bientôt';
    return 'Valide';
  }

  // Obtenir la couleur du statut
  Color get statusColor {
    if (isExpired) return Colors.red;
    if (isExpiringSoon) return Colors.orange;
    return Colors.green;
  }

}

// ===== Bus Breakdown =====
@JsonSerializable()
class BusBreakdown {
  final int id;
  
  @JsonKey(name: 'bus_id')
  final int busId;
  
  final int? kilometrage;
  
  @JsonKey(name: 'reparation_effectuee')
  final String reparationEffectuee;
  
  @JsonKey(name: 'date_panne')
  final DateTime breakdownDate;
  
  @JsonKey(name: 'description_probleme')
  final String descriptionProbleme;
  
  @JsonKey(name: 'diagnostic_mecanicien')
  final String diagnosticMecanicien;
  
  @JsonKey(name: 'piece_remplacee')
  final String? pieceRemplacee;
  
  @JsonKey(name: 'prix_piece')
  final double? prixPiece;
  
  @JsonKey(name: 'facture_photo')
  final String? facturePhoto;
  
  @JsonKey(name: 'notes_complementaires')
  final String? notesComplementaires;
  
  @JsonKey(name: 'statut_reparation')
  final String statutReparation; // en_cours, terminee, en_attente_pieces
  
  @JsonKey(name: 'created_by')
  final int createdBy;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  
  // Relation optionnelle
  final Bus? bus;

  BusBreakdown({
    required this.id,
    required this.busId,
    this.kilometrage,
    required this.reparationEffectuee,
    required this.breakdownDate,
    required this.descriptionProbleme,
    required this.diagnosticMecanicien,
    this.pieceRemplacee,
    this.prixPiece,
    this.facturePhoto,
    this.notesComplementaires,
    required this.statutReparation,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.bus,
  });

  factory BusBreakdown.fromJson(Map<String, dynamic> json) =>
      _$BusBreakdownFromJson(json);
  
  Map<String, dynamic> toJson() => _$BusBreakdownToJson(this);
}

// ===== Bus Vidange =====
@JsonSerializable()
class BusVidange {
  final int id;
  
  @JsonKey(name: 'bus_id')
  final int busId;
  
  @JsonKey(name: 'last_vidange_date')
  final DateTime lastVidangeDate;
  
  @JsonKey(name: 'next_vidange_date')
  final DateTime nextVidangeDate;
  
  final String? notes;
  
  @JsonKey(name: 'created_by')
  final int createdBy;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  BusVidange({
    required this.id,
    required this.busId,
    required this.lastVidangeDate,
    required this.nextVidangeDate,
    this.notes,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory BusVidange.fromJson(Map<String, dynamic> json) =>
      _$BusVidangeFromJson(json);
  
  Map<String, dynamic> toJson() => _$BusVidangeToJson(this);
}

// ===== Pagination Response =====
@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponse<T> {
  @JsonKey(name: 'current_page')
  final int currentPage;
  
  final List<T> data;
  
  @JsonKey(name: 'first_page_url')
  final String? firstPageUrl;
  
  @JsonKey(name: 'from')
  final int? from;
  
  @JsonKey(name: 'last_page')
  final int lastPage;
  
  @JsonKey(name: 'last_page_url')
  final String? lastPageUrl;
  
  @JsonKey(name: 'next_page_url')
  final String? nextPageUrl;
  
  final String path;
  
  @JsonKey(name: 'per_page')
  final int perPage;
  
  @JsonKey(name: 'prev_page_url')
  final String? prevPageUrl;
  
  final int? to;
  final int total;

  PaginatedResponse({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);
  
  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$PaginatedResponseToJson(this, toJsonT);
}
