// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssignedAuthority {

 String get id;@JsonKey(name: 'official_name') String get officialName; String get title; String get ward; String get department; String? get handle;@JsonKey(name: 'is_unclaimed') bool get isUnclaimed;@JsonKey(name: 'is_verified') bool get isVerified;@JsonKey(name: 'contact_email') String? get contactEmail;@JsonKey(name: 'contact_phone') String? get contactPhone;
/// Create a copy of AssignedAuthority
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssignedAuthorityCopyWith<AssignedAuthority> get copyWith => _$AssignedAuthorityCopyWithImpl<AssignedAuthority>(this as AssignedAuthority, _$identity);

  /// Serializes this AssignedAuthority to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignedAuthority&&(identical(other.id, id) || other.id == id)&&(identical(other.officialName, officialName) || other.officialName == officialName)&&(identical(other.title, title) || other.title == title)&&(identical(other.ward, ward) || other.ward == ward)&&(identical(other.department, department) || other.department == department)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.isUnclaimed, isUnclaimed) || other.isUnclaimed == isUnclaimed)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,officialName,title,ward,department,handle,isUnclaimed,isVerified,contactEmail,contactPhone);

@override
String toString() {
  return 'AssignedAuthority(id: $id, officialName: $officialName, title: $title, ward: $ward, department: $department, handle: $handle, isUnclaimed: $isUnclaimed, isVerified: $isVerified, contactEmail: $contactEmail, contactPhone: $contactPhone)';
}


}

/// @nodoc
abstract mixin class $AssignedAuthorityCopyWith<$Res>  {
  factory $AssignedAuthorityCopyWith(AssignedAuthority value, $Res Function(AssignedAuthority) _then) = _$AssignedAuthorityCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'official_name') String officialName, String title, String ward, String department, String? handle,@JsonKey(name: 'is_unclaimed') bool isUnclaimed,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'contact_phone') String? contactPhone
});




}
/// @nodoc
class _$AssignedAuthorityCopyWithImpl<$Res>
    implements $AssignedAuthorityCopyWith<$Res> {
  _$AssignedAuthorityCopyWithImpl(this._self, this._then);

  final AssignedAuthority _self;
  final $Res Function(AssignedAuthority) _then;

/// Create a copy of AssignedAuthority
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? officialName = null,Object? title = null,Object? ward = null,Object? department = null,Object? handle = freezed,Object? isUnclaimed = null,Object? isVerified = null,Object? contactEmail = freezed,Object? contactPhone = freezed,}) {
  return _then(AssignedAuthority(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,officialName: null == officialName ? _self.officialName : officialName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,ward: null == ward ? _self.ward : ward // ignore: cast_nullable_to_non_nullable
as String,department: null == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String,handle: freezed == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String?,isUnclaimed: null == isUnclaimed ? _self.isUnclaimed : isUnclaimed // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssignedAuthority].
extension AssignedAuthorityPatterns on AssignedAuthority {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssignedAuthority value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssignedAuthority() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssignedAuthority value)  $default,){
final _that = this;
switch (_that) {
case _AssignedAuthority():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssignedAuthority value)?  $default,){
final _that = this;
switch (_that) {
case _AssignedAuthority() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'official_name')  String officialName,  String title,  String ward,  String department,  String? handle, @JsonKey(name: 'is_unclaimed')  bool isUnclaimed, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'contact_phone')  String? contactPhone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssignedAuthority() when $default != null:
return $default(_that.id,_that.officialName,_that.title,_that.ward,_that.department,_that.handle,_that.isUnclaimed,_that.isVerified,_that.contactEmail,_that.contactPhone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'official_name')  String officialName,  String title,  String ward,  String department,  String? handle, @JsonKey(name: 'is_unclaimed')  bool isUnclaimed, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'contact_phone')  String? contactPhone)  $default,) {final _that = this;
switch (_that) {
case _AssignedAuthority():
return $default(_that.id,_that.officialName,_that.title,_that.ward,_that.department,_that.handle,_that.isUnclaimed,_that.isVerified,_that.contactEmail,_that.contactPhone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'official_name')  String officialName,  String title,  String ward,  String department,  String? handle, @JsonKey(name: 'is_unclaimed')  bool isUnclaimed, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'contact_email')  String? contactEmail, @JsonKey(name: 'contact_phone')  String? contactPhone)?  $default,) {final _that = this;
switch (_that) {
case _AssignedAuthority() when $default != null:
return $default(_that.id,_that.officialName,_that.title,_that.ward,_that.department,_that.handle,_that.isUnclaimed,_that.isVerified,_that.contactEmail,_that.contactPhone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssignedAuthority implements AssignedAuthority {
  const _AssignedAuthority({required this.id, @JsonKey(name: 'official_name') required this.officialName, required this.title, required this.ward, this.department = 'all', this.handle, @JsonKey(name: 'is_unclaimed') this.isUnclaimed = false, @JsonKey(name: 'is_verified') this.isVerified = true, @JsonKey(name: 'contact_email') this.contactEmail, @JsonKey(name: 'contact_phone') this.contactPhone});
  factory _AssignedAuthority.fromJson(Map<String, dynamic> json) => _$AssignedAuthorityFromJson(json);

@override final  String id;
@override@JsonKey(name: 'official_name') final  String officialName;
@override final  String title;
@override final  String ward;
@override@JsonKey() final  String department;
@override final  String? handle;
@override@JsonKey(name: 'is_unclaimed') final  bool isUnclaimed;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey(name: 'contact_email') final  String? contactEmail;
@override@JsonKey(name: 'contact_phone') final  String? contactPhone;

/// Create a copy of AssignedAuthority
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssignedAuthorityCopyWith<_AssignedAuthority> get copyWith => __$AssignedAuthorityCopyWithImpl<_AssignedAuthority>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssignedAuthorityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssignedAuthority&&(identical(other.id, id) || other.id == id)&&(identical(other.officialName, officialName) || other.officialName == officialName)&&(identical(other.title, title) || other.title == title)&&(identical(other.ward, ward) || other.ward == ward)&&(identical(other.department, department) || other.department == department)&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.isUnclaimed, isUnclaimed) || other.isUnclaimed == isUnclaimed)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,officialName,title,ward,department,handle,isUnclaimed,isVerified,contactEmail,contactPhone);

@override
String toString() {
  return 'AssignedAuthority(id: $id, officialName: $officialName, title: $title, ward: $ward, department: $department, handle: $handle, isUnclaimed: $isUnclaimed, isVerified: $isVerified, contactEmail: $contactEmail, contactPhone: $contactPhone)';
}


}

/// @nodoc
abstract mixin class _$AssignedAuthorityCopyWith<$Res> implements $AssignedAuthorityCopyWith<$Res> {
  factory _$AssignedAuthorityCopyWith(_AssignedAuthority value, $Res Function(_AssignedAuthority) _then) = __$AssignedAuthorityCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'official_name') String officialName, String title, String ward, String department, String? handle,@JsonKey(name: 'is_unclaimed') bool isUnclaimed,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'contact_email') String? contactEmail,@JsonKey(name: 'contact_phone') String? contactPhone
});




}
/// @nodoc
class __$AssignedAuthorityCopyWithImpl<$Res>
    implements _$AssignedAuthorityCopyWith<$Res> {
  __$AssignedAuthorityCopyWithImpl(this._self, this._then);

  final _AssignedAuthority _self;
  final $Res Function(_AssignedAuthority) _then;

/// Create a copy of AssignedAuthority
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? officialName = null,Object? title = null,Object? ward = null,Object? department = null,Object? handle = freezed,Object? isUnclaimed = null,Object? isVerified = null,Object? contactEmail = freezed,Object? contactPhone = freezed,}) {
  return _then(_AssignedAuthority(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,officialName: null == officialName ? _self.officialName : officialName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,ward: null == ward ? _self.ward : ward // ignore: cast_nullable_to_non_nullable
as String,department: null == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String,handle: freezed == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String?,isUnclaimed: null == isUnclaimed ? _self.isUnclaimed : isUnclaimed // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$QuorumVoter {

@JsonKey(name: 'user_id') int get userId; String? get username;@JsonKey(name: 'display_name') String? get displayName; String get vote; String? get reason;@JsonKey(name: 'is_verified_nearby') bool get isVerifiedNearby;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of QuorumVoter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuorumVoterCopyWith<QuorumVoter> get copyWith => _$QuorumVoterCopyWithImpl<QuorumVoter>(this as QuorumVoter, _$identity);

  /// Serializes this QuorumVoter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuorumVoter&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vote, vote) || other.vote == vote)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.isVerifiedNearby, isVerifiedNearby) || other.isVerifiedNearby == isVerifiedNearby)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username,displayName,vote,reason,isVerifiedNearby,createdAt);

@override
String toString() {
  return 'QuorumVoter(userId: $userId, username: $username, displayName: $displayName, vote: $vote, reason: $reason, isVerifiedNearby: $isVerifiedNearby, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $QuorumVoterCopyWith<$Res>  {
  factory $QuorumVoterCopyWith(QuorumVoter value, $Res Function(QuorumVoter) _then) = _$QuorumVoterCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') int userId, String? username,@JsonKey(name: 'display_name') String? displayName, String vote, String? reason,@JsonKey(name: 'is_verified_nearby') bool isVerifiedNearby,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$QuorumVoterCopyWithImpl<$Res>
    implements $QuorumVoterCopyWith<$Res> {
  _$QuorumVoterCopyWithImpl(this._self, this._then);

  final QuorumVoter _self;
  final $Res Function(QuorumVoter) _then;

/// Create a copy of QuorumVoter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? username = freezed,Object? displayName = freezed,Object? vote = null,Object? reason = freezed,Object? isVerifiedNearby = null,Object? createdAt = null,}) {
  return _then(QuorumVoter(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,vote: null == vote ? _self.vote : vote // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,isVerifiedNearby: null == isVerifiedNearby ? _self.isVerifiedNearby : isVerifiedNearby // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [QuorumVoter].
extension QuorumVoterPatterns on QuorumVoter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuorumVoter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuorumVoter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuorumVoter value)  $default,){
final _that = this;
switch (_that) {
case _QuorumVoter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuorumVoter value)?  $default,){
final _that = this;
switch (_that) {
case _QuorumVoter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  int userId,  String? username, @JsonKey(name: 'display_name')  String? displayName,  String vote,  String? reason, @JsonKey(name: 'is_verified_nearby')  bool isVerifiedNearby, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuorumVoter() when $default != null:
return $default(_that.userId,_that.username,_that.displayName,_that.vote,_that.reason,_that.isVerifiedNearby,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  int userId,  String? username, @JsonKey(name: 'display_name')  String? displayName,  String vote,  String? reason, @JsonKey(name: 'is_verified_nearby')  bool isVerifiedNearby, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _QuorumVoter():
return $default(_that.userId,_that.username,_that.displayName,_that.vote,_that.reason,_that.isVerifiedNearby,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  int userId,  String? username, @JsonKey(name: 'display_name')  String? displayName,  String vote,  String? reason, @JsonKey(name: 'is_verified_nearby')  bool isVerifiedNearby, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _QuorumVoter() when $default != null:
return $default(_that.userId,_that.username,_that.displayName,_that.vote,_that.reason,_that.isVerifiedNearby,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuorumVoter implements QuorumVoter {
  const _QuorumVoter({@JsonKey(name: 'user_id') required this.userId, this.username, @JsonKey(name: 'display_name') this.displayName, required this.vote, this.reason, @JsonKey(name: 'is_verified_nearby') this.isVerifiedNearby = true, @JsonKey(name: 'created_at') required this.createdAt});
  factory _QuorumVoter.fromJson(Map<String, dynamic> json) => _$QuorumVoterFromJson(json);

@override@JsonKey(name: 'user_id') final  int userId;
@override final  String? username;
@override@JsonKey(name: 'display_name') final  String? displayName;
@override final  String vote;
@override final  String? reason;
@override@JsonKey(name: 'is_verified_nearby') final  bool isVerifiedNearby;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of QuorumVoter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuorumVoterCopyWith<_QuorumVoter> get copyWith => __$QuorumVoterCopyWithImpl<_QuorumVoter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuorumVoterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuorumVoter&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vote, vote) || other.vote == vote)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.isVerifiedNearby, isVerifiedNearby) || other.isVerifiedNearby == isVerifiedNearby)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username,displayName,vote,reason,isVerifiedNearby,createdAt);

@override
String toString() {
  return 'QuorumVoter(userId: $userId, username: $username, displayName: $displayName, vote: $vote, reason: $reason, isVerifiedNearby: $isVerifiedNearby, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$QuorumVoterCopyWith<$Res> implements $QuorumVoterCopyWith<$Res> {
  factory _$QuorumVoterCopyWith(_QuorumVoter value, $Res Function(_QuorumVoter) _then) = __$QuorumVoterCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') int userId, String? username,@JsonKey(name: 'display_name') String? displayName, String vote, String? reason,@JsonKey(name: 'is_verified_nearby') bool isVerifiedNearby,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$QuorumVoterCopyWithImpl<$Res>
    implements _$QuorumVoterCopyWith<$Res> {
  __$QuorumVoterCopyWithImpl(this._self, this._then);

  final _QuorumVoter _self;
  final $Res Function(_QuorumVoter) _then;

/// Create a copy of QuorumVoter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? username = freezed,Object? displayName = freezed,Object? vote = null,Object? reason = freezed,Object? isVerifiedNearby = null,Object? createdAt = null,}) {
  return _then(_QuorumVoter(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,vote: null == vote ? _self.vote : vote // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,isVerifiedNearby: null == isVerifiedNearby ? _self.isVerifiedNearby : isVerifiedNearby // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$IssueTimelineEvent {

@JsonKey(name: 'event_type') String get eventType; String get title; String get description; DateTime get timestamp; String? get actor;@JsonKey(name: 'actor_role') String? get actorRole;@JsonKey(name: 'media_url') String? get mediaUrl; Map<String, dynamic>? get metadata;
/// Create a copy of IssueTimelineEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueTimelineEventCopyWith<IssueTimelineEvent> get copyWith => _$IssueTimelineEventCopyWithImpl<IssueTimelineEvent>(this as IssueTimelineEvent, _$identity);

  /// Serializes this IssueTimelineEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueTimelineEvent&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.actorRole, actorRole) || other.actorRole == actorRole)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventType,title,description,timestamp,actor,actorRole,mediaUrl,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'IssueTimelineEvent(eventType: $eventType, title: $title, description: $description, timestamp: $timestamp, actor: $actor, actorRole: $actorRole, mediaUrl: $mediaUrl, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $IssueTimelineEventCopyWith<$Res>  {
  factory $IssueTimelineEventCopyWith(IssueTimelineEvent value, $Res Function(IssueTimelineEvent) _then) = _$IssueTimelineEventCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'event_type') String eventType, String title, String description, DateTime timestamp, String? actor,@JsonKey(name: 'actor_role') String? actorRole,@JsonKey(name: 'media_url') String? mediaUrl, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$IssueTimelineEventCopyWithImpl<$Res>
    implements $IssueTimelineEventCopyWith<$Res> {
  _$IssueTimelineEventCopyWithImpl(this._self, this._then);

  final IssueTimelineEvent _self;
  final $Res Function(IssueTimelineEvent) _then;

/// Create a copy of IssueTimelineEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventType = null,Object? title = null,Object? description = null,Object? timestamp = null,Object? actor = freezed,Object? actorRole = freezed,Object? mediaUrl = freezed,Object? metadata = freezed,}) {
  return _then(IssueTimelineEvent(
eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String?,actorRole: freezed == actorRole ? _self.actorRole : actorRole // ignore: cast_nullable_to_non_nullable
as String?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueTimelineEvent].
extension IssueTimelineEventPatterns on IssueTimelineEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueTimelineEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueTimelineEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueTimelineEvent value)  $default,){
final _that = this;
switch (_that) {
case _IssueTimelineEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueTimelineEvent value)?  $default,){
final _that = this;
switch (_that) {
case _IssueTimelineEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_type')  String eventType,  String title,  String description,  DateTime timestamp,  String? actor, @JsonKey(name: 'actor_role')  String? actorRole, @JsonKey(name: 'media_url')  String? mediaUrl,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueTimelineEvent() when $default != null:
return $default(_that.eventType,_that.title,_that.description,_that.timestamp,_that.actor,_that.actorRole,_that.mediaUrl,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_type')  String eventType,  String title,  String description,  DateTime timestamp,  String? actor, @JsonKey(name: 'actor_role')  String? actorRole, @JsonKey(name: 'media_url')  String? mediaUrl,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _IssueTimelineEvent():
return $default(_that.eventType,_that.title,_that.description,_that.timestamp,_that.actor,_that.actorRole,_that.mediaUrl,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'event_type')  String eventType,  String title,  String description,  DateTime timestamp,  String? actor, @JsonKey(name: 'actor_role')  String? actorRole, @JsonKey(name: 'media_url')  String? mediaUrl,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _IssueTimelineEvent() when $default != null:
return $default(_that.eventType,_that.title,_that.description,_that.timestamp,_that.actor,_that.actorRole,_that.mediaUrl,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueTimelineEvent implements IssueTimelineEvent {
  const _IssueTimelineEvent({@JsonKey(name: 'event_type') required this.eventType, required this.title, required this.description, required this.timestamp, this.actor, @JsonKey(name: 'actor_role') this.actorRole, @JsonKey(name: 'media_url') this.mediaUrl,  Map<String, dynamic>? metadata}): _metadata = metadata;
  factory _IssueTimelineEvent.fromJson(Map<String, dynamic> json) => _$IssueTimelineEventFromJson(json);

@override@JsonKey(name: 'event_type') final  String eventType;
@override final  String title;
@override final  String description;
@override final  DateTime timestamp;
@override final  String? actor;
@override@JsonKey(name: 'actor_role') final  String? actorRole;
@override@JsonKey(name: 'media_url') final  String? mediaUrl;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of IssueTimelineEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueTimelineEventCopyWith<_IssueTimelineEvent> get copyWith => __$IssueTimelineEventCopyWithImpl<_IssueTimelineEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueTimelineEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueTimelineEvent&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.actorRole, actorRole) || other.actorRole == actorRole)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventType,title,description,timestamp,actor,actorRole,mediaUrl,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'IssueTimelineEvent(eventType: $eventType, title: $title, description: $description, timestamp: $timestamp, actor: $actor, actorRole: $actorRole, mediaUrl: $mediaUrl, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$IssueTimelineEventCopyWith<$Res> implements $IssueTimelineEventCopyWith<$Res> {
  factory _$IssueTimelineEventCopyWith(_IssueTimelineEvent value, $Res Function(_IssueTimelineEvent) _then) = __$IssueTimelineEventCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'event_type') String eventType, String title, String description, DateTime timestamp, String? actor,@JsonKey(name: 'actor_role') String? actorRole,@JsonKey(name: 'media_url') String? mediaUrl, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$IssueTimelineEventCopyWithImpl<$Res>
    implements _$IssueTimelineEventCopyWith<$Res> {
  __$IssueTimelineEventCopyWithImpl(this._self, this._then);

  final _IssueTimelineEvent _self;
  final $Res Function(_IssueTimelineEvent) _then;

/// Create a copy of IssueTimelineEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventType = null,Object? title = null,Object? description = null,Object? timestamp = null,Object? actor = freezed,Object? actorRole = freezed,Object? mediaUrl = freezed,Object? metadata = freezed,}) {
  return _then(_IssueTimelineEvent(
eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String?,actorRole: freezed == actorRole ? _self.actorRole : actorRole // ignore: cast_nullable_to_non_nullable
as String?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$IssueTimelineData {

@JsonKey(name: 'issue_id') int get issueId; String get status; List<IssueTimelineEvent> get events; List<QuorumVoter> get confirmations; List<QuorumVoter> get disputes;
/// Create a copy of IssueTimelineData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueTimelineDataCopyWith<IssueTimelineData> get copyWith => _$IssueTimelineDataCopyWithImpl<IssueTimelineData>(this as IssueTimelineData, _$identity);

  /// Serializes this IssueTimelineData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueTimelineData&&(identical(other.issueId, issueId) || other.issueId == issueId)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.events, events)&&const DeepCollectionEquality().equals(other.confirmations, confirmations)&&const DeepCollectionEquality().equals(other.disputes, disputes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,issueId,status,const DeepCollectionEquality().hash(events),const DeepCollectionEquality().hash(confirmations),const DeepCollectionEquality().hash(disputes));

@override
String toString() {
  return 'IssueTimelineData(issueId: $issueId, status: $status, events: $events, confirmations: $confirmations, disputes: $disputes)';
}


}

/// @nodoc
abstract mixin class $IssueTimelineDataCopyWith<$Res>  {
  factory $IssueTimelineDataCopyWith(IssueTimelineData value, $Res Function(IssueTimelineData) _then) = _$IssueTimelineDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'issue_id') int issueId, String status, List<IssueTimelineEvent> events, List<QuorumVoter> confirmations, List<QuorumVoter> disputes
});




}
/// @nodoc
class _$IssueTimelineDataCopyWithImpl<$Res>
    implements $IssueTimelineDataCopyWith<$Res> {
  _$IssueTimelineDataCopyWithImpl(this._self, this._then);

  final IssueTimelineData _self;
  final $Res Function(IssueTimelineData) _then;

/// Create a copy of IssueTimelineData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? issueId = null,Object? status = null,Object? events = null,Object? confirmations = null,Object? disputes = null,}) {
  return _then(IssueTimelineData(
issueId: null == issueId ? _self.issueId : issueId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<IssueTimelineEvent>,confirmations: null == confirmations ? _self.confirmations : confirmations // ignore: cast_nullable_to_non_nullable
as List<QuorumVoter>,disputes: null == disputes ? _self.disputes : disputes // ignore: cast_nullable_to_non_nullable
as List<QuorumVoter>,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueTimelineData].
extension IssueTimelineDataPatterns on IssueTimelineData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueTimelineData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueTimelineData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueTimelineData value)  $default,){
final _that = this;
switch (_that) {
case _IssueTimelineData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueTimelineData value)?  $default,){
final _that = this;
switch (_that) {
case _IssueTimelineData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'issue_id')  int issueId,  String status,  List<IssueTimelineEvent> events,  List<QuorumVoter> confirmations,  List<QuorumVoter> disputes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueTimelineData() when $default != null:
return $default(_that.issueId,_that.status,_that.events,_that.confirmations,_that.disputes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'issue_id')  int issueId,  String status,  List<IssueTimelineEvent> events,  List<QuorumVoter> confirmations,  List<QuorumVoter> disputes)  $default,) {final _that = this;
switch (_that) {
case _IssueTimelineData():
return $default(_that.issueId,_that.status,_that.events,_that.confirmations,_that.disputes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'issue_id')  int issueId,  String status,  List<IssueTimelineEvent> events,  List<QuorumVoter> confirmations,  List<QuorumVoter> disputes)?  $default,) {final _that = this;
switch (_that) {
case _IssueTimelineData() when $default != null:
return $default(_that.issueId,_that.status,_that.events,_that.confirmations,_that.disputes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueTimelineData implements IssueTimelineData {
  const _IssueTimelineData({@JsonKey(name: 'issue_id') required this.issueId, required this.status,  List<IssueTimelineEvent> events = const <IssueTimelineEvent>[],  List<QuorumVoter> confirmations = const <QuorumVoter>[],  List<QuorumVoter> disputes = const <QuorumVoter>[]}): _events = events,_confirmations = confirmations,_disputes = disputes;
  factory _IssueTimelineData.fromJson(Map<String, dynamic> json) => _$IssueTimelineDataFromJson(json);

@override@JsonKey(name: 'issue_id') final  int issueId;
@override final  String status;
 final  List<IssueTimelineEvent> _events;
@override@JsonKey() List<IssueTimelineEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

 final  List<QuorumVoter> _confirmations;
@override@JsonKey() List<QuorumVoter> get confirmations {
  if (_confirmations is EqualUnmodifiableListView) return _confirmations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_confirmations);
}

 final  List<QuorumVoter> _disputes;
@override@JsonKey() List<QuorumVoter> get disputes {
  if (_disputes is EqualUnmodifiableListView) return _disputes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_disputes);
}


/// Create a copy of IssueTimelineData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueTimelineDataCopyWith<_IssueTimelineData> get copyWith => __$IssueTimelineDataCopyWithImpl<_IssueTimelineData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueTimelineDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueTimelineData&&(identical(other.issueId, issueId) || other.issueId == issueId)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._events, _events)&&const DeepCollectionEquality().equals(other._confirmations, _confirmations)&&const DeepCollectionEquality().equals(other._disputes, _disputes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,issueId,status,const DeepCollectionEquality().hash(_events),const DeepCollectionEquality().hash(_confirmations),const DeepCollectionEquality().hash(_disputes));

@override
String toString() {
  return 'IssueTimelineData(issueId: $issueId, status: $status, events: $events, confirmations: $confirmations, disputes: $disputes)';
}


}

/// @nodoc
abstract mixin class _$IssueTimelineDataCopyWith<$Res> implements $IssueTimelineDataCopyWith<$Res> {
  factory _$IssueTimelineDataCopyWith(_IssueTimelineData value, $Res Function(_IssueTimelineData) _then) = __$IssueTimelineDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'issue_id') int issueId, String status, List<IssueTimelineEvent> events, List<QuorumVoter> confirmations, List<QuorumVoter> disputes
});




}
/// @nodoc
class __$IssueTimelineDataCopyWithImpl<$Res>
    implements _$IssueTimelineDataCopyWith<$Res> {
  __$IssueTimelineDataCopyWithImpl(this._self, this._then);

  final _IssueTimelineData _self;
  final $Res Function(_IssueTimelineData) _then;

/// Create a copy of IssueTimelineData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? issueId = null,Object? status = null,Object? events = null,Object? confirmations = null,Object? disputes = null,}) {
  return _then(_IssueTimelineData(
issueId: null == issueId ? _self.issueId : issueId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<IssueTimelineEvent>,confirmations: null == confirmations ? _self._confirmations : confirmations // ignore: cast_nullable_to_non_nullable
as List<QuorumVoter>,disputes: null == disputes ? _self._disputes : disputes // ignore: cast_nullable_to_non_nullable
as List<QuorumVoter>,
  ));
}


}


/// @nodoc
mixin _$Issue {

 int get id; String get title; String get description; String get category; String get status; double get latitude; double get longitude; String? get geohash; String get ward;@JsonKey(name: 'is_anonymous') bool get isAnonymous;@JsonKey(name: 'is_fuzzed') bool get isFuzzed;@JsonKey(name: 'is_shielded') bool get isShielded;@JsonKey(name: 'reporter_label') String get reporterLabel;@JsonKey(name: 'reporter_name') String? get reporterName;@JsonKey(name: 'reporter_photo_url') String? get reporterPhotoUrl;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'acknowledged_at') DateTime? get acknowledgedAt;@JsonKey(name: 'resolved_at') DateTime? get resolvedAt;@JsonKey(name: 'resolution_proof') String? get resolutionProof;@JsonKey(name: 'resolution_notes') String? get resolutionNotes;@JsonKey(name: 'upvotes_count') int get upvotesCount;@JsonKey(name: 'confirmations_count') int get confirmationsCount;@JsonKey(name: 'disputes_count') int get disputesCount;@JsonKey(name: 'has_upvoted') bool get hasUpvoted;@JsonKey(name: 'media_urls') List<String> get mediaUrls;@JsonKey(name: 'video_url') String? get videoUrl;@JsonKey(name: 'reporter_id') int? get reporterId;@JsonKey(name: 'assigned_representative') AssignedAuthority? get assignedRepresentative;@JsonKey(name: 'resolved_by') String? get resolvedBy;@JsonKey(name: 'resolution_type') String? get resolutionType;
/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueCopyWith<Issue> get copyWith => _$IssueCopyWithImpl<Issue>(this as Issue, _$identity);

  /// Serializes this Issue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Issue&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&(identical(other.ward, ward) || other.ward == ward)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.isFuzzed, isFuzzed) || other.isFuzzed == isFuzzed)&&(identical(other.isShielded, isShielded) || other.isShielded == isShielded)&&(identical(other.reporterLabel, reporterLabel) || other.reporterLabel == reporterLabel)&&(identical(other.reporterName, reporterName) || other.reporterName == reporterName)&&(identical(other.reporterPhotoUrl, reporterPhotoUrl) || other.reporterPhotoUrl == reporterPhotoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolutionProof, resolutionProof) || other.resolutionProof == resolutionProof)&&(identical(other.resolutionNotes, resolutionNotes) || other.resolutionNotes == resolutionNotes)&&(identical(other.upvotesCount, upvotesCount) || other.upvotesCount == upvotesCount)&&(identical(other.confirmationsCount, confirmationsCount) || other.confirmationsCount == confirmationsCount)&&(identical(other.disputesCount, disputesCount) || other.disputesCount == disputesCount)&&(identical(other.hasUpvoted, hasUpvoted) || other.hasUpvoted == hasUpvoted)&&const DeepCollectionEquality().equals(other.mediaUrls, mediaUrls)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.assignedRepresentative, assignedRepresentative) || other.assignedRepresentative == assignedRepresentative)&&(identical(other.resolvedBy, resolvedBy) || other.resolvedBy == resolvedBy)&&(identical(other.resolutionType, resolutionType) || other.resolutionType == resolutionType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,category,status,latitude,longitude,geohash,ward,isAnonymous,isFuzzed,isShielded,reporterLabel,reporterName,reporterPhotoUrl,createdAt,acknowledgedAt,resolvedAt,resolutionProof,resolutionNotes,upvotesCount,confirmationsCount,disputesCount,hasUpvoted,const DeepCollectionEquality().hash(mediaUrls),videoUrl,reporterId,assignedRepresentative,resolvedBy,resolutionType]);

@override
String toString() {
  return 'Issue(id: $id, title: $title, description: $description, category: $category, status: $status, latitude: $latitude, longitude: $longitude, geohash: $geohash, ward: $ward, isAnonymous: $isAnonymous, isFuzzed: $isFuzzed, isShielded: $isShielded, reporterLabel: $reporterLabel, reporterName: $reporterName, reporterPhotoUrl: $reporterPhotoUrl, createdAt: $createdAt, acknowledgedAt: $acknowledgedAt, resolvedAt: $resolvedAt, resolutionProof: $resolutionProof, resolutionNotes: $resolutionNotes, upvotesCount: $upvotesCount, confirmationsCount: $confirmationsCount, disputesCount: $disputesCount, hasUpvoted: $hasUpvoted, mediaUrls: $mediaUrls, videoUrl: $videoUrl, reporterId: $reporterId, assignedRepresentative: $assignedRepresentative, resolvedBy: $resolvedBy, resolutionType: $resolutionType)';
}


}

/// @nodoc
abstract mixin class $IssueCopyWith<$Res>  {
  factory $IssueCopyWith(Issue value, $Res Function(Issue) _then) = _$IssueCopyWithImpl;
@useResult
$Res call({
 int id, String title, String description, String category, String status, double latitude, double longitude, String? geohash, String ward,@JsonKey(name: 'is_anonymous') bool isAnonymous,@JsonKey(name: 'is_fuzzed') bool isFuzzed,@JsonKey(name: 'is_shielded') bool isShielded,@JsonKey(name: 'reporter_label') String reporterLabel,@JsonKey(name: 'reporter_name') String? reporterName,@JsonKey(name: 'reporter_photo_url') String? reporterPhotoUrl,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'acknowledged_at') DateTime? acknowledgedAt,@JsonKey(name: 'resolved_at') DateTime? resolvedAt,@JsonKey(name: 'resolution_proof') String? resolutionProof,@JsonKey(name: 'resolution_notes') String? resolutionNotes,@JsonKey(name: 'upvotes_count') int upvotesCount,@JsonKey(name: 'confirmations_count') int confirmationsCount,@JsonKey(name: 'disputes_count') int disputesCount,@JsonKey(name: 'has_upvoted') bool hasUpvoted,@JsonKey(name: 'media_urls') List<String> mediaUrls,@JsonKey(name: 'video_url') String? videoUrl,@JsonKey(name: 'reporter_id') int? reporterId,@JsonKey(name: 'assigned_representative') AssignedAuthority? assignedRepresentative,@JsonKey(name: 'resolved_by') String? resolvedBy,@JsonKey(name: 'resolution_type') String? resolutionType
});


$AssignedAuthorityCopyWith<$Res>? get assignedRepresentative;

}
/// @nodoc
class _$IssueCopyWithImpl<$Res>
    implements $IssueCopyWith<$Res> {
  _$IssueCopyWithImpl(this._self, this._then);

  final Issue _self;
  final $Res Function(Issue) _then;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? status = null,Object? latitude = null,Object? longitude = null,Object? geohash = freezed,Object? ward = null,Object? isAnonymous = null,Object? isFuzzed = null,Object? isShielded = null,Object? reporterLabel = null,Object? reporterName = freezed,Object? reporterPhotoUrl = freezed,Object? createdAt = null,Object? acknowledgedAt = freezed,Object? resolvedAt = freezed,Object? resolutionProof = freezed,Object? resolutionNotes = freezed,Object? upvotesCount = null,Object? confirmationsCount = null,Object? disputesCount = null,Object? hasUpvoted = null,Object? mediaUrls = null,Object? videoUrl = freezed,Object? reporterId = freezed,Object? assignedRepresentative = freezed,Object? resolvedBy = freezed,Object? resolutionType = freezed,}) {
  return _then(Issue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,geohash: freezed == geohash ? _self.geohash : geohash // ignore: cast_nullable_to_non_nullable
as String?,ward: null == ward ? _self.ward : ward // ignore: cast_nullable_to_non_nullable
as String,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,isFuzzed: null == isFuzzed ? _self.isFuzzed : isFuzzed // ignore: cast_nullable_to_non_nullable
as bool,isShielded: null == isShielded ? _self.isShielded : isShielded // ignore: cast_nullable_to_non_nullable
as bool,reporterLabel: null == reporterLabel ? _self.reporterLabel : reporterLabel // ignore: cast_nullable_to_non_nullable
as String,reporterName: freezed == reporterName ? _self.reporterName : reporterName // ignore: cast_nullable_to_non_nullable
as String?,reporterPhotoUrl: freezed == reporterPhotoUrl ? _self.reporterPhotoUrl : reporterPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolutionProof: freezed == resolutionProof ? _self.resolutionProof : resolutionProof // ignore: cast_nullable_to_non_nullable
as String?,resolutionNotes: freezed == resolutionNotes ? _self.resolutionNotes : resolutionNotes // ignore: cast_nullable_to_non_nullable
as String?,upvotesCount: null == upvotesCount ? _self.upvotesCount : upvotesCount // ignore: cast_nullable_to_non_nullable
as int,confirmationsCount: null == confirmationsCount ? _self.confirmationsCount : confirmationsCount // ignore: cast_nullable_to_non_nullable
as int,disputesCount: null == disputesCount ? _self.disputesCount : disputesCount // ignore: cast_nullable_to_non_nullable
as int,hasUpvoted: null == hasUpvoted ? _self.hasUpvoted : hasUpvoted // ignore: cast_nullable_to_non_nullable
as bool,mediaUrls: null == mediaUrls ? _self.mediaUrls : mediaUrls // ignore: cast_nullable_to_non_nullable
as List<String>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,reporterId: freezed == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as int?,assignedRepresentative: freezed == assignedRepresentative ? _self.assignedRepresentative : assignedRepresentative // ignore: cast_nullable_to_non_nullable
as AssignedAuthority?,resolvedBy: freezed == resolvedBy ? _self.resolvedBy : resolvedBy // ignore: cast_nullable_to_non_nullable
as String?,resolutionType: freezed == resolutionType ? _self.resolutionType : resolutionType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssignedAuthorityCopyWith<$Res>? get assignedRepresentative {
    if (_self.assignedRepresentative == null) {
    return null;
  }

  return $AssignedAuthorityCopyWith<$Res>(_self.assignedRepresentative!, (value) {
    return _then(_self.copyWith(assignedRepresentative: value));
  });
}
}


/// Adds pattern-matching-related methods to [Issue].
extension IssuePatterns on Issue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Issue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Issue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Issue value)  $default,){
final _that = this;
switch (_that) {
case _Issue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Issue value)?  $default,){
final _that = this;
switch (_that) {
case _Issue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String description,  String category,  String status,  double latitude,  double longitude,  String? geohash,  String ward, @JsonKey(name: 'is_anonymous')  bool isAnonymous, @JsonKey(name: 'is_fuzzed')  bool isFuzzed, @JsonKey(name: 'is_shielded')  bool isShielded, @JsonKey(name: 'reporter_label')  String reporterLabel, @JsonKey(name: 'reporter_name')  String? reporterName, @JsonKey(name: 'reporter_photo_url')  String? reporterPhotoUrl, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'acknowledged_at')  DateTime? acknowledgedAt, @JsonKey(name: 'resolved_at')  DateTime? resolvedAt, @JsonKey(name: 'resolution_proof')  String? resolutionProof, @JsonKey(name: 'resolution_notes')  String? resolutionNotes, @JsonKey(name: 'upvotes_count')  int upvotesCount, @JsonKey(name: 'confirmations_count')  int confirmationsCount, @JsonKey(name: 'disputes_count')  int disputesCount, @JsonKey(name: 'has_upvoted')  bool hasUpvoted, @JsonKey(name: 'media_urls')  List<String> mediaUrls, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'reporter_id')  int? reporterId, @JsonKey(name: 'assigned_representative')  AssignedAuthority? assignedRepresentative, @JsonKey(name: 'resolved_by')  String? resolvedBy, @JsonKey(name: 'resolution_type')  String? resolutionType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Issue() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.status,_that.latitude,_that.longitude,_that.geohash,_that.ward,_that.isAnonymous,_that.isFuzzed,_that.isShielded,_that.reporterLabel,_that.reporterName,_that.reporterPhotoUrl,_that.createdAt,_that.acknowledgedAt,_that.resolvedAt,_that.resolutionProof,_that.resolutionNotes,_that.upvotesCount,_that.confirmationsCount,_that.disputesCount,_that.hasUpvoted,_that.mediaUrls,_that.videoUrl,_that.reporterId,_that.assignedRepresentative,_that.resolvedBy,_that.resolutionType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String description,  String category,  String status,  double latitude,  double longitude,  String? geohash,  String ward, @JsonKey(name: 'is_anonymous')  bool isAnonymous, @JsonKey(name: 'is_fuzzed')  bool isFuzzed, @JsonKey(name: 'is_shielded')  bool isShielded, @JsonKey(name: 'reporter_label')  String reporterLabel, @JsonKey(name: 'reporter_name')  String? reporterName, @JsonKey(name: 'reporter_photo_url')  String? reporterPhotoUrl, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'acknowledged_at')  DateTime? acknowledgedAt, @JsonKey(name: 'resolved_at')  DateTime? resolvedAt, @JsonKey(name: 'resolution_proof')  String? resolutionProof, @JsonKey(name: 'resolution_notes')  String? resolutionNotes, @JsonKey(name: 'upvotes_count')  int upvotesCount, @JsonKey(name: 'confirmations_count')  int confirmationsCount, @JsonKey(name: 'disputes_count')  int disputesCount, @JsonKey(name: 'has_upvoted')  bool hasUpvoted, @JsonKey(name: 'media_urls')  List<String> mediaUrls, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'reporter_id')  int? reporterId, @JsonKey(name: 'assigned_representative')  AssignedAuthority? assignedRepresentative, @JsonKey(name: 'resolved_by')  String? resolvedBy, @JsonKey(name: 'resolution_type')  String? resolutionType)  $default,) {final _that = this;
switch (_that) {
case _Issue():
return $default(_that.id,_that.title,_that.description,_that.category,_that.status,_that.latitude,_that.longitude,_that.geohash,_that.ward,_that.isAnonymous,_that.isFuzzed,_that.isShielded,_that.reporterLabel,_that.reporterName,_that.reporterPhotoUrl,_that.createdAt,_that.acknowledgedAt,_that.resolvedAt,_that.resolutionProof,_that.resolutionNotes,_that.upvotesCount,_that.confirmationsCount,_that.disputesCount,_that.hasUpvoted,_that.mediaUrls,_that.videoUrl,_that.reporterId,_that.assignedRepresentative,_that.resolvedBy,_that.resolutionType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String description,  String category,  String status,  double latitude,  double longitude,  String? geohash,  String ward, @JsonKey(name: 'is_anonymous')  bool isAnonymous, @JsonKey(name: 'is_fuzzed')  bool isFuzzed, @JsonKey(name: 'is_shielded')  bool isShielded, @JsonKey(name: 'reporter_label')  String reporterLabel, @JsonKey(name: 'reporter_name')  String? reporterName, @JsonKey(name: 'reporter_photo_url')  String? reporterPhotoUrl, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'acknowledged_at')  DateTime? acknowledgedAt, @JsonKey(name: 'resolved_at')  DateTime? resolvedAt, @JsonKey(name: 'resolution_proof')  String? resolutionProof, @JsonKey(name: 'resolution_notes')  String? resolutionNotes, @JsonKey(name: 'upvotes_count')  int upvotesCount, @JsonKey(name: 'confirmations_count')  int confirmationsCount, @JsonKey(name: 'disputes_count')  int disputesCount, @JsonKey(name: 'has_upvoted')  bool hasUpvoted, @JsonKey(name: 'media_urls')  List<String> mediaUrls, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'reporter_id')  int? reporterId, @JsonKey(name: 'assigned_representative')  AssignedAuthority? assignedRepresentative, @JsonKey(name: 'resolved_by')  String? resolvedBy, @JsonKey(name: 'resolution_type')  String? resolutionType)?  $default,) {final _that = this;
switch (_that) {
case _Issue() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.status,_that.latitude,_that.longitude,_that.geohash,_that.ward,_that.isAnonymous,_that.isFuzzed,_that.isShielded,_that.reporterLabel,_that.reporterName,_that.reporterPhotoUrl,_that.createdAt,_that.acknowledgedAt,_that.resolvedAt,_that.resolutionProof,_that.resolutionNotes,_that.upvotesCount,_that.confirmationsCount,_that.disputesCount,_that.hasUpvoted,_that.mediaUrls,_that.videoUrl,_that.reporterId,_that.assignedRepresentative,_that.resolvedBy,_that.resolutionType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Issue extends Issue {
  const _Issue({required this.id, required this.title, required this.description, required this.category, required this.status, required this.latitude, required this.longitude, this.geohash, this.ward = 'Ward 45, Urban Central', @JsonKey(name: 'is_anonymous') required this.isAnonymous, @JsonKey(name: 'is_fuzzed') this.isFuzzed = false, @JsonKey(name: 'is_shielded') this.isShielded = false, @JsonKey(name: 'reporter_label') required this.reporterLabel, @JsonKey(name: 'reporter_name') this.reporterName, @JsonKey(name: 'reporter_photo_url') this.reporterPhotoUrl, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'acknowledged_at') this.acknowledgedAt, @JsonKey(name: 'resolved_at') this.resolvedAt, @JsonKey(name: 'resolution_proof') this.resolutionProof, @JsonKey(name: 'resolution_notes') this.resolutionNotes, @JsonKey(name: 'upvotes_count') this.upvotesCount = 0, @JsonKey(name: 'confirmations_count') this.confirmationsCount = 0, @JsonKey(name: 'disputes_count') this.disputesCount = 0, @JsonKey(name: 'has_upvoted') this.hasUpvoted = false, @JsonKey(name: 'media_urls')  List<String> mediaUrls = const <String>[], @JsonKey(name: 'video_url') this.videoUrl, @JsonKey(name: 'reporter_id') this.reporterId, @JsonKey(name: 'assigned_representative') this.assignedRepresentative, @JsonKey(name: 'resolved_by') this.resolvedBy, @JsonKey(name: 'resolution_type') this.resolutionType}): _mediaUrls = mediaUrls,super._();
  factory _Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);

@override final  int id;
@override final  String title;
@override final  String description;
@override final  String category;
@override final  String status;
@override final  double latitude;
@override final  double longitude;
@override final  String? geohash;
@override@JsonKey() final  String ward;
@override@JsonKey(name: 'is_anonymous') final  bool isAnonymous;
@override@JsonKey(name: 'is_fuzzed') final  bool isFuzzed;
@override@JsonKey(name: 'is_shielded') final  bool isShielded;
@override@JsonKey(name: 'reporter_label') final  String reporterLabel;
@override@JsonKey(name: 'reporter_name') final  String? reporterName;
@override@JsonKey(name: 'reporter_photo_url') final  String? reporterPhotoUrl;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'acknowledged_at') final  DateTime? acknowledgedAt;
@override@JsonKey(name: 'resolved_at') final  DateTime? resolvedAt;
@override@JsonKey(name: 'resolution_proof') final  String? resolutionProof;
@override@JsonKey(name: 'resolution_notes') final  String? resolutionNotes;
@override@JsonKey(name: 'upvotes_count') final  int upvotesCount;
@override@JsonKey(name: 'confirmations_count') final  int confirmationsCount;
@override@JsonKey(name: 'disputes_count') final  int disputesCount;
@override@JsonKey(name: 'has_upvoted') final  bool hasUpvoted;
 final  List<String> _mediaUrls;
@override@JsonKey(name: 'media_urls') List<String> get mediaUrls {
  if (_mediaUrls is EqualUnmodifiableListView) return _mediaUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaUrls);
}

@override@JsonKey(name: 'video_url') final  String? videoUrl;
@override@JsonKey(name: 'reporter_id') final  int? reporterId;
@override@JsonKey(name: 'assigned_representative') final  AssignedAuthority? assignedRepresentative;
@override@JsonKey(name: 'resolved_by') final  String? resolvedBy;
@override@JsonKey(name: 'resolution_type') final  String? resolutionType;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueCopyWith<_Issue> get copyWith => __$IssueCopyWithImpl<_Issue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Issue&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&(identical(other.ward, ward) || other.ward == ward)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.isFuzzed, isFuzzed) || other.isFuzzed == isFuzzed)&&(identical(other.isShielded, isShielded) || other.isShielded == isShielded)&&(identical(other.reporterLabel, reporterLabel) || other.reporterLabel == reporterLabel)&&(identical(other.reporterName, reporterName) || other.reporterName == reporterName)&&(identical(other.reporterPhotoUrl, reporterPhotoUrl) || other.reporterPhotoUrl == reporterPhotoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolutionProof, resolutionProof) || other.resolutionProof == resolutionProof)&&(identical(other.resolutionNotes, resolutionNotes) || other.resolutionNotes == resolutionNotes)&&(identical(other.upvotesCount, upvotesCount) || other.upvotesCount == upvotesCount)&&(identical(other.confirmationsCount, confirmationsCount) || other.confirmationsCount == confirmationsCount)&&(identical(other.disputesCount, disputesCount) || other.disputesCount == disputesCount)&&(identical(other.hasUpvoted, hasUpvoted) || other.hasUpvoted == hasUpvoted)&&const DeepCollectionEquality().equals(other._mediaUrls, _mediaUrls)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.assignedRepresentative, assignedRepresentative) || other.assignedRepresentative == assignedRepresentative)&&(identical(other.resolvedBy, resolvedBy) || other.resolvedBy == resolvedBy)&&(identical(other.resolutionType, resolutionType) || other.resolutionType == resolutionType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,category,status,latitude,longitude,geohash,ward,isAnonymous,isFuzzed,isShielded,reporterLabel,reporterName,reporterPhotoUrl,createdAt,acknowledgedAt,resolvedAt,resolutionProof,resolutionNotes,upvotesCount,confirmationsCount,disputesCount,hasUpvoted,const DeepCollectionEquality().hash(_mediaUrls),videoUrl,reporterId,assignedRepresentative,resolvedBy,resolutionType]);

@override
String toString() {
  return 'Issue(id: $id, title: $title, description: $description, category: $category, status: $status, latitude: $latitude, longitude: $longitude, geohash: $geohash, ward: $ward, isAnonymous: $isAnonymous, isFuzzed: $isFuzzed, isShielded: $isShielded, reporterLabel: $reporterLabel, reporterName: $reporterName, reporterPhotoUrl: $reporterPhotoUrl, createdAt: $createdAt, acknowledgedAt: $acknowledgedAt, resolvedAt: $resolvedAt, resolutionProof: $resolutionProof, resolutionNotes: $resolutionNotes, upvotesCount: $upvotesCount, confirmationsCount: $confirmationsCount, disputesCount: $disputesCount, hasUpvoted: $hasUpvoted, mediaUrls: $mediaUrls, videoUrl: $videoUrl, reporterId: $reporterId, assignedRepresentative: $assignedRepresentative, resolvedBy: $resolvedBy, resolutionType: $resolutionType)';
}


}

/// @nodoc
abstract mixin class _$IssueCopyWith<$Res> implements $IssueCopyWith<$Res> {
  factory _$IssueCopyWith(_Issue value, $Res Function(_Issue) _then) = __$IssueCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String description, String category, String status, double latitude, double longitude, String? geohash, String ward,@JsonKey(name: 'is_anonymous') bool isAnonymous,@JsonKey(name: 'is_fuzzed') bool isFuzzed,@JsonKey(name: 'is_shielded') bool isShielded,@JsonKey(name: 'reporter_label') String reporterLabel,@JsonKey(name: 'reporter_name') String? reporterName,@JsonKey(name: 'reporter_photo_url') String? reporterPhotoUrl,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'acknowledged_at') DateTime? acknowledgedAt,@JsonKey(name: 'resolved_at') DateTime? resolvedAt,@JsonKey(name: 'resolution_proof') String? resolutionProof,@JsonKey(name: 'resolution_notes') String? resolutionNotes,@JsonKey(name: 'upvotes_count') int upvotesCount,@JsonKey(name: 'confirmations_count') int confirmationsCount,@JsonKey(name: 'disputes_count') int disputesCount,@JsonKey(name: 'has_upvoted') bool hasUpvoted,@JsonKey(name: 'media_urls') List<String> mediaUrls,@JsonKey(name: 'video_url') String? videoUrl,@JsonKey(name: 'reporter_id') int? reporterId,@JsonKey(name: 'assigned_representative') AssignedAuthority? assignedRepresentative,@JsonKey(name: 'resolved_by') String? resolvedBy,@JsonKey(name: 'resolution_type') String? resolutionType
});


@override $AssignedAuthorityCopyWith<$Res>? get assignedRepresentative;

}
/// @nodoc
class __$IssueCopyWithImpl<$Res>
    implements _$IssueCopyWith<$Res> {
  __$IssueCopyWithImpl(this._self, this._then);

  final _Issue _self;
  final $Res Function(_Issue) _then;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? status = null,Object? latitude = null,Object? longitude = null,Object? geohash = freezed,Object? ward = null,Object? isAnonymous = null,Object? isFuzzed = null,Object? isShielded = null,Object? reporterLabel = null,Object? reporterName = freezed,Object? reporterPhotoUrl = freezed,Object? createdAt = null,Object? acknowledgedAt = freezed,Object? resolvedAt = freezed,Object? resolutionProof = freezed,Object? resolutionNotes = freezed,Object? upvotesCount = null,Object? confirmationsCount = null,Object? disputesCount = null,Object? hasUpvoted = null,Object? mediaUrls = null,Object? videoUrl = freezed,Object? reporterId = freezed,Object? assignedRepresentative = freezed,Object? resolvedBy = freezed,Object? resolutionType = freezed,}) {
  return _then(_Issue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,geohash: freezed == geohash ? _self.geohash : geohash // ignore: cast_nullable_to_non_nullable
as String?,ward: null == ward ? _self.ward : ward // ignore: cast_nullable_to_non_nullable
as String,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,isFuzzed: null == isFuzzed ? _self.isFuzzed : isFuzzed // ignore: cast_nullable_to_non_nullable
as bool,isShielded: null == isShielded ? _self.isShielded : isShielded // ignore: cast_nullable_to_non_nullable
as bool,reporterLabel: null == reporterLabel ? _self.reporterLabel : reporterLabel // ignore: cast_nullable_to_non_nullable
as String,reporterName: freezed == reporterName ? _self.reporterName : reporterName // ignore: cast_nullable_to_non_nullable
as String?,reporterPhotoUrl: freezed == reporterPhotoUrl ? _self.reporterPhotoUrl : reporterPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolutionProof: freezed == resolutionProof ? _self.resolutionProof : resolutionProof // ignore: cast_nullable_to_non_nullable
as String?,resolutionNotes: freezed == resolutionNotes ? _self.resolutionNotes : resolutionNotes // ignore: cast_nullable_to_non_nullable
as String?,upvotesCount: null == upvotesCount ? _self.upvotesCount : upvotesCount // ignore: cast_nullable_to_non_nullable
as int,confirmationsCount: null == confirmationsCount ? _self.confirmationsCount : confirmationsCount // ignore: cast_nullable_to_non_nullable
as int,disputesCount: null == disputesCount ? _self.disputesCount : disputesCount // ignore: cast_nullable_to_non_nullable
as int,hasUpvoted: null == hasUpvoted ? _self.hasUpvoted : hasUpvoted // ignore: cast_nullable_to_non_nullable
as bool,mediaUrls: null == mediaUrls ? _self._mediaUrls : mediaUrls // ignore: cast_nullable_to_non_nullable
as List<String>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,reporterId: freezed == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as int?,assignedRepresentative: freezed == assignedRepresentative ? _self.assignedRepresentative : assignedRepresentative // ignore: cast_nullable_to_non_nullable
as AssignedAuthority?,resolvedBy: freezed == resolvedBy ? _self.resolvedBy : resolvedBy // ignore: cast_nullable_to_non_nullable
as String?,resolutionType: freezed == resolutionType ? _self.resolutionType : resolutionType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssignedAuthorityCopyWith<$Res>? get assignedRepresentative {
    if (_self.assignedRepresentative == null) {
    return null;
  }

  return $AssignedAuthorityCopyWith<$Res>(_self.assignedRepresentative!, (value) {
    return _then(_self.copyWith(assignedRepresentative: value));
  });
}
}

// dart format on
