class FeedbackModel {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String subject;
  final String message;
  final String? status;
  final String? statusLabel;
  final String? statusColor;
  final String? priority;
  final String? priorityLabel;
  final String? priorityColor;
  final List<String>? keywords;
  final bool? isUnread;
  final TravelInfo? travelInfo;
  final String? photoUrl;
  final DateTime? createdAt;
  final String? createdAtHuman;

  FeedbackModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.subject,
    required this.message,
    this.status,
    this.statusLabel,
    this.statusColor,
    this.priority,
    this.priorityLabel,
    this.priorityColor,
    this.keywords,
    this.isUnread,
    this.travelInfo,
    this.photoUrl,
    this.createdAt,
    this.createdAtHuman,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      status: json['status'],
      statusLabel: json['status_label'],
      statusColor: json['status_color'],
      priority: json['priority'],
      priorityLabel: json['priority_label'],
      priorityColor: json['priority_color'],
      keywords: json['keywords'] != null ? List<String>.from(json['keywords']) : null,
      isUnread: json['is_unread'],
      travelInfo: json['travel_info'] != null 
          ? TravelInfo.fromJson(json['travel_info'])
          : null,
      photoUrl: json['photo_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'])
          : null,
      createdAtHuman: json['created_at_human'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'subject': subject,
      'message': message,
      'status': status,
      'status_label': statusLabel,
      'status_color': statusColor,
      'priority': priority,
      'priority_label': priorityLabel,
      'priority_color': priorityColor,
      'keywords': keywords,
      'is_unread': isUnread,
      'travel_info': travelInfo?.toJson(),
      'photo_url': photoUrl,
      'created_at': createdAt?.toIso8601String(),
      'created_at_human': createdAtHuman,
    };
  }
}

class TravelInfo {
  final String? station;
  final String? route;
  final String? seatNumber;
  final String? departureNumber;

  TravelInfo({
    this.station,
    this.route,
    this.seatNumber,
    this.departureNumber,
  });

  factory TravelInfo.fromJson(Map<String, dynamic> json) {
    return TravelInfo(
      station: json['station'],
      route: json['route'],
      seatNumber: json['seat_number'],
      departureNumber: json['departure_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station': station,
      'route': route,
      'seat_number': seatNumber,
      'departure_number': departureNumber,
    };
  }
}

class FeedbackStats {
  final int total;
  final int nouveau;
  final int enCours;
  final int resolu;
  final int hautePriorite;
  final int nonLus;

  FeedbackStats({
    required this.total,
    required this.nouveau,
    required this.enCours,
    required this.resolu,
    required this.hautePriorite,
    required this.nonLus,
  });

  factory FeedbackStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return FeedbackStats(
      total: data['total'] ?? 0,
      nouveau: data['nouveau'] ?? 0,
      enCours: data['en_cours'] ?? 0,
      resolu: data['résolu'] ?? data['resolu'] ?? 0,
      hautePriorite: data['haute_priorite'] ?? 0,
      nonLus: data['non_lus'] ?? 0,
    );
  }
}
