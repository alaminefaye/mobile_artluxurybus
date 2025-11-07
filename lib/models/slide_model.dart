class Slide {
  final int id;
  final String title;
  final String imageUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;

  Slide({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] is bool)
          ? json['is_active'] as bool
          : (json['is_active'] == 1 || json['is_active'] == '1'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Slide copyWith({
    int? id,
    String? title,
    String? imageUrl,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Slide(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

