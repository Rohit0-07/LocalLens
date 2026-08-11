// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'near_duplicate_candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NearDuplicateCandidate _$NearDuplicateCandidateFromJson(
  Map<String, dynamic> json,
) => _NearDuplicateCandidate(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  category: json['category'] as String,
  status: json['status'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  distanceMeters: (json['distance_meters'] as num).toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$NearDuplicateCandidateToJson(
  _NearDuplicateCandidate instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'category': instance.category,
  'status': instance.status,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'distance_meters': instance.distanceMeters,
  'created_at': instance.createdAt.toIso8601String(),
};
