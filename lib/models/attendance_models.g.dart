// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceRecord _$AttendanceRecordFromJson(Map<String, dynamic> json) =>
    AttendanceRecord(
      id: (json['id'] as num).toInt(),
      location: json['location'] as String,
      actionType: json['action_type'] as String,
      actionLabel: json['action_label'] as String,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
      distance: json['distance'] as String,
      scannedAt: json['scanned_at'] as String,
      failureReason: json['failure_reason'] as String?,
    );

Map<String, dynamic> _$AttendanceRecordToJson(AttendanceRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'location': instance.location,
      'action_type': instance.actionType,
      'action_label': instance.actionLabel,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'distance': instance.distance,
      'scanned_at': instance.scannedAt,
      'failure_reason': instance.failureReason,
    };

AttendanceStats _$AttendanceStatsFromJson(Map<String, dynamic> json) =>
    AttendanceStats(
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      qrStats: QrStats.fromJson(json['qr_stats'] as Map<String, dynamic>),
      employeeStats: json['attendance_stats'] == null
          ? null
          : EmployeeStats.fromJson(
              json['attendance_stats'] as Map<String, dynamic>),
      lastAttendance: json['last_attendance'] == null
          ? null
          : LastAttendance.fromJson(
              json['last_attendance'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttendanceStatsToJson(AttendanceStats instance) =>
    <String, dynamic>{
      'month': instance.month,
      'year': instance.year,
      'qr_stats': instance.qrStats,
      'attendance_stats': instance.employeeStats,
      'last_attendance': instance.lastAttendance,
    };

QrStats _$QrStatsFromJson(Map<String, dynamic> json) => QrStats(
      totalScans: (json['total_scans'] as num).toInt(),
      successfulScans: (json['successful_scans'] as num).toInt(),
      failedScans: (json['failed_scans'] as num).toInt(),
      outOfRangeScans: (json['out_of_range_scans'] as num).toInt(),
      entries: (json['entries'] as num).toInt(),
      exits: (json['exits'] as num).toInt(),
      successRate: (json['success_rate'] as num).toDouble(),
    );

Map<String, dynamic> _$QrStatsToJson(QrStats instance) => <String, dynamic>{
      'total_scans': instance.totalScans,
      'successful_scans': instance.successfulScans,
      'failed_scans': instance.failedScans,
      'out_of_range_scans': instance.outOfRangeScans,
      'entries': instance.entries,
      'exits': instance.exits,
      'success_rate': instance.successRate,
    };

EmployeeStats _$EmployeeStatsFromJson(Map<String, dynamic> json) =>
    EmployeeStats(
      totalDays: (json['total_days'] as num).toInt(),
      workedDays: (json['worked_days'] as num).toInt(),
      absentDays: (json['absent_days'] as num).toInt(),
      justifiedAbsences: (json['justified_absences'] as num).toInt(),
      totalHours: (json['total_hours'] as num).toDouble(),
    );

Map<String, dynamic> _$EmployeeStatsToJson(EmployeeStats instance) =>
    <String, dynamic>{
      'total_days': instance.totalDays,
      'worked_days': instance.workedDays,
      'absent_days': instance.absentDays,
      'justified_absences': instance.justifiedAbsences,
      'total_hours': instance.totalHours,
    };

LastAttendance _$LastAttendanceFromJson(Map<String, dynamic> json) =>
    LastAttendance(
      location: json['location'] as String,
      actionType: json['action_type'] as String,
      scannedAt: json['scanned_at'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$LastAttendanceToJson(LastAttendance instance) =>
    <String, dynamic>{
      'location': instance.location,
      'action_type': instance.actionType,
      'scanned_at': instance.scannedAt,
      'status': instance.status,
    };

CurrentStatus _$CurrentStatusFromJson(Map<String, dynamic> json) =>
    CurrentStatus(
      currentStatus: json['current_status'] as String,
      message: json['message'] as String,
      lastAttendance: json['last_attendance'] == null
          ? null
          : CurrentLastAttendance.fromJson(
              json['last_attendance'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CurrentStatusToJson(CurrentStatus instance) =>
    <String, dynamic>{
      'current_status': instance.currentStatus,
      'message': instance.message,
      'last_attendance': instance.lastAttendance,
    };

CurrentLastAttendance _$CurrentLastAttendanceFromJson(
        Map<String, dynamic> json) =>
    CurrentLastAttendance(
      id: (json['id'] as num).toInt(),
      location: json['location'] as String,
      actionType: json['action_type'] as String,
      scannedAt: json['scanned_at'] as String,
      timeAgo: json['time_ago'] as String,
    );

Map<String, dynamic> _$CurrentLastAttendanceToJson(
        CurrentLastAttendance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'location': instance.location,
      'action_type': instance.actionType,
      'scanned_at': instance.scannedAt,
      'time_ago': instance.timeAgo,
    };

AttendanceLocation _$AttendanceLocationFromJson(Map<String, dynamic> json) =>
    AttendanceLocation(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      maxScanDistance: (json['max_scan_distance'] as num).toInt(),
      hasActiveQrCodes: json['has_active_qr_codes'] as bool,
    );

Map<String, dynamic> _$AttendanceLocationToJson(AttendanceLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'max_scan_distance': instance.maxScanDistance,
      'has_active_qr_codes': instance.hasActiveQrCodes,
    };
