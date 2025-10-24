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
  final String maintenanceType;
  
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
    required this.maintenanceType,
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
  
  @JsonKey(name: 'expiry_date')
  final DateTime expiryDate;
  
  @JsonKey(name: 'visit_center')
  final String? visitCenter;
  
  @JsonKey(name: 'result')
  final String result;
  
  final double? cost;
  final String? notes;
  
  @JsonKey(name: 'certificate_number')
  final String? certificateNumber;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  TechnicalVisit({
    required this.id,
    required this.busId,
    required this.visitDate,
    required this.expiryDate,
    this.visitCenter,
    required this.result,
    this.cost,
    this.notes,
    this.certificateNumber,
    this.createdAt,
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
  
  @JsonKey(name: 'insurance_company')
  final String insuranceCompany;
  
  @JsonKey(name: 'policy_number')
  final String policyNumber;
  
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  
  @JsonKey(name: 'expiry_date')
  final DateTime expiryDate;
  
  @JsonKey(name: 'coverage_type')
  final String coverageType;
  
  final double premium;
  final String? notes;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  InsuranceRecord({
    required this.id,
    required this.busId,
    required this.insuranceCompany,
    required this.policyNumber,
    required this.startDate,
    required this.expiryDate,
    required this.coverageType,
    required this.premium,
    this.notes,
    this.createdAt,
  });

  factory InsuranceRecord.fromJson(Map<String, dynamic> json) =>
      _$InsuranceRecordFromJson(json);
  
  Map<String, dynamic> toJson() => _$InsuranceRecordToJson(this);
}

// ===== Patent =====
@JsonSerializable()
class Patent {
  final int id;
  
  @JsonKey(name: 'bus_id')
  final int busId;
  
  @JsonKey(name: 'patent_number')
  final String patentNumber;
  
  @JsonKey(name: 'issue_date')
  final DateTime issueDate;
  
  @JsonKey(name: 'expiry_date')
  final DateTime expiryDate;
  
  @JsonKey(name: 'issuing_authority')
  final String? issuingAuthority;
  
  final double? cost;
  final String? notes;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Patent({
    required this.id,
    required this.busId,
    required this.patentNumber,
    required this.issueDate,
    required this.expiryDate,
    this.issuingAuthority,
    this.cost,
    this.notes,
    this.createdAt,
  });

  factory Patent.fromJson(Map<String, dynamic> json) =>
      _$PatentFromJson(json);
  
  Map<String, dynamic> toJson() => _$PatentToJson(this);
}

// ===== Bus Breakdown =====
@JsonSerializable()
class BusBreakdown {
  final int id;
  
  @JsonKey(name: 'bus_id')
  final int busId;
  
  final String description;
  
  @JsonKey(name: 'breakdown_date')
  final DateTime breakdownDate;
  
  final String severity; // low, medium, high
  final String status; // reported, in_progress, resolved
  
  @JsonKey(name: 'repair_cost')
  final double? repairCost;
  
  @JsonKey(name: 'resolved_date')
  final DateTime? resolvedDate;
  
  final String? notes;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  // Relation optionnelle
  final Bus? bus;

  BusBreakdown({
    required this.id,
    required this.busId,
    required this.description,
    required this.breakdownDate,
    required this.severity,
    required this.status,
    this.repairCost,
    this.resolvedDate,
    this.notes,
    this.createdAt,
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
  
  @JsonKey(name: 'vidange_date')
  final DateTime? vidangeDate;
  
  @JsonKey(name: 'next_vidange_date')
  final DateTime? nextVidangeDate;
  
  @JsonKey(name: 'planned_date')
  final DateTime? plannedDate;
  
  final String type;
  final double? cost;
  
  @JsonKey(name: 'service_provider')
  final String? serviceProvider;
  
  final double? mileage;
  final String? notes;
  
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  
  @JsonKey(name: 'completion_notes')
  final String? completionNotes;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  BusVidange({
    required this.id,
    required this.busId,
    this.vidangeDate,
    this.nextVidangeDate,
    this.plannedDate,
    required this.type,
    this.cost,
    this.serviceProvider,
    this.mileage,
    this.notes,
    this.completedAt,
    this.completionNotes,
    this.createdAt,
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
