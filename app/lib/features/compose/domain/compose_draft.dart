import 'package:freezed_annotation/freezed_annotation.dart';

part 'compose_draft.freezed.dart';
part 'compose_draft.g.dart';

@freezed
abstract class ComposeDraft with _$ComposeDraft {
  const factory ComposeDraft({
    @Default('') String id,
    @Default('') String title,
    @Default('') String description,
    @Default('road') String category,
    @Default(false) bool isAnonymous,
    @Default(false) bool isFuzzed,
    @Default(false) bool isShielded,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(<String>[]) List<String> mediaBytes,
  }) = _ComposeDraft;

  const ComposeDraft._();

  factory ComposeDraft.fromJson(Map<String, Object?> json) =>
      _$ComposeDraftFromJson(json);

  bool get hasContent => title.isNotEmpty || description.isNotEmpty;

  bool get hasMedia => mediaBytes.isNotEmpty;

  int get mediaCount => mediaBytes.length;
}
