import 'dart:convert';

class AdModel {
  final int? id;
  final String? title;
  final String? description;
  final String? videoUrl;
  final String? imageUrl;
  final String? linkUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final int? displaySeconds;

  AdModel({
    this.id,
    this.title,
    this.description,
    this.videoUrl,
    this.imageUrl,
    this.linkUrl,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
    this.displaySeconds,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    // Try common key variants
    String? str(dynamic v) => v?.toString();
    DateTime? dt(dynamic v) {
      if (v == null) return null;
      try { return DateTime.parse(v.toString()); } catch (_) { return null; }
    }

    return AdModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(str(json['id']) ?? ''),
      title: str(json['title'] ?? json['name'] ?? json['label']),
      description: str(json['description'] ?? json['desc']),
      videoUrl: str(json['video_url'] ?? json['video'] ?? json['media_url'] ?? json['url']),
      imageUrl: str(json['image_url'] ?? json['image'] ?? json['thumbnail']),
      linkUrl: str(json['link_url'] ?? json['target_url'] ?? json['link']),
      startsAt: dt(json['starts_at'] ?? json['start_at'] ?? json['start_date']),
      endsAt: dt(json['ends_at'] ?? json['end_at'] ?? json['end_date']),
      isActive: (json['is_active'] ?? json['active'] ?? 1) == true || (json['is_active'] ?? json['active'] ?? 1) == 1,
      displaySeconds: json['display_seconds'] is int
          ? json['display_seconds'] as int
          : int.tryParse(str(json['display_seconds'] ?? json['duration']) ?? ''),
    );
  }

  static List<AdModel> listFromJson(dynamic data) {
    if (data is List) {
      return data.map((e) => AdModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map<String, dynamic>) {
      // Support { data: [...] } or { items: [...] }
      final list = data['data'] ?? data['items'] ?? data['ads'] ?? data['publicites'];
      if (list is List) {
        return list.map((e) => AdModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'video_url': videoUrl,
    'image_url': imageUrl,
    'link_url': linkUrl,
    'starts_at': startsAt?.toIso8601String(),
    'ends_at': endsAt?.toIso8601String(),
    'is_active': isActive,
    'display_seconds': displaySeconds,
  };

  @override
  String toString() => jsonEncode(toJson());
}