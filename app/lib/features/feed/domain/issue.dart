import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue.freezed.dart';
part 'issue.g.dart';

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
  }) = _Issue;

  const Issue._();

  factory Issue.fromJson(Map<String, Object?> json) => _$IssueFromJson(json);

  bool get isResolved => status == 'resolved';
  bool get isPendingQuorum => status == 'pending_quorum';
  bool get isEscalating => status == 'escalating';
  bool get isForwarded => status == 'forwarded';
  bool get isUnacknowledged => status == 'unacknowledged';
}
