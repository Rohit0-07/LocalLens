class NoticeItem {
  final int id;
  final String title;
  final String description;
  final String officialHeader;
  final DateTime? validUntil;
  final String ward;
  final double latitude;
  final double longitude;
  final String? geohash;
  final DateTime createdAt;

  const NoticeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.officialHeader,
    this.validUntil,
    required this.ward,
    required this.latitude,
    required this.longitude,
    this.geohash,
    required this.createdAt,
  });

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      officialHeader: json['official_header'] as String? ?? 'Official Notice',
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'] as String)
          : null,
      ward: json['ward'] as String? ?? 'Ward 45, Urban Central',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      geohash: json['geohash'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
