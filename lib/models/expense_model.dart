class Expense {
  final int id;
  final String motif;
  final double montant;
  final String status;
  final String? commentaire;
  final String type;
  final int? employeeId;
  final int createdBy;
  final int? validatedBy;
  final DateTime? validatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relations
  final ExpenseCreator? creator;
  final ExpenseValidator? validator;
  final ExpenseEmployee? employee;

  Expense({
    required this.id,
    required this.motif,
    required this.montant,
    required this.status,
    this.commentaire,
    required this.type,
    this.employeeId,
    required this.createdBy,
    this.validatedBy,
    this.validatedAt,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
    this.validator,
    this.employee,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      motif: json['motif'] as String,
      montant: (json['montant'] as num).toDouble(),
      status: json['status'] as String,
      commentaire: json['commentaire'] as String?,
      type: json['type'] as String,
      employeeId: json['employee_id'] as int?,
      createdBy: json['created_by'] as int,
      validatedBy: json['validated_by'] as int?,
      validatedAt: json['validated_at'] != null
          ? DateTime.parse(json['validated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      creator: json['creator'] != null
          ? ExpenseCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      validator: json['validator'] != null
          ? ExpenseValidator.fromJson(json['validator'] as Map<String, dynamic>)
          : null,
      employee: json['employee'] != null
          ? ExpenseEmployee.fromJson(json['employee'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motif': motif,
      'montant': montant,
      'status': status,
      'commentaire': commentaire,
      'type': type,
      'employee_id': employeeId,
      'created_by': createdBy,
      'validated_by': validatedBy,
      'validated_at': validatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'creator': creator?.toJson(),
      'validator': validator?.toJson(),
      'employee': employee?.toJson(),
    };
  }

  bool get isPending => status == 'en_attente';
  bool get isValidated => status == 'validee';
  bool get isRejected => status == 'rejetee';

  String get statusLabel {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'validee':
        return 'Validée';
      case 'rejetee':
        return 'Rejetée';
      default:
        return status;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'divers':
        return 'Divers';
      case 'ration':
        return 'Ration';
      default:
        return type;
    }
  }
}

class ExpenseCreator {
  final int id;
  final String name;
  final String? email;

  ExpenseCreator({
    required this.id,
    required this.name,
    this.email,
  });

  factory ExpenseCreator.fromJson(Map<String, dynamic> json) {
    return ExpenseCreator(
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

class ExpenseValidator {
  final int id;
  final String name;
  final String? email;

  ExpenseValidator({
    required this.id,
    required this.name,
    this.email,
  });

  factory ExpenseValidator.fromJson(Map<String, dynamic> json) {
    return ExpenseValidator(
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

class ExpenseEmployee {
  final int id;
  final String name;
  final String? matricule;
  final String? position;

  ExpenseEmployee({
    required this.id,
    required this.name,
    this.matricule,
    this.position,
  });

  factory ExpenseEmployee.fromJson(Map<String, dynamic> json) {
    return ExpenseEmployee(
      id: json['id'] as int,
      name: json['name'] as String,
      matricule: json['matricule'] as String?,
      position: json['position'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'matricule': matricule,
      'position': position,
    };
  }
}

