// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compose_draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ComposeDraft _$ComposeDraftFromJson(Map<String, dynamic> json) =>
    _ComposeDraft(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'road',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isFuzzed: json['isFuzzed'] as bool? ?? false,
      isShielded: json['isShielded'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ComposeDraftToJson(_ComposeDraft instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'isAnonymous': instance.isAnonymous,
      'isFuzzed': instance.isFuzzed,
      'isShielded': instance.isShielded,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
