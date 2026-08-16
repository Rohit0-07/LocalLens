// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Issue _$IssueFromJson(Map<String, dynamic> json) => _Issue(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  status: json['status'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  geohash: json['geohash'] as String?,
  ward: json['ward'] as String? ?? 'Ward 45, Urban Central',
  isAnonymous: json['is_anonymous'] as bool,
  isFuzzed: json['is_fuzzed'] as bool? ?? false,
  isShielded: json['is_shielded'] as bool? ?? false,
  reporterLabel: json['reporter_label'] as String,
  reporterName: json['reporter_name'] as String?,
  reporterPhotoUrl: json['reporter_photo_url'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  acknowledgedAt: json['acknowledged_at'] == null
      ? null
      : DateTime.parse(json['acknowledged_at'] as String),
  resolvedAt: json['resolved_at'] == null
      ? null
      : DateTime.parse(json['resolved_at'] as String),
  resolutionProof: json['resolution_proof'] as String?,
  resolutionNotes: json['resolution_notes'] as String?,
  upvotesCount: (json['upvotes_count'] as num?)?.toInt() ?? 0,
  confirmationsCount: (json['confirmations_count'] as num?)?.toInt() ?? 0,
  disputesCount: (json['disputes_count'] as num?)?.toInt() ?? 0,
  hasUpvoted: json['has_upvoted'] as bool? ?? false,
  mediaUrls:
      (json['media_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  videoUrl: json['video_url'] as String?,
  reporterId: (json['reporter_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$IssueToJson(_Issue instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'category': instance.category,
  'status': instance.status,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'geohash': instance.geohash,
  'ward': instance.ward,
  'is_anonymous': instance.isAnonymous,
  'is_fuzzed': instance.isFuzzed,
  'is_shielded': instance.isShielded,
  'reporter_label': instance.reporterLabel,
  'reporter_name': instance.reporterName,
  'reporter_photo_url': instance.reporterPhotoUrl,
  'created_at': instance.createdAt.toIso8601String(),
  'acknowledged_at': instance.acknowledgedAt?.toIso8601String(),
  'resolved_at': instance.resolvedAt?.toIso8601String(),
  'resolution_proof': instance.resolutionProof,
  'resolution_notes': instance.resolutionNotes,
  'upvotes_count': instance.upvotesCount,
  'confirmations_count': instance.confirmationsCount,
  'disputes_count': instance.disputesCount,
  'has_upvoted': instance.hasUpvoted,
  'media_urls': instance.mediaUrls,
  'video_url': instance.videoUrl,
  'reporter_id': instance.reporterId,
};
