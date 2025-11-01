import 'package:flutter/foundation.dart';

class MessageModel {
  final int id;
  final String titre;
  final String contenu;
  final String type; // 'notification' ou 'annonce'
  final int? gareId;
  final GareInfo? gare;
  final String? appareil; // 'mobile', 'ecran_tv', 'ecran_led', 'tous'
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final bool active;
  final bool isExpired;
  final DateTime createdAt;
  final DateTime updatedAt;

  MessageModel({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.type,
    this.gareId,
    this.gare,
    this.appareil,
    this.dateDebut,
    this.dateFin,
    required this.active,
    required this.isExpired,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      contenu: json['contenu'] as String,
      type: json['type'] as String,
      gareId: json['gare_id'] as int?,
      gare: json['gare'] != null ? GareInfo.fromJson(json['gare']) : null,
      appareil: json['appareil'] as String?,
      dateDebut: json['date_debut'] != null
          ? DateTime.parse(json['date_debut'])
          : null,
      dateFin:
          json['date_fin'] != null ? DateTime.parse(json['date_fin']) : null,
      active: json['active'] as bool? ?? true,
      isExpired: json['is_expired'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'contenu': contenu,
      'type': type,
      'gare_id': gareId,
      'gare': gare?.toJson(),
      'appareil': appareil,
      'date_debut': dateDebut?.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'active': active,
      'is_expired': isExpired,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isNotification => type == 'notification';
  bool get isAnnonce => type == 'annonce';

  bool get isCurrentlyActive {
    if (!active) {
      debugPrint('📅 [MessageModel] Message non actif (active=false)');
      return false;
    }
    if (isExpired) {
      debugPrint('📅 [MessageModel] Message expiré (isExpired=true)');
      return false;
    }

    final now = DateTime.now();
    if (dateDebut != null && now.isBefore(dateDebut!)) {
      debugPrint(
          '📅 [MessageModel] Message pas encore commencé (dateDebut: $dateDebut, now: $now)');
      return false;
    }
    if (dateFin != null && now.isAfter(dateFin!)) {
      debugPrint(
          '📅 [MessageModel] Message terminé (dateFin: $dateFin, now: $now)');
      return false;
    }

    debugPrint(
        '✅ [MessageModel] Message actif (active: $active, isExpired: $isExpired, dateDebut: $dateDebut, dateFin: $dateFin)');
    return true;
  }

  String get formattedPeriod {
    if (dateDebut == null || dateFin == null) return '';

    final debut = '${dateDebut!.day}/${dateDebut!.month}/${dateDebut!.year}';
    final fin = '${dateFin!.day}/${dateFin!.month}/${dateFin!.year}';

    return 'Du $debut au $fin';
  }
}

class GareInfo {
  final int id;
  final String nom;
  final String? appareil;

  GareInfo({
    required this.id,
    required this.nom,
    this.appareil,
  });

  factory GareInfo.fromJson(Map<String, dynamic> json) {
    return GareInfo(
      id: json['id'] as int,
      nom: json['nom'] as String,
      appareil: json['appareil'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'appareil': appareil,
    };
  }
}
