// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'near_duplicate_candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NearDuplicateCandidate {

 int get id; String get title; String get category; String get status; double get latitude; double get longitude;@JsonKey(name: 'distance_meters') double get distanceMeters;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of NearDuplicateCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NearDuplicateCandidateCopyWith<NearDuplicateCandidate> get copyWith => _$NearDuplicateCandidateCopyWithImpl<NearDuplicateCandidate>(this as NearDuplicateCandidate, _$identity);

  /// Serializes this NearDuplicateCandidate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NearDuplicateCandidate&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,status,latitude,longitude,distanceMeters,createdAt);

@override
String toString() {
  return 'NearDuplicateCandidate(id: $id, title: $title, category: $category, status: $status, latitude: $latitude, longitude: $longitude, distanceMeters: $distanceMeters, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $NearDuplicateCandidateCopyWith<$Res>  {
  factory $NearDuplicateCandidateCopyWith(NearDuplicateCandidate value, $Res Function(NearDuplicateCandidate) _then) = _$NearDuplicateCandidateCopyWithImpl;
@useResult
$Res call({
 int id, String title, String category, String status, double latitude, double longitude,@JsonKey(name: 'distance_meters') double distanceMeters,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$NearDuplicateCandidateCopyWithImpl<$Res>
    implements $NearDuplicateCandidateCopyWith<$Res> {
  _$NearDuplicateCandidateCopyWithImpl(this._self, this._then);

  final NearDuplicateCandidate _self;
  final $Res Function(NearDuplicateCandidate) _then;

/// Create a copy of NearDuplicateCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? category = null,Object? status = null,Object? latitude = null,Object? longitude = null,Object? distanceMeters = null,Object? createdAt = null,}) {
  return _then(NearDuplicateCandidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [NearDuplicateCandidate].
extension NearDuplicateCandidatePatterns on NearDuplicateCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NearDuplicateCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NearDuplicateCandidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NearDuplicateCandidate value)  $default,){
final _that = this;
switch (_that) {
case _NearDuplicateCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NearDuplicateCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _NearDuplicateCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String category,  String status,  double latitude,  double longitude, @JsonKey(name: 'distance_meters')  double distanceMeters, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NearDuplicateCandidate() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.status,_that.latitude,_that.longitude,_that.distanceMeters,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String category,  String status,  double latitude,  double longitude, @JsonKey(name: 'distance_meters')  double distanceMeters, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _NearDuplicateCandidate():
return $default(_that.id,_that.title,_that.category,_that.status,_that.latitude,_that.longitude,_that.distanceMeters,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String category,  String status,  double latitude,  double longitude, @JsonKey(name: 'distance_meters')  double distanceMeters, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _NearDuplicateCandidate() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.status,_that.latitude,_that.longitude,_that.distanceMeters,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NearDuplicateCandidate implements NearDuplicateCandidate {
  const _NearDuplicateCandidate({required this.id, required this.title, required this.category, required this.status, required this.latitude, required this.longitude, @JsonKey(name: 'distance_meters') required this.distanceMeters, @JsonKey(name: 'created_at') required this.createdAt});
  factory _NearDuplicateCandidate.fromJson(Map<String, dynamic> json) => _$NearDuplicateCandidateFromJson(json);

@override final  int id;
@override final  String title;
@override final  String category;
@override final  String status;
@override final  double latitude;
@override final  double longitude;
@override@JsonKey(name: 'distance_meters') final  double distanceMeters;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of NearDuplicateCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NearDuplicateCandidateCopyWith<_NearDuplicateCandidate> get copyWith => __$NearDuplicateCandidateCopyWithImpl<_NearDuplicateCandidate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NearDuplicateCandidateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NearDuplicateCandidate&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,status,latitude,longitude,distanceMeters,createdAt);

@override
String toString() {
  return 'NearDuplicateCandidate(id: $id, title: $title, category: $category, status: $status, latitude: $latitude, longitude: $longitude, distanceMeters: $distanceMeters, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$NearDuplicateCandidateCopyWith<$Res> implements $NearDuplicateCandidateCopyWith<$Res> {
  factory _$NearDuplicateCandidateCopyWith(_NearDuplicateCandidate value, $Res Function(_NearDuplicateCandidate) _then) = __$NearDuplicateCandidateCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String category, String status, double latitude, double longitude,@JsonKey(name: 'distance_meters') double distanceMeters,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$NearDuplicateCandidateCopyWithImpl<$Res>
    implements _$NearDuplicateCandidateCopyWith<$Res> {
  __$NearDuplicateCandidateCopyWithImpl(this._self, this._then);

  final _NearDuplicateCandidate _self;
  final $Res Function(_NearDuplicateCandidate) _then;

/// Create a copy of NearDuplicateCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? category = null,Object? status = null,Object? latitude = null,Object? longitude = null,Object? distanceMeters = null,Object? createdAt = null,}) {
  return _then(_NearDuplicateCandidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
