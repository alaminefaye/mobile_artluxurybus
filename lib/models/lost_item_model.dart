class LostItem {
  final int id;
  final String title;
  final String? description;
  final String? photoUrl;
  final String currentLocation;
  final List<String> tags;
  final String foundDate;
  final String? foundBy;

  LostItem({
    required this.id,
    required this.title,
    this.description,
    this.photoUrl,
    required this.currentLocation,
    required this.tags,
    required this.foundDate,
    this.foundBy,
  });

  factory LostItem.fromJson(Map<String, dynamic> json) {
    return LostItem(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      photoUrl: json['photo_url'],
      currentLocation: json['current_location'] ?? '',
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
      foundDate: json['found_date'] ?? '',
      foundBy: json['found_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'photo_url': photoUrl,
      'current_location': currentLocation,
      'tags': tags,
      'found_date': foundDate,
      'found_by': foundBy,
    };
  }
}
