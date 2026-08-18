// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'captured_media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CapturedMedia {

 String get id; String get bytesBase64; double? get capturedLat; double? get capturedLng; DateTime? get capturedAt; bool get isVerified; String? get remoteMediaId;
/// Create a copy of CapturedMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapturedMediaCopyWith<CapturedMedia> get copyWith => _$CapturedMediaCopyWithImpl<CapturedMedia>(this as CapturedMedia, _$identity);

  /// Serializes this CapturedMedia to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapturedMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.bytesBase64, bytesBase64) || other.bytesBase64 == bytesBase64)&&(identical(other.capturedLat, capturedLat) || other.capturedLat == capturedLat)&&(identical(other.capturedLng, capturedLng) || other.capturedLng == capturedLng)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.remoteMediaId, remoteMediaId) || other.remoteMediaId == remoteMediaId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bytesBase64,capturedLat,capturedLng,capturedAt,isVerified,remoteMediaId);

@override
String toString() {
  return 'CapturedMedia(id: $id, bytesBase64: $bytesBase64, capturedLat: $capturedLat, capturedLng: $capturedLng, capturedAt: $capturedAt, isVerified: $isVerified, remoteMediaId: $remoteMediaId)';
}


}

/// @nodoc
abstract mixin class $CapturedMediaCopyWith<$Res>  {
  factory $CapturedMediaCopyWith(CapturedMedia value, $Res Function(CapturedMedia) _then) = _$CapturedMediaCopyWithImpl;
@useResult
$Res call({
 String id, String bytesBase64, double? capturedLat, double? capturedLng, DateTime? capturedAt, bool isVerified, String? remoteMediaId
});




}
/// @nodoc
class _$CapturedMediaCopyWithImpl<$Res>
    implements $CapturedMediaCopyWith<$Res> {
  _$CapturedMediaCopyWithImpl(this._self, this._then);

  final CapturedMedia _self;
  final $Res Function(CapturedMedia) _then;

/// Create a copy of CapturedMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bytesBase64 = null,Object? capturedLat = freezed,Object? capturedLng = freezed,Object? capturedAt = freezed,Object? isVerified = null,Object? remoteMediaId = freezed,}) {
  return _then(CapturedMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bytesBase64: null == bytesBase64 ? _self.bytesBase64 : bytesBase64 // ignore: cast_nullable_to_non_nullable
as String,capturedLat: freezed == capturedLat ? _self.capturedLat : capturedLat // ignore: cast_nullable_to_non_nullable
as double?,capturedLng: freezed == capturedLng ? _self.capturedLng : capturedLng // ignore: cast_nullable_to_non_nullable
as double?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,remoteMediaId: freezed == remoteMediaId ? _self.remoteMediaId : remoteMediaId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CapturedMedia].
extension CapturedMediaPatterns on CapturedMedia {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapturedMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapturedMedia() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapturedMedia value)  $default,){
final _that = this;
switch (_that) {
case _CapturedMedia():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapturedMedia value)?  $default,){
final _that = this;
switch (_that) {
case _CapturedMedia() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bytesBase64,  double? capturedLat,  double? capturedLng,  DateTime? capturedAt,  bool isVerified,  String? remoteMediaId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapturedMedia() when $default != null:
return $default(_that.id,_that.bytesBase64,_that.capturedLat,_that.capturedLng,_that.capturedAt,_that.isVerified,_that.remoteMediaId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bytesBase64,  double? capturedLat,  double? capturedLng,  DateTime? capturedAt,  bool isVerified,  String? remoteMediaId)  $default,) {final _that = this;
switch (_that) {
case _CapturedMedia():
return $default(_that.id,_that.bytesBase64,_that.capturedLat,_that.capturedLng,_that.capturedAt,_that.isVerified,_that.remoteMediaId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bytesBase64,  double? capturedLat,  double? capturedLng,  DateTime? capturedAt,  bool isVerified,  String? remoteMediaId)?  $default,) {final _that = this;
switch (_that) {
case _CapturedMedia() when $default != null:
return $default(_that.id,_that.bytesBase64,_that.capturedLat,_that.capturedLng,_that.capturedAt,_that.isVerified,_that.remoteMediaId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CapturedMedia extends CapturedMedia {
  const _CapturedMedia({this.id = '', this.bytesBase64 = '', this.capturedLat, this.capturedLng, this.capturedAt, this.isVerified = false, this.remoteMediaId}): super._();
  factory _CapturedMedia.fromJson(Map<String, dynamic> json) => _$CapturedMediaFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String bytesBase64;
@override final  double? capturedLat;
@override final  double? capturedLng;
@override final  DateTime? capturedAt;
@override@JsonKey() final  bool isVerified;
@override final  String? remoteMediaId;

/// Create a copy of CapturedMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapturedMediaCopyWith<_CapturedMedia> get copyWith => __$CapturedMediaCopyWithImpl<_CapturedMedia>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CapturedMediaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapturedMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.bytesBase64, bytesBase64) || other.bytesBase64 == bytesBase64)&&(identical(other.capturedLat, capturedLat) || other.capturedLat == capturedLat)&&(identical(other.capturedLng, capturedLng) || other.capturedLng == capturedLng)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.remoteMediaId, remoteMediaId) || other.remoteMediaId == remoteMediaId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bytesBase64,capturedLat,capturedLng,capturedAt,isVerified,remoteMediaId);

@override
String toString() {
  return 'CapturedMedia(id: $id, bytesBase64: $bytesBase64, capturedLat: $capturedLat, capturedLng: $capturedLng, capturedAt: $capturedAt, isVerified: $isVerified, remoteMediaId: $remoteMediaId)';
}


}

/// @nodoc
abstract mixin class _$CapturedMediaCopyWith<$Res> implements $CapturedMediaCopyWith<$Res> {
  factory _$CapturedMediaCopyWith(_CapturedMedia value, $Res Function(_CapturedMedia) _then) = __$CapturedMediaCopyWithImpl;
@override @useResult
$Res call({
 String id, String bytesBase64, double? capturedLat, double? capturedLng, DateTime? capturedAt, bool isVerified, String? remoteMediaId
});




}
/// @nodoc
class __$CapturedMediaCopyWithImpl<$Res>
    implements _$CapturedMediaCopyWith<$Res> {
  __$CapturedMediaCopyWithImpl(this._self, this._then);

  final _CapturedMedia _self;
  final $Res Function(_CapturedMedia) _then;

/// Create a copy of CapturedMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bytesBase64 = null,Object? capturedLat = freezed,Object? capturedLng = freezed,Object? capturedAt = freezed,Object? isVerified = null,Object? remoteMediaId = freezed,}) {
  return _then(_CapturedMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bytesBase64: null == bytesBase64 ? _self.bytesBase64 : bytesBase64 // ignore: cast_nullable_to_non_nullable
as String,capturedLat: freezed == capturedLat ? _self.capturedLat : capturedLat // ignore: cast_nullable_to_non_nullable
as double?,capturedLng: freezed == capturedLng ? _self.capturedLng : capturedLng // ignore: cast_nullable_to_non_nullable
as double?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,remoteMediaId: freezed == remoteMediaId ? _self.remoteMediaId : remoteMediaId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
