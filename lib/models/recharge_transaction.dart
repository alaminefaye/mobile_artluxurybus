/// Modèle pour une transaction de recharge
class RechargeTransaction {
  final int id;
  final double montant;
  final String modePaiement;
  final String modePaiementLabel;
  final String status;
  final String statusLabel;
  final String? transactionId;
  final String date;
  final String dateIso;
  final String? completedAt;

  RechargeTransaction({
    required this.id,
    required this.montant,
    required this.modePaiement,
    required this.modePaiementLabel,
    required this.status,
    required this.statusLabel,
    this.transactionId,
    required this.date,
    required this.dateIso,
    this.completedAt,
  });

  factory RechargeTransaction.fromJson(Map<String, dynamic> json) {
    return RechargeTransaction(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      montant: (json['montant'] is num)
          ? (json['montant'] as num).toDouble()
          : double.tryParse('${json['montant'] ?? 0}') ?? 0.0,
      modePaiement: (json['mode_paiement'] ?? '').toString(),
      modePaiementLabel: (json['mode_paiement_label'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      transactionId: json['transaction_id']?.toString(),
      date: (json['date'] ?? '').toString(),
      dateIso: (json['date_iso'] ?? '').toString(),
      completedAt: json['completed_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'montant': montant,
      'mode_paiement': modePaiement,
      'mode_paiement_label': modePaiementLabel,
      'status': status,
      'status_label': statusLabel,
      'transaction_id': transactionId,
      'date': date,
      'date_iso': dateIso,
      'completed_at': completedAt,
    };
  }
}
