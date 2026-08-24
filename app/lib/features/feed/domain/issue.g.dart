// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssignedAuthority _$AssignedAuthorityFromJson(Map<String, dynamic> json) =>
    _AssignedAuthority(
      id: json['id'] as String,
      officialName: json['official_name'] as String,
      title: json['title'] as String,
      ward: json['ward'] as String,
      department: json['department'] as String? ?? 'all',
      handle: json['handle'] as String?,
      isUnclaimed: json['is_unclaimed'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? true,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
    );

Map<String, dynamic> _$AssignedAuthorityToJson(_AssignedAuthority instance) =>
    <String, dynamic>{
      'id': instance.id,
      'official_name': instance.officialName,
      'title': instance.title,
      'ward': instance.ward,
      'department': instance.department,
      'handle': instance.handle,
      'is_unclaimed': instance.isUnclaimed,
      'is_verified': instance.isVerified,
      'contact_email': instance.contactEmail,
      'contact_phone': instance.contactPhone,
    };

_QuorumVoter _$QuorumVoterFromJson(Map<String, dynamic> json) => _QuorumVoter(
  userId: (json['user_id'] as num).toInt(),
  username: json['username'] as String?,
  displayName: json['display_name'] as String?,
  vote: json['vote'] as String,
  reason: json['reason'] as String?,
  isVerifiedNearby: json['is_nearby'] as bool? ?? true,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$QuorumVoterToJson(_QuorumVoter instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'username': instance.username,
      'display_name': instance.displayName,
      'vote': instance.vote,
      'reason': instance.reason,
      'is_nearby': instance.isVerifiedNearby,
      'created_at': instance.createdAt.toIso8601String(),
    };

_IssueTimelineEvent _$IssueTimelineEventFromJson(Map<String, dynamic> json) =>
    _IssueTimelineEvent(
      eventType: json['event_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      actorName: json['actor_name'] as String?,
      actorHandle: json['actor_handle'] as String?,
      actorRole: json['actor_role'] as String?,
      isUnclaimed: json['is_unclaimed'] as bool? ?? false,
      mediaUrl: json['media_url'] as String?,
    );

Map<String, dynamic> _$IssueTimelineEventToJson(_IssueTimelineEvent instance) =>
    <String, dynamic>{
      'event_type': instance.eventType,
      'title': instance.title,
      'description': instance.description,
      'created_at': instance.createdAt.toIso8601String(),
      'actor_name': instance.actorName,
      'actor_handle': instance.actorHandle,
      'actor_role': instance.actorRole,
      'is_unclaimed': instance.isUnclaimed,
      'media_url': instance.mediaUrl,
    };

_IssueTimelineData _$IssueTimelineDataFromJson(Map<String, dynamic> json) =>
    _IssueTimelineData(
      issueId: (json['issue_id'] as num).toInt(),
      status: json['status'] as String,
      events:
          (json['events'] as List<dynamic>?)
              ?.map(
                (e) => IssueTimelineEvent.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <IssueTimelineEvent>[],
      confirmations:
          (json['confirmations'] as List<dynamic>?)
              ?.map((e) => QuorumVoter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <QuorumVoter>[],
      disputes:
          (json['disputes'] as List<dynamic>?)
              ?.map((e) => QuorumVoter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <QuorumVoter>[],
    );

Map<String, dynamic> _$IssueTimelineDataToJson(_IssueTimelineData instance) =>
    <String, dynamic>{
      'issue_id': instance.issueId,
      'status': instance.status,
      'events': instance.events,
      'confirmations': instance.confirmations,
      'disputes': instance.disputes,
    };

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
  commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
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
  assignedRepresentative: json['assigned_representative'] == null
      ? null
      : AssignedAuthority.fromJson(
          json['assigned_representative'] as Map<String, dynamic>,
        ),
  resolvedBy: json['resolved_by'] as String?,
  resolutionType: json['resolution_type'] as String?,
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
  'comments_count': instance.commentsCount,
  'confirmations_count': instance.confirmationsCount,
  'disputes_count': instance.disputesCount,
  'has_upvoted': instance.hasUpvoted,
  'media_urls': instance.mediaUrls,
  'video_url': instance.videoUrl,
  'reporter_id': instance.reporterId,
  'assigned_representative': instance.assignedRepresentative,
  'resolved_by': instance.resolvedBy,
  'resolution_type': instance.resolutionType,
};
