import 'package:flutter/material.dart';

class AdminExpense {
  final int id;
  final String typeDepense;
  final String titre;
  final double montant;
  final String? description;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relations
  final AdminExpenseCreator? creator;

  AdminExpense({
    required this.id,
    required this.typeDepense,
    required this.titre,
    required this.montant,
    this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
  });

  factory AdminExpense.fromJson(Map<String, dynamic> json) {
    return AdminExpense(
      id: json['id'] as int,
      typeDepense: json['type_depense'] as String,
      titre: json['titre'] as String,
      montant: (json['montant'] as num).toDouble(),
      description: json['description'] as String?,
      createdBy: json['created_by'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      creator: json['creator'] != null
          ? AdminExpenseCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type_depense': typeDepense,
      'titre': titre,
      'montant': montant,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'creator': creator?.toJson(),
    };
  }

  String get typeDepenseLabel {
    switch (typeDepense) {
      case 'eau':
        return 'Eau';
      case 'surcrerie':
        return 'Surcrerie';
      case 'achat_pieces':
        return 'Achat pièces';
      case 'vidange':
        return 'Vidange';
      case 'carburant':
        return 'Carburant';
      default:
        return typeDepense;
    }
  }

  Color get typeDepenseColor {
    switch (typeDepense) {
      case 'eau':
        return const Color(0xFF3B82F6); // Blue
      case 'surcrerie':
        return const Color(0xFF10B981); // Green
      case 'achat_pieces':
        return const Color(0xFFF59E0B); // Amber
      case 'vidange':
        return const Color(0xFFEF4444); // Red
      case 'carburant':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return Colors.grey;
    }
  }
}

class AdminExpenseCreator {
  final int id;
  final String name;
  final String? email;

  AdminExpenseCreator({
    required this.id,
    required this.name,
    this.email,
  });

  factory AdminExpenseCreator.fromJson(Map<String, dynamic> json) {
    return AdminExpenseCreator(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

