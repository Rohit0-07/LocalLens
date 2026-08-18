// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captured_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CapturedMedia _$CapturedMediaFromJson(Map<String, dynamic> json) =>
    _CapturedMedia(
      id: json['id'] as String? ?? '',
      bytesBase64: json['bytesBase64'] as String? ?? '',
      capturedLat: (json['capturedLat'] as num?)?.toDouble(),
      capturedLng: (json['capturedLng'] as num?)?.toDouble(),
      capturedAt: json['capturedAt'] == null
          ? null
          : DateTime.parse(json['capturedAt'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
      remoteMediaId: json['remoteMediaId'] as String?,
    );

Map<String, dynamic> _$CapturedMediaToJson(_CapturedMedia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bytesBase64': instance.bytesBase64,
      'capturedLat': instance.capturedLat,
      'capturedLng': instance.capturedLng,
      'capturedAt': instance.capturedAt?.toIso8601String(),
      'isVerified': instance.isVerified,
      'remoteMediaId': instance.remoteMediaId,
    };
