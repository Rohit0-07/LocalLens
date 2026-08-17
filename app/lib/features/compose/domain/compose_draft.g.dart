// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compose_draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ComposeDraft _$ComposeDraftFromJson(Map<String, dynamic> json) =>
    _ComposeDraft(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'road',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isFuzzed: json['isFuzzed'] as bool? ?? false,
      isShielded: json['isShielded'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      mediaBytes:
          (json['mediaBytes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$ComposeDraftToJson(_ComposeDraft instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'isAnonymous': instance.isAnonymous,
      'isFuzzed': instance.isFuzzed,
      'isShielded': instance.isShielded,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'mediaBytes': instance.mediaBytes,
    };
