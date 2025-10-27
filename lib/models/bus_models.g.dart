// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bus_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusDashboardStats _$BusDashboardStatsFromJson(Map<String, dynamic> json) =>
    BusDashboardStats(
      totalBuses: (json['total_buses'] as num).toInt(),
      activeBuses: (json['active_buses'] as num).toInt(),
      maintenanceNeeded: (json['maintenance_needed'] as num).toInt(),
      insuranceExpiring: (json['insurance_expiring'] as num).toInt(),
      technicalVisitExpiring: (json['technical_visit_expiring'] as num).toInt(),
      vidangeNeeded: (json['vidange_needed'] as num).toInt(),
      breakdownsCount: (json['breakdowns_count'] as num).toInt(),
      patenteExpiring: (json['patente_expiring'] as num).toInt(),
    );

Map<String, dynamic> _$BusDashboardStatsToJson(BusDashboardStats instance) =>
    <String, dynamic>{
      'total_buses': instance.totalBuses,
      'active_buses': instance.activeBuses,
      'maintenance_needed': instance.maintenanceNeeded,
      'insurance_expiring': instance.insuranceExpiring,
      'technical_visit_expiring': instance.technicalVisitExpiring,
      'vidange_needed': instance.vidangeNeeded,
      'breakdowns_count': instance.breakdownsCount,
      'patente_expiring': instance.patenteExpiring,
    };

BusDashboard _$BusDashboardFromJson(Map<String, dynamic> json) => BusDashboard(
      stats: BusDashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      recentBreakdowns: (json['recent_breakdowns'] as List<dynamic>)
          .map((e) => BusBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BusDashboardToJson(BusDashboard instance) =>
    <String, dynamic>{
      'stats': instance.stats,
      'recent_breakdowns': instance.recentBreakdowns,
    };

Bus _$BusFromJson(Map<String, dynamic> json) => Bus(
      id: (json['id'] as num).toInt(),
      registrationNumber: json['registration_number'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      year: (json['year'] as num?)?.toInt(),
      capacity: (json['seat_count'] as num?)?.toInt(),
      status: json['status'] as String?,
      currentMileage: (json['current_mileage'] as num?)?.toDouble(),
      chassisNumber: json['chassis_number'] as String?,
      engineNumber: json['engine_number'] as String?,
      color: json['color'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      maintenanceRecords: (json['maintenance_records'] as List<dynamic>?)
          ?.map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      fuelRecords: (json['fuel_records'] as List<dynamic>?)
          ?.map((e) => FuelRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      technicalVisits: (json['technical_visits'] as List<dynamic>?)
          ?.map((e) => TechnicalVisit.fromJson(e as Map<String, dynamic>))
          .toList(),
      insuranceRecords: (json['insurance_records'] as List<dynamic>?)
          ?.map((e) => InsuranceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      patents: (json['patents'] as List<dynamic>?)
          ?.map((e) => Patent.fromJson(e as Map<String, dynamic>))
          .toList(),
      breakdowns: (json['breakdowns'] as List<dynamic>?)
          ?.map((e) => BusBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      vidanges: (json['vidanges'] as List<dynamic>?)
          ?.map((e) => BusVidange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BusToJson(Bus instance) => <String, dynamic>{
      'id': instance.id,
      'registration_number': instance.registrationNumber,
      'brand': instance.brand,
      'model': instance.model,
      'year': instance.year,
      'seat_count': instance.capacity,
      'status': instance.status,
      'current_mileage': instance.currentMileage,
      'chassis_number': instance.chassisNumber,
      'engine_number': instance.engineNumber,
      'color': instance.color,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'maintenance_records': instance.maintenanceRecords,
      'fuel_records': instance.fuelRecords,
      'technical_visits': instance.technicalVisits,
      'insurance_records': instance.insuranceRecords,
      'patents': instance.patents,
      'breakdowns': instance.breakdowns,
      'vidanges': instance.vidanges,
    };

MaintenanceRecord _$MaintenanceRecordFromJson(Map<String, dynamic> json) =>
    MaintenanceRecord(
      id: (json['id'] as num).toInt(),
      busId: (json['bus_id'] as num).toInt(),
      maintenanceType: json['maintenance_type'] as String?,
      maintenanceDate: DateTime.parse(json['maintenance_date'] as String),
      nextMaintenanceDate: json['next_maintenance_date'] == null
          ? null
          : DateTime.parse(json['next_maintenance_date'] as String),
      description: json['description'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      serviceProvider: json['service_provider'] as String?,
      mileage: (json['mileage'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MaintenanceRecordToJson(MaintenanceRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bus_id': instance.busId,
      'maintenance_type': instance.maintenanceType,
      'maintenance_date': instance.maintenanceDate.toIso8601String(),
      'next_maintenance_date': instance.nextMaintenanceDate?.toIso8601String(),
      'description': instance.description,
      'cost': instance.cost,
      'service_provider': instance.serviceProvider,
      'mileage': instance.mileage,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
    };

FuelRecord _$FuelRecordFromJson(Map<String, dynamic> json) => FuelRecord(
      id: FuelRecord._intFromJson(json['id']),
      busId: FuelRecord._intFromJson(json['bus_id']),
      date: DateTime.parse(json['date'] as String),
      cost: FuelRecord._costFromJson(json['cost']),
      invoicePhoto: json['invoice_photo'] as String?,
      notes: json['notes'] as String?,
      fueledAt: DateTime.parse(json['fueled_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FuelRecordToJson(FuelRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bus_id': instance.busId,
      'date': instance.date.toIso8601String(),
      'cost': instance.cost,
      'invoice_photo': instance.invoicePhoto,
      'notes': instance.notes,
      'fueled_at': instance.fueledAt.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

FuelStats _$FuelStatsFromJson(Map<String, dynamic> json) => FuelStats(
      totalConsumption: FuelStats._doubleFromJson(json['total_cost']),
      averageConsumption:
          FuelStats._nullableDoubleFromJson(json['average_cost']),
      lastMonthConsumption: FuelStats._doubleFromJson(json['last_month_cost']),
      lastRefill: json['last_refill'] == null
          ? null
          : FuelRecord.fromJson(json['last_refill'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FuelStatsToJson(FuelStats instance) => <String, dynamic>{
      'total_cost': instance.totalConsumption,
      'average_cost': instance.averageConsumption,
      'last_month_cost': instance.lastMonthConsumption,
      'last_refill': instance.lastRefill,
    };

TechnicalVisit _$TechnicalVisitFromJson(Map<String, dynamic> json) =>
    TechnicalVisit(
      id: (json['id'] as num).toInt(),
      busId: (json['bus_id'] as num).toInt(),
      visitDate: DateTime.parse(json['visit_date'] as String),
      expirationDate: DateTime.parse(json['expiration_date'] as String),
      documentPhoto: json['document_photo'] as String?,
      notes: json['notes'] as String?,
      isNotified: json['is_notified'] as bool,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TechnicalVisitToJson(TechnicalVisit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bus_id': instance.busId,
      'visit_date': instance.visitDate.toIso8601String(),
      'expiration_date': instance.expirationDate.toIso8601String(),
      'document_photo': instance.documentPhoto,
      'notes': instance.notes,
      'is_notified': instance.isNotified,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

InsuranceRecord _$InsuranceRecordFromJson(Map<String, dynamic> json) =>
    InsuranceRecord(
      id: (json['id'] as num).toInt(),
      busId: (json['bus_id'] as num).toInt(),
      policyNumber: json['policy_number'] as String,
      insuranceCompany: json['insurance_company'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      expiryDate: DateTime.parse(json['end_date'] as String),
      cost: (json['cost'] as num).toDouble(),
      documentPhoto: json['document_photo'] as String?,
      notes: json['notes'] as String?,
      isNotified: json['is_notified'] as bool,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$InsuranceRecordToJson(InsuranceRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bus_id': instance.busId,
      'policy_number': instance.policyNumber,
      'insurance_company': instance.insuranceCompany,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.expiryDate.toIso8601String(),
      'cost': instance.cost,
      'document_photo': instance.documentPhoto,
      'notes': instance.notes,
      'is_notified': instance.isNotified,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

Patent _$PatentFromJson(Map<String, dynamic> json) => Patent(
      id: _intFromJson(json['id']),
      busId: _intFromJson(json['bus_id']),
      patentNumber: json['patent_number'] as String,
      issueDate: DateTime.parse(json['issue_date'] as String),
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      cost: _costFromJsonGlobal(json['cost']),
      notes: json['notes'] as String?,
      documentPath: json['document_path'] as String?,
      documentUrl: json['document_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PatentToJson(Patent instance) => <String, dynamic>{
      'id': instance.id,
      'bus_id': instance.busId,
      'patent_number': instance.patentNumber,
      'issue_date': instance.issueDate.toIso8601String(),
      'expiry_date': instance.expiryDate.toIso8601String(),
      'cost': instance.cost,
      'notes': instance.notes,
      'document_path': instance.documentPath,
      'document_url': instance.documentUrl,
      'created_at': instance.createdAt?.toIso8601String(),
    };

BusBreakdown _$BusBreakdownFromJson(Map<String, dynamic> json) => BusBreakdown(
      id: (json['id'] as num).toInt(),
      busId: (json['bus_id'] as num).toInt(),
      kilometrage: (json['kilometrage'] as num?)?.toInt(),
      reparationEffectuee: json['reparation_effectuee'] as String,
      breakdownDate: DateTime.parse(json['date_panne'] as String),
      descriptionProbleme: json['description_probleme'] as String,
      diagnosticMecanicien: json['diagnostic_mecanicien'] as String,
      pieceRemplacee: json['piece_remplacee'] as String?,
      prixPiece: (json['prix_piece'] as num?)?.toDouble(),
      facturePhoto: json['facture_photo'] as String?,
      notesComplementaires: json['notes_complementaires'] as String?,
      statutReparation: json['statut_reparation'] as String,
      createdBy: (json['created_by'] as num).toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      bus: json['bus'] == null
          ? null
          : Bus.fromJson(json['bus'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BusBreakdownToJson(BusBreakdown instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bus_id': instance.busId,
      'kilometrage': instance.kilometrage,
      'reparation_effectuee': instance.reparationEffectuee,
      'date_panne': instance.breakdownDate.toIso8601String(),
      'description_probleme': instance.descriptionProbleme,
      'diagnostic_mecanicien': instance.diagnosticMecanicien,
      'piece_remplacee': instance.pieceRemplacee,
      'prix_piece': instance.prixPiece,
      'facture_photo': instance.facturePhoto,
      'notes_complementaires': instance.notesComplementaires,
      'statut_reparation': instance.statutReparation,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'bus': instance.bus,
    };

BusVidange _$BusVidangeFromJson(Map<String, dynamic> json) => BusVidange(
      id: (json['id'] as num).toInt(),
      busId: (json['bus_id'] as num).toInt(),
      lastVidangeDate: DateTime.parse(json['last_vidange_date'] as String),
      nextVidangeDate: DateTime.parse(json['next_vidange_date'] as String),
      notes: json['notes'] as String?,
      createdBy: (json['created_by'] as num).toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$BusVidangeToJson(BusVidange instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bus_id': instance.busId,
      'last_vidange_date': instance.lastVidangeDate.toIso8601String(),
      'next_vidange_date': instance.nextVidangeDate.toIso8601String(),
      'notes': instance.notes,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

PaginatedResponse<T> _$PaginatedResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    PaginatedResponse<T>(
      currentPage: (json['current_page'] as num).toInt(),
      data: (json['data'] as List<dynamic>).map(fromJsonT).toList(),
      firstPageUrl: json['first_page_url'] as String?,
      from: (json['from'] as num?)?.toInt(),
      lastPage: (json['last_page'] as num).toInt(),
      lastPageUrl: json['last_page_url'] as String?,
      nextPageUrl: json['next_page_url'] as String?,
      path: json['path'] as String,
      perPage: (json['per_page'] as num).toInt(),
      prevPageUrl: json['prev_page_url'] as String?,
      to: (json['to'] as num?)?.toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$PaginatedResponseToJson<T>(
  PaginatedResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'data': instance.data.map(toJsonT).toList(),
      'first_page_url': instance.firstPageUrl,
      'from': instance.from,
      'last_page': instance.lastPage,
      'last_page_url': instance.lastPageUrl,
      'next_page_url': instance.nextPageUrl,
      'path': instance.path,
      'per_page': instance.perPage,
      'prev_page_url': instance.prevPageUrl,
      'to': instance.to,
      'total': instance.total,
    };
