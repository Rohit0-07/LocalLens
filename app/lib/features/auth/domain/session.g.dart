// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Session _$SessionFromJson(Map<String, dynamic> json) => _Session(
  accessToken: json['access_token'] as String,
  userId: json['user_id'] as Object,
  anonId: json['anon_id'] as String?,
  isGuest: json['is_guest'] as bool? ?? false,
);

Map<String, dynamic> _$SessionToJson(_Session instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'user_id': instance.userId,
  'anon_id': instance.anonId,
  'is_guest': instance.isGuest,
};
