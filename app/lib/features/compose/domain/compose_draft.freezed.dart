// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compose_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComposeDraft {

 String get id; String get title; String get description; String get category; bool get isAnonymous; bool get isFuzzed; bool get isShielded; double? get latitude; double? get longitude; DateTime? get createdAt; DateTime? get updatedAt; List<CapturedMedia> get media;
/// Create a copy of ComposeDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComposeDraftCopyWith<ComposeDraft> get copyWith => _$ComposeDraftCopyWithImpl<ComposeDraft>(this as ComposeDraft, _$identity);

  /// Serializes this ComposeDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComposeDraft&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.isFuzzed, isFuzzed) || other.isFuzzed == isFuzzed)&&(identical(other.isShielded, isShielded) || other.isShielded == isShielded)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.media, media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,category,isAnonymous,isFuzzed,isShielded,latitude,longitude,createdAt,updatedAt,const DeepCollectionEquality().hash(media));

@override
String toString() {
  return 'ComposeDraft(id: $id, title: $title, description: $description, category: $category, isAnonymous: $isAnonymous, isFuzzed: $isFuzzed, isShielded: $isShielded, latitude: $latitude, longitude: $longitude, createdAt: $createdAt, updatedAt: $updatedAt, media: $media)';
}


}

/// @nodoc
abstract mixin class $ComposeDraftCopyWith<$Res>  {
  factory $ComposeDraftCopyWith(ComposeDraft value, $Res Function(ComposeDraft) _then) = _$ComposeDraftCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String category, bool isAnonymous, bool isFuzzed, bool isShielded, double? latitude, double? longitude, DateTime? createdAt, DateTime? updatedAt, List<CapturedMedia> media
});




}
/// @nodoc
class _$ComposeDraftCopyWithImpl<$Res>
    implements $ComposeDraftCopyWith<$Res> {
  _$ComposeDraftCopyWithImpl(this._self, this._then);

  final ComposeDraft _self;
  final $Res Function(ComposeDraft) _then;

/// Create a copy of ComposeDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? isAnonymous = null,Object? isFuzzed = null,Object? isShielded = null,Object? latitude = freezed,Object? longitude = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? media = null,}) {
  return _then(ComposeDraft(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,isFuzzed: null == isFuzzed ? _self.isFuzzed : isFuzzed // ignore: cast_nullable_to_non_nullable
as bool,isShielded: null == isShielded ? _self.isShielded : isShielded // ignore: cast_nullable_to_non_nullable
as bool,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<CapturedMedia>,
  ));
}

}


/// Adds pattern-matching-related methods to [ComposeDraft].
extension ComposeDraftPatterns on ComposeDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComposeDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComposeDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComposeDraft value)  $default,){
final _that = this;
switch (_that) {
case _ComposeDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComposeDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ComposeDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String category,  bool isAnonymous,  bool isFuzzed,  bool isShielded,  double? latitude,  double? longitude,  DateTime? createdAt,  DateTime? updatedAt,  List<CapturedMedia> media)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComposeDraft() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.isAnonymous,_that.isFuzzed,_that.isShielded,_that.latitude,_that.longitude,_that.createdAt,_that.updatedAt,_that.media);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String category,  bool isAnonymous,  bool isFuzzed,  bool isShielded,  double? latitude,  double? longitude,  DateTime? createdAt,  DateTime? updatedAt,  List<CapturedMedia> media)  $default,) {final _that = this;
switch (_that) {
case _ComposeDraft():
return $default(_that.id,_that.title,_that.description,_that.category,_that.isAnonymous,_that.isFuzzed,_that.isShielded,_that.latitude,_that.longitude,_that.createdAt,_that.updatedAt,_that.media);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String category,  bool isAnonymous,  bool isFuzzed,  bool isShielded,  double? latitude,  double? longitude,  DateTime? createdAt,  DateTime? updatedAt,  List<CapturedMedia> media)?  $default,) {final _that = this;
switch (_that) {
case _ComposeDraft() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.isAnonymous,_that.isFuzzed,_that.isShielded,_that.latitude,_that.longitude,_that.createdAt,_that.updatedAt,_that.media);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComposeDraft extends ComposeDraft {
  const _ComposeDraft({this.id = '', this.title = '', this.description = '', this.category = 'road', this.isAnonymous = false, this.isFuzzed = false, this.isShielded = false, this.latitude, this.longitude, this.createdAt, this.updatedAt,  List<CapturedMedia> media = const <CapturedMedia>[]}): _media = media,super._();
  factory _ComposeDraft.fromJson(Map<String, dynamic> json) => _$ComposeDraftFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  String category;
@override@JsonKey() final  bool isAnonymous;
@override@JsonKey() final  bool isFuzzed;
@override@JsonKey() final  bool isShielded;
@override final  double? latitude;
@override final  double? longitude;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
 final  List<CapturedMedia> _media;
@override@JsonKey() List<CapturedMedia> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}


/// Create a copy of ComposeDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComposeDraftCopyWith<_ComposeDraft> get copyWith => __$ComposeDraftCopyWithImpl<_ComposeDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComposeDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComposeDraft&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.isFuzzed, isFuzzed) || other.isFuzzed == isFuzzed)&&(identical(other.isShielded, isShielded) || other.isShielded == isShielded)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._media, _media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,category,isAnonymous,isFuzzed,isShielded,latitude,longitude,createdAt,updatedAt,const DeepCollectionEquality().hash(_media));

@override
String toString() {
  return 'ComposeDraft(id: $id, title: $title, description: $description, category: $category, isAnonymous: $isAnonymous, isFuzzed: $isFuzzed, isShielded: $isShielded, latitude: $latitude, longitude: $longitude, createdAt: $createdAt, updatedAt: $updatedAt, media: $media)';
}


}

/// @nodoc
abstract mixin class _$ComposeDraftCopyWith<$Res> implements $ComposeDraftCopyWith<$Res> {
  factory _$ComposeDraftCopyWith(_ComposeDraft value, $Res Function(_ComposeDraft) _then) = __$ComposeDraftCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String category, bool isAnonymous, bool isFuzzed, bool isShielded, double? latitude, double? longitude, DateTime? createdAt, DateTime? updatedAt, List<CapturedMedia> media
});




}
/// @nodoc
class __$ComposeDraftCopyWithImpl<$Res>
    implements _$ComposeDraftCopyWith<$Res> {
  __$ComposeDraftCopyWithImpl(this._self, this._then);

  final _ComposeDraft _self;
  final $Res Function(_ComposeDraft) _then;

/// Create a copy of ComposeDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? isAnonymous = null,Object? isFuzzed = null,Object? isShielded = null,Object? latitude = freezed,Object? longitude = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? media = null,}) {
  return _then(_ComposeDraft(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,isFuzzed: null == isFuzzed ? _self.isFuzzed : isFuzzed // ignore: cast_nullable_to_non_nullable
as bool,isShielded: null == isShielded ? _self.isShielded : isShielded // ignore: cast_nullable_to_non_nullable
as bool,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<CapturedMedia>,
  ));
}


}

// dart format on
