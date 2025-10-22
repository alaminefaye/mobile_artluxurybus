import 'package:json_annotation/json_annotation.dart';

part 'attendance_models.g.dart';

/// Modèle pour un pointage
@JsonSerializable()
class AttendanceRecord {
  final int id;
  final String location;
  @JsonKey(name: 'action_type')
  final String actionType;
  @JsonKey(name: 'action_label')
  final String actionLabel;
  final String status;
  @JsonKey(name: 'status_label')
  final String statusLabel;
  final String distance;
  @JsonKey(name: 'scanned_at')
  final String scannedAt;
  @JsonKey(name: 'failure_reason')
  final String? failureReason;

  AttendanceRecord({
    required this.id,
    required this.location,
    required this.actionType,
    required this.actionLabel,
    required this.status,
    required this.statusLabel,
    required this.distance,
    required this.scannedAt,
    this.failureReason,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceRecordToJson(this);

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isOutOfRange => status == 'out_of_range';
}

/// Modèle pour les statistiques de pointage
@JsonSerializable()
class AttendanceStats {
  final int month;
  final int year;
  @JsonKey(name: 'qr_stats')
  final QrStats qrStats;
  @JsonKey(name: 'attendance_stats')
  final EmployeeStats? employeeStats;
  @JsonKey(name: 'last_attendance')
  final LastAttendance? lastAttendance;

  AttendanceStats({
    required this.month,
    required this.year,
    required this.qrStats,
    this.employeeStats,
    this.lastAttendance,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) =>
      _$AttendanceStatsFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceStatsToJson(this);
}

@JsonSerializable()
class QrStats {
  @JsonKey(name: 'total_scans')
  final int totalScans;
  @JsonKey(name: 'successful_scans')
  final int successfulScans;
  @JsonKey(name: 'failed_scans')
  final int failedScans;
  @JsonKey(name: 'out_of_range_scans')
  final int outOfRangeScans;
  final int entries;
  final int exits;
  @JsonKey(name: 'success_rate')
  final double successRate;

  QrStats({
    required this.totalScans,
    required this.successfulScans,
    required this.failedScans,
    required this.outOfRangeScans,
    required this.entries,
    required this.exits,
    required this.successRate,
  });

  factory QrStats.fromJson(Map<String, dynamic> json) =>
      _$QrStatsFromJson(json);

  Map<String, dynamic> toJson() => _$QrStatsToJson(this);
}

@JsonSerializable()
class EmployeeStats {
  @JsonKey(name: 'total_days')
  final int totalDays;
  @JsonKey(name: 'worked_days')
  final int workedDays;
  @JsonKey(name: 'absent_days')
  final int absentDays;
  @JsonKey(name: 'justified_absences')
  final int justifiedAbsences;
  @JsonKey(name: 'total_hours')
  final double totalHours;

  EmployeeStats({
    required this.totalDays,
    required this.workedDays,
    required this.absentDays,
    required this.justifiedAbsences,
    required this.totalHours,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) =>
      _$EmployeeStatsFromJson(json);

  Map<String, dynamic> toJson() => _$EmployeeStatsToJson(this);
}

@JsonSerializable()
class LastAttendance {
  final String location;
  @JsonKey(name: 'action_type')
  final String actionType;
  @JsonKey(name: 'scanned_at')
  final String scannedAt;
  final String status;

  LastAttendance({
    required this.location,
    required this.actionType,
    required this.scannedAt,
    required this.status,
  });

  factory LastAttendance.fromJson(Map<String, dynamic> json) =>
      _$LastAttendanceFromJson(json);

  Map<String, dynamic> toJson() => _$LastAttendanceToJson(this);
}

/// Modèle pour le statut actuel de présence
@JsonSerializable()
class CurrentStatus {
  @JsonKey(name: 'current_status')
  final String currentStatus;
  final String message;
  @JsonKey(name: 'last_attendance')
  final CurrentLastAttendance? lastAttendance;

  CurrentStatus({
    required this.currentStatus,
    required this.message,
    this.lastAttendance,
  });

  factory CurrentStatus.fromJson(Map<String, dynamic> json) =>
      _$CurrentStatusFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentStatusToJson(this);

  bool get isCheckedIn => currentStatus == 'checked_in';
  bool get isCheckedOut => currentStatus == 'checked_out';
  bool get isOnBreak => currentStatus == 'on_break';
  bool get notCheckedIn => currentStatus == 'not_checked_in';
}

@JsonSerializable()
class CurrentLastAttendance {
  final int id;
  final String location;
  @JsonKey(name: 'action_type')
  final String actionType;
  @JsonKey(name: 'scanned_at')
  final String scannedAt;
  @JsonKey(name: 'time_ago')
  final String timeAgo;

  CurrentLastAttendance({
    required this.id,
    required this.location,
    required this.actionType,
    required this.scannedAt,
    required this.timeAgo,
  });

  factory CurrentLastAttendance.fromJson(Map<String, dynamic> json) =>
      _$CurrentLastAttendanceFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentLastAttendanceToJson(this);
}

/// Modèle pour une location
@JsonSerializable()
class AttendanceLocation {
  final int id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  @JsonKey(name: 'max_scan_distance')
  final int maxScanDistance;
  @JsonKey(name: 'has_active_qr_codes')
  final bool hasActiveQrCodes;

  AttendanceLocation({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.maxScanDistance,
    required this.hasActiveQrCodes,
  });

  factory AttendanceLocation.fromJson(Map<String, dynamic> json) =>
      _$AttendanceLocationFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceLocationToJson(this);
}

/// Enum pour les types d'action
enum ActionType {
  @JsonValue('entry')
  entry,
  @JsonValue('exit')
  exit,
  @JsonValue('break')
  break_,
}

extension ActionTypeExtension on ActionType {
  String get value {
    switch (this) {
      case ActionType.entry:
        return 'entry';
      case ActionType.exit:
        return 'exit';
      case ActionType.break_:
        return 'break';
    }
  }

  String get label {
    switch (this) {
      case ActionType.entry:
        return 'Entrée';
      case ActionType.exit:
        return 'Sortie';
      case ActionType.break_:
        return 'Pause';
    }
  }
}
