import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
abstract class Session with _$Session {
  const factory Session({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'user_id') required Object userId,
    @JsonKey(name: 'anon_id') String? anonId,
    @JsonKey(name: 'is_guest') @Default(false) bool isGuest,
  }) = _Session;

  factory Session.fromJson(Map<String, Object?> json) =>
      _$SessionFromJson(json);
}
