import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue.freezed.dart';
part 'issue.g.dart';

@freezed
abstract class AssignedAuthority with _$AssignedAuthority {
  const factory AssignedAuthority({
    required String id,
    @JsonKey(name: 'official_name') required String officialName,
    required String title,
    required String ward,
    @Default('all') String department,
    String? handle,
    @JsonKey(name: 'is_unclaimed') @Default(false) bool isUnclaimed,
    @JsonKey(name: 'is_verified') @Default(true) bool isVerified,
    @JsonKey(name: 'contact_email') String? contactEmail,
    @JsonKey(name: 'contact_phone') String? contactPhone,
  }) = _AssignedAuthority;

  factory AssignedAuthority.fromJson(Map<String, Object?> json) =>
      _$AssignedAuthorityFromJson(json);
}

@freezed
abstract class QuorumVoter with _$QuorumVoter {
  const factory QuorumVoter({
    @JsonKey(name: 'user_id') required int userId,
    String? username,
    @JsonKey(name: 'display_name') String? displayName,
    required String vote,
    String? reason,
    @JsonKey(name: 'is_verified_nearby') @Default(true) bool isVerifiedNearby,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _QuorumVoter;

  factory QuorumVoter.fromJson(Map<String, Object?> json) =>
      _$QuorumVoterFromJson(json);
}

@freezed
abstract class IssueTimelineEvent with _$IssueTimelineEvent {
  const factory IssueTimelineEvent({
    @JsonKey(name: 'event_type') required String eventType,
    required String title,
    required String description,
    required DateTime timestamp,
    String? actor,
    @JsonKey(name: 'actor_role') String? actorRole,
    @JsonKey(name: 'media_url') String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) = _IssueTimelineEvent;

  factory IssueTimelineEvent.fromJson(Map<String, Object?> json) =>
      _$IssueTimelineEventFromJson(json);
}

@freezed
abstract class IssueTimelineData with _$IssueTimelineData {
  const factory IssueTimelineData({
    @JsonKey(name: 'issue_id') required int issueId,
    required String status,
    @Default(<IssueTimelineEvent>[]) List<IssueTimelineEvent> events,
    @Default(<QuorumVoter>[]) List<QuorumVoter> confirmations,
    @Default(<QuorumVoter>[]) List<QuorumVoter> disputes,
  }) = _IssueTimelineData;

  factory IssueTimelineData.fromJson(Map<String, Object?> json) =>
      _$IssueTimelineDataFromJson(json);
}

@freezed
abstract class Issue with _$Issue {
  const factory Issue({
    required int id,
    required String title,
    required String description,
    required String category,
    required String status,
    required double latitude,
    required double longitude,
    String? geohash,
    @Default('Ward 45, Urban Central') String ward,
    @JsonKey(name: 'is_anonymous') required bool isAnonymous,
    @JsonKey(name: 'is_fuzzed') @Default(false) bool isFuzzed,
    @JsonKey(name: 'is_shielded') @Default(false) bool isShielded,
    @JsonKey(name: 'reporter_label') required String reporterLabel,
    @JsonKey(name: 'reporter_name') String? reporterName,
    @JsonKey(name: 'reporter_photo_url') String? reporterPhotoUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'acknowledged_at') DateTime? acknowledgedAt,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'resolution_proof') String? resolutionProof,
    @JsonKey(name: 'resolution_notes') String? resolutionNotes,
    @JsonKey(name: 'upvotes_count') @Default(0) int upvotesCount,
    @JsonKey(name: 'confirmations_count') @Default(0) int confirmationsCount,
    @JsonKey(name: 'disputes_count') @Default(0) int disputesCount,
    @JsonKey(name: 'has_upvoted') @Default(false) bool hasUpvoted,
    @JsonKey(name: 'media_urls') @Default(<String>[]) List<String> mediaUrls,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'reporter_id') int? reporterId,
    @JsonKey(name: 'assigned_representative') AssignedAuthority? assignedRepresentative,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
    @JsonKey(name: 'resolution_type') String? resolutionType,
  }) = _Issue;

  const Issue._();

  factory Issue.fromJson(Map<String, Object?> json) => _$IssueFromJson(json);

  bool get isResolved => status == 'resolved';
  bool get isPendingQuorum => status == 'pending_quorum';
  bool get isEscalating => status == 'escalating';
  bool get isForwarded => status == 'forwarded';
  bool get isUnacknowledged => status == 'unacknowledged';
}
