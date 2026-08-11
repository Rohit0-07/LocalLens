class LocalTalkPost {
  final int id;
  final String wardSlug;
  final String authorName;
  final String title;
  final String body;
  final String topic;
  final int repliesCount;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const LocalTalkPost({
    required this.id,
    required this.wardSlug,
    required this.authorName,
    required this.title,
    required this.body,
    required this.topic,
    required this.repliesCount,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory LocalTalkPost.fromJson(Map<String, dynamic> json) {
    return LocalTalkPost(
      id: (json['id'] as num).toInt(),
      wardSlug: json['ward_slug'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Local Citizen',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      topic: json['topic'] as String? ?? 'General',
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ward_slug': wardSlug,
      'author_name': authorName,
      'title': title,
      'body': body,
      'topic': topic,
      'replies_count': repliesCount,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
