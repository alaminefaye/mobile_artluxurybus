class MailModel {
  final int id;
  final String mailNumber;
  final String destination;
  final String senderName;
  final String senderPhone;
  final String recipientName;
  final String recipientPhone;
  final double amount;
  final String packageValue;
  final String packageType;
  final String receivingAgency;
  final String? description;
  final String? photo;
  final bool isCollected;
  final DateTime? collectedAt;
  final int? collectedBy;
  final String? collectorName;
  final String? collectorPhone;
  final String? collectorIdCard;
  final String? collectorSignature;
  final int? clientProfileId;
  final bool isLoyaltyMail;
  final String? loyaltyNotes;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final UserInfo? collectedByUser;
  final UserInfo? createdByUser;
  final ClientProfile? clientProfile;

  MailModel({
    required this.id,
    required this.mailNumber,
    required this.destination,
    required this.senderName,
    required this.senderPhone,
    required this.recipientName,
    required this.recipientPhone,
    required this.amount,
    required this.packageValue,
    required this.packageType,
    required this.receivingAgency,
    this.description,
    this.photo,
    required this.isCollected,
    this.collectedAt,
    this.collectedBy,
    this.collectorName,
    this.collectorPhone,
    this.collectorIdCard,
    this.collectorSignature,
    this.clientProfileId,
    this.isLoyaltyMail = false,
    this.loyaltyNotes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.collectedByUser,
    this.createdByUser,
    this.clientProfile,
  });

  factory MailModel.fromJson(Map<String, dynamic> json) {
    return MailModel(
      id: json['id'] ?? 0,
      mailNumber: json['mail_number'] ?? '',
      destination: json['destination'] ?? '',
      senderName: json['sender_name'] ?? '',
      senderPhone: json['sender_phone'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      recipientPhone: json['recipient_phone'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      packageValue: json['package_value'] ?? '',
      packageType: json['package_type'] ?? '',
      receivingAgency: json['receiving_agency'] ?? '',
      description: json['description'],
      photo: json['photo'],
      isCollected: json['is_collected'] == true || json['is_collected'] == 1,
      collectedAt: json['collected_at'] != null
          ? DateTime.parse(json['collected_at'])
          : null,
      collectedBy: json['collected_by'],
      collectorName: json['collector_name'],
      collectorPhone: json['collector_phone'],
      collectorIdCard: json['collector_id_card'],
      collectorSignature: json['collector_signature'],
      clientProfileId: json['client_profile_id'],
      isLoyaltyMail:
          json['is_loyalty_mail'] == true || json['is_loyalty_mail'] == 1,
      loyaltyNotes: json['loyalty_notes'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      collectedByUser: json['collected_by_user'] != null
          ? UserInfo.fromJson(json['collected_by_user'])
          : null,
      createdByUser: json['created_by_user'] != null
          ? UserInfo.fromJson(json['created_by_user'])
          : null,
      clientProfile: json['client_profile'] != null
          ? ClientProfile.fromJson(json['client_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mail_number': mailNumber,
      'destination': destination,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'amount': amount,
      'package_value': packageValue,
      'package_type': packageType,
      'receiving_agency': receivingAgency,
      'description': description,
      'photo': photo,
      'is_collected': isCollected,
      'collected_at': collectedAt?.toIso8601String(),
      'collected_by': collectedBy,
      'collector_name': collectorName,
      'collector_phone': collectorPhone,
      'collector_id_card': collectorIdCard,
      'collector_signature': collectorSignature,
      'client_profile_id': clientProfileId,
      'is_loyalty_mail': isLoyaltyMail,
      'loyalty_notes': loyaltyNotes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MailModel copyWith({
    int? id,
    String? mailNumber,
    String? destination,
    String? senderName,
    String? senderPhone,
    String? recipientName,
    String? recipientPhone,
    double? amount,
    String? packageValue,
    String? packageType,
    String? receivingAgency,
    String? description,
    String? photo,
    bool? isCollected,
    DateTime? collectedAt,
    int? collectedBy,
    String? collectorName,
    String? collectorPhone,
    String? collectorIdCard,
    String? collectorSignature,
    int? clientProfileId,
    bool? isLoyaltyMail,
    String? loyaltyNotes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserInfo? collectedByUser,
    UserInfo? createdByUser,
    ClientProfile? clientProfile,
  }) {
    return MailModel(
      id: id ?? this.id,
      mailNumber: mailNumber ?? this.mailNumber,
      destination: destination ?? this.destination,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      amount: amount ?? this.amount,
      packageValue: packageValue ?? this.packageValue,
      packageType: packageType ?? this.packageType,
      receivingAgency: receivingAgency ?? this.receivingAgency,
      description: description ?? this.description,
      photo: photo ?? this.photo,
      isCollected: isCollected ?? this.isCollected,
      collectedAt: collectedAt ?? this.collectedAt,
      collectedBy: collectedBy ?? this.collectedBy,
      collectorName: collectorName ?? this.collectorName,
      collectorPhone: collectorPhone ?? this.collectorPhone,
      collectorIdCard: collectorIdCard ?? this.collectorIdCard,
      collectorSignature: collectorSignature ?? this.collectorSignature,
      clientProfileId: clientProfileId ?? this.clientProfileId,
      isLoyaltyMail: isLoyaltyMail ?? this.isLoyaltyMail,
      loyaltyNotes: loyaltyNotes ?? this.loyaltyNotes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      collectedByUser: collectedByUser ?? this.collectedByUser,
      createdByUser: createdByUser ?? this.createdByUser,
      clientProfile: clientProfile ?? this.clientProfile,
    );
  }
}

class UserInfo {
  final int id;
  final String name;
  final String? email;

  UserInfo({
    required this.id,
    required this.name,
    this.email,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
    );
  }
}

class ClientProfile {
  final int id;
  final String nom;
  final String telephone;
  final int points;
  final int mailPoints;

  ClientProfile({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.points,
    required this.mailPoints,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      telephone: json['telephone'] ?? '',
      points: json['points'] ?? 0,
      mailPoints: json['mail_points'] ?? 0,
    );
  }
}

class MailStats {
  final int total;
  final int collected;
  final int pending;
  final int today;
  final int thisWeek;
  final int thisMonth;
  final double totalRevenue;
  final double revenueThisMonth;

  MailStats({
    required this.total,
    required this.collected,
    required this.pending,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.totalRevenue,
    required this.revenueThisMonth,
  });

  factory MailStats.fromJson(Map<String, dynamic> json) {
    return MailStats(
      total: json['total'] ?? 0,
      collected: json['collected'] ?? 0,
      pending: json['pending'] ?? 0,
      today: json['today'] ?? 0,
      thisWeek: json['this_week'] ?? 0,
      thisMonth: json['this_month'] ?? 0,
      totalRevenue: double.tryParse(json['total_revenue'].toString()) ?? 0.0,
      revenueThisMonth:
          double.tryParse(json['revenue_this_month'].toString()) ?? 0.0,
    );
  }
}

class MailDashboard {
  final DashboardPeriod today;
  final DashboardPeriod week;
  final DashboardPeriod month;
  final List<MailModel> pendingMails;
  final List<MailModel> recentCollections;
  final List<DestinationStat> topDestinations;

  MailDashboard({
    required this.today,
    required this.week,
    required this.month,
    required this.pendingMails,
    required this.recentCollections,
    required this.topDestinations,
  });

  factory MailDashboard.fromJson(Map<String, dynamic> json) {
    return MailDashboard(
      today: DashboardPeriod.fromJson(json['today'] ?? {}),
      week: DashboardPeriod.fromJson(json['week'] ?? {}),
      month: DashboardPeriod.fromJson(json['month'] ?? {}),
      pendingMails: (json['pending_mails'] as List?)
              ?.map((e) => MailModel.fromJson(e))
              .toList() ??
          [],
      recentCollections: (json['recent_collections'] as List?)
              ?.map((e) => MailModel.fromJson(e))
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
  final int collected;
  final int pending;
  final double revenue;

  DashboardPeriod({
    required this.total,
    required this.collected,
    required this.pending,
    required this.revenue,
  });

  factory DashboardPeriod.fromJson(Map<String, dynamic> json) {
    return DashboardPeriod(
      total: json['total'] ?? 0,
      collected: json['collected'] ?? 0,
      pending: json['pending'] ?? 0,
      revenue: double.tryParse(json['revenue'].toString()) ?? 0.0,
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
