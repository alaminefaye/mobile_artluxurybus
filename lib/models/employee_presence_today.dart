/// Modèle pour la présence d'un employé aujourd'hui
class EmployeePresenceToday {
  final int id;
  final String name;
  final String? phone;
  final String? position;
  final String?
      currentStatus; // checked_in, checked_out, on_break, not_checked_in
  final String? checkedInAt;
  final String? checkedOutAt;
  final String? lastActionType; // entry, exit, break
  final String? lastActionLabel; // Entrée, Sortie, Pause

  EmployeePresenceToday({
    required this.id,
    required this.name,
    this.phone,
    this.position,
    this.currentStatus,
    this.checkedInAt,
    this.checkedOutAt,
    this.lastActionType,
    this.lastActionLabel,
  });

  /// Indique si l'employé a pointé au moins une fois aujourd'hui
  bool get hasPointed =>
      (checkedInAt != null && checkedInAt!.isNotEmpty) ||
      (checkedOutAt != null && checkedOutAt!.isNotEmpty) ||
      (currentStatus != null && currentStatus != 'not_checked_in');

  factory EmployeePresenceToday.fromJson(Map<String, dynamic> json) {
    return EmployeePresenceToday(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: (json['name'] ?? json['full_name'] ?? '').toString(),
      phone: (json['phone'] ?? json['telephone'])?.toString(),
      position:
          (json['position'] ?? json['poste'] ?? json['job_title'])?.toString(),
      currentStatus: (json['current_status'] ?? json['status'])?.toString(),
      checkedInAt:
          (json['checked_in_at'] ?? json['first_checkin_at'])?.toString(),
      checkedOutAt:
          (json['checked_out_at'] ?? json['last_checkout_at'])?.toString(),
      lastActionType:
          (json['last_action_type'] ?? json['action_type'])?.toString(),
      lastActionLabel:
          (json['last_action_label'] ?? json['action_label'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'position': position,
      'current_status': currentStatus,
      'checked_in_at': checkedInAt,
      'checked_out_at': checkedOutAt,
      'last_action_type': lastActionType,
      'last_action_label': lastActionLabel,
    };
  }
}
