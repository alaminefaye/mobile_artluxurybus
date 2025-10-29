class VideoAdvertisement {
  final int id;
  final String title;
  final String? description;
  final String url;
  final String videoPath;
  final int? duration;
  final String durationFormatted;
  final int fileSize;
  final String fileSizeFormatted;
  final int displayOrder;
  final int viewsCount;
  final bool isActive;
  final Creator? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoAdvertisement({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    required this.videoPath,
    this.duration,
    required this.durationFormatted,
    required this.fileSize,
    required this.fileSizeFormatted,
    required this.displayOrder,
    required this.viewsCount,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoAdvertisement.fromJson(Map<String, dynamic> json) {
    return VideoAdvertisement(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      url: json['url'] as String? ?? '',
      videoPath: json['video_path'] as String? ?? '',
      duration: json['duration'] as int?,
      durationFormatted: json['duration_formatted'] as String? ?? 'N/A',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      fileSizeFormatted: json['file_size_formatted'] as String? ?? '0 B',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] is bool) 
          ? json['is_active'] as bool 
          : (json['is_active'] == 1 || json['is_active'] == '1'),
      createdBy: json['created_by'] != null
          ? Creator.fromJson(json['created_by'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'video_path': videoPath,
      'duration': duration,
      'duration_formatted': durationFormatted,
      'file_size': fileSize,
      'file_size_formatted': fileSizeFormatted,
      'display_order': displayOrder,
      'views_count': viewsCount,
      'is_active': isActive,
      'created_by': createdBy?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VideoAdvertisement copyWith({
    int? id,
    String? title,
    String? description,
    String? url,
    String? videoPath,
    int? duration,
    String? durationFormatted,
    int? fileSize,
    String? fileSizeFormatted,
    int? displayOrder,
    int? viewsCount,
    bool? isActive,
    Creator? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoAdvertisement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      videoPath: videoPath ?? this.videoPath,
      duration: duration ?? this.duration,
      durationFormatted: durationFormatted ?? this.durationFormatted,
      fileSize: fileSize ?? this.fileSize,
      fileSizeFormatted: fileSizeFormatted ?? this.fileSizeFormatted,
      displayOrder: displayOrder ?? this.displayOrder,
      viewsCount: viewsCount ?? this.viewsCount,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Creator {
  final int id;
  final String name;
  final String email;

  Creator({
    required this.id,
    required this.name,
    required this.email,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
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

