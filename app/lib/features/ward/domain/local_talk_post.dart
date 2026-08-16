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
  final List<String> mediaUrls;
  final String? imageUrl;
  final String? videoUrl;
  final int? authorId;

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
    this.mediaUrls = const <String>[],
    this.imageUrl,
    this.videoUrl,
    this.authorId,
  });

  factory LocalTalkPost.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media_urls'] as List<dynamic>?;
    final mediaList = rawMedia?.map((e) => e.toString()).toList() ?? const <String>[];
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
      mediaUrls: mediaList,
      imageUrl: json['image_url'] as String? ?? (json['image'] as String?),
      videoUrl: json['video_url'] as String?,
      authorId: (json['author_id'] ?? json['user_id'] as num?)?.toInt(),
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
      'media_urls': mediaUrls,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
    };
  }
}
