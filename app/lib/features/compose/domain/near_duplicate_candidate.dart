import 'package:freezed_annotation/freezed_annotation.dart';

part 'near_duplicate_candidate.freezed.dart';
part 'near_duplicate_candidate.g.dart';

@freezed
abstract class NearDuplicateCandidate with _$NearDuplicateCandidate {
  const factory NearDuplicateCandidate({
    required int id,
    required String title,
    required String category,
    required String status,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'distance_meters') required double distanceMeters,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _NearDuplicateCandidate;

  factory NearDuplicateCandidate.fromJson(Map<String, Object?> json) =>
      _$NearDuplicateCandidateFromJson(json);
}
