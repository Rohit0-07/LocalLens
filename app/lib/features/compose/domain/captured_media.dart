import 'package:freezed_annotation/freezed_annotation.dart';

part 'captured_media.freezed.dart';
part 'captured_media.g.dart';

/// A photo captured through the in-app camera, persisted to the local
/// captured-media library (Hive) and optionally attached to a compose draft.
@freezed
abstract class CapturedMedia with _$CapturedMedia {
  const factory CapturedMedia({
    @Default('') String id,
    @Default('') String bytesBase64,
    double? capturedLat,
    double? capturedLng,
    DateTime? capturedAt,
    @Default(false) bool isVerified,
    String? remoteMediaId,
  }) = _CapturedMedia;

  const CapturedMedia._();

  factory CapturedMedia.fromJson(Map<String, Object?> json) =>
      _$CapturedMediaFromJson(json);

  bool get hasGps => capturedLat != null && capturedLng != null;
}