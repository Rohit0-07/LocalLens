class WinItem {
  final int id;
  final int issueId;
  final String title;
  final String description;
  final String category;
  final String ward;
  final double latitude;
  final double longitude;
  final String? geohash;
  final String? beforeImageUrl;
  final String? afterImageUrl;
  final List<String> contributorCredits;
  final DateTime createdAt;

  const WinItem({
    required this.id,
    required this.issueId,
    required this.title,
    required this.description,
    required this.category,
    required this.ward,
    required this.latitude,
    required this.longitude,
    this.geohash,
    this.beforeImageUrl,
    this.afterImageUrl,
    required this.contributorCredits,
    required this.createdAt,
  });

  factory WinItem.fromJson(Map<String, dynamic> json) {
    return WinItem(
      id: (json['id'] as num).toInt(),
      issueId: (json['issue_id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      ward: json['ward'] as String? ?? 'Ward 45, Urban Central',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      geohash: json['geohash'] as String?,
      beforeImageUrl: json['before_image_url'] as String?,
      afterImageUrl: json['after_image_url'] as String?,
      contributorCredits: (json['contributor_credits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
