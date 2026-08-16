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
mixin _$Issue {

 int get id; String get title; String get description; String get category; String get status; double get latitude; double get longitude; String? get geohash; String get ward;@JsonKey(name: 'is_anonymous') bool get isAnonymous;@JsonKey(name: 'is_fuzzed') bool get isFuzzed;@JsonKey(name: 'is_shielded') bool get isShielded;@JsonKey(name: 'reporter_label') String get reporterLabel;@JsonKey(name: 'reporter_name') String? get reporterName;@JsonKey(name: 'reporter_photo_url') String? get reporterPhotoUrl;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'acknowledged_at') DateTime? get acknowledgedAt;@JsonKey(name: 'resolved_at') DateTime? get resolvedAt;@JsonKey(name: 'resolution_proof') String? get resolutionProof;@JsonKey(name: 'resolution_notes') String? get resolutionNotes;@JsonKey(name: 'upvotes_count') int get upvotesCount;@JsonKey(name: 'confirmations_count') int get confirmationsCount;@JsonKey(name: 'disputes_count') int get disputesCount;@JsonKey(name: 'has_upvoted') bool get hasUpvoted;@JsonKey(name: 'media_urls') List<String> get mediaUrls;@JsonKey(name: 'video_url') String? get videoUrl;@JsonKey(name: 'reporter_id') int? get reporterId;
/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueCopyWith<Issue> get copyWith => _$IssueCopyWithImpl<Issue>(this as Issue, _$identity);

  /// Serializes this Issue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Issue&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&(identical(other.ward, ward) || other.ward == ward)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.isFuzzed, isFuzzed) || other.isFuzzed == isFuzzed)&&(identical(other.isShielded, isShielded) || other.isShielded == isShielded)&&(identical(other.reporterLabel, reporterLabel) || other.reporterLabel == reporterLabel)&&(identical(other.reporterName, reporterName) || other.reporterName == reporterName)&&(identical(other.reporterPhotoUrl, reporterPhotoUrl) || other.reporterPhotoUrl == reporterPhotoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolutionProof, resolutionProof) || other.resolutionProof == resolutionProof)&&(identical(other.resolutionNotes, resolutionNotes) || other.resolutionNotes == resolutionNotes)&&(identical(other.upvotesCount, upvotesCount) || other.upvotesCount == upvotesCount)&&(identical(other.confirmationsCount, confirmationsCount) || other.confirmationsCount == confirmationsCount)&&(identical(other.disputesCount, disputesCount) || other.disputesCount == disputesCount)&&(identical(other.hasUpvoted, hasUpvoted) || other.hasUpvoted == hasUpvoted)&&const DeepCollectionEquality().equals(other.mediaUrls, mediaUrls)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,category,status,latitude,longitude,geohash,ward,isAnonymous,isFuzzed,isShielded,reporterLabel,reporterName,reporterPhotoUrl,createdAt,acknowledgedAt,resolvedAt,resolutionProof,resolutionNotes,upvotesCount,confirmationsCount,disputesCount,hasUpvoted,const DeepCollectionEquality().hash(mediaUrls),videoUrl,reporterId]);

@override
String toString() {
  return 'Issue(id: $id, title: $title, description: $description, category: $category, status: $status, latitude: $latitude, longitude: $longitude, geohash: $geohash, ward: $ward, isAnonymous: $isAnonymous, isFuzzed: $isFuzzed, isShielded: $isShielded, reporterLabel: $reporterLabel, reporterName: $reporterName, reporterPhotoUrl: $reporterPhotoUrl, createdAt: $createdAt, acknowledgedAt: $acknowledgedAt, resolvedAt: $resolvedAt, resolutionProof: $resolutionProof, resolutionNotes: $resolutionNotes, upvotesCount: $upvotesCount, confirmationsCount: $confirmationsCount, disputesCount: $disputesCount, hasUpvoted: $hasUpvoted, mediaUrls: $mediaUrls, videoUrl: $videoUrl, reporterId: $reporterId)';
}


}

/// @nodoc
abstract mixin class $IssueCopyWith<$Res>  {
  factory $IssueCopyWith(Issue value, $Res Function(Issue) _then) = _$IssueCopyWithImpl;
@useResult
$Res call({
 int id, String title, String description, String category, String status, double latitude, double longitude, String? geohash, String ward,@JsonKey(name: 'is_anonymous') bool isAnonymous,@JsonKey(name: 'is_fuzzed') bool isFuzzed,@JsonKey(name: 'is_shielded') bool isShielded,@JsonKey(name: 'reporter_label') String reporterLabel,@JsonKey(name: 'reporter_name') String? reporterName,@JsonKey(name: 'reporter_photo_url') String? reporterPhotoUrl,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'acknowledged_at') DateTime? acknowledgedAt,@JsonKey(name: 'resolved_at') DateTime? resolvedAt,@JsonKey(name: 'resolution_proof') String? resolutionProof,@JsonKey(name: 'resolution_notes') String? resolutionNotes,@JsonKey(name: 'upvotes_count') int upvotesCount,@JsonKey(name: 'confirmations_count') int confirmationsCount,@JsonKey(name: 'disputes_count') int disputesCount,@JsonKey(name: 'has_upvoted') bool hasUpvoted,@JsonKey(name: 'media_urls') List<String> mediaUrls,@JsonKey(name: 'video_url') String? videoUrl,@JsonKey(name: 'reporter_id') int? reporterId
});




}
/// @nodoc
class _$IssueCopyWithImpl<$Res>
    implements $IssueCopyWith<$Res> {
  _$IssueCopyWithImpl(this._self, this._then);

  final Issue _self;
  final $Res Function(Issue) _then;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? status = null,Object? latitude = null,Object? longitude = null,Object? geohash = freezed,Object? ward = null,Object? isAnonymous = null,Object? isFuzzed = null,Object? isShielded = null,Object? reporterLabel = null,Object? reporterName = freezed,Object? reporterPhotoUrl = freezed,Object? createdAt = null,Object? acknowledgedAt = freezed,Object? resolvedAt = freezed,Object? resolutionProof = freezed,Object? resolutionNotes = freezed,Object? upvotesCount = null,Object? confirmationsCount = null,Object? disputesCount = null,Object? hasUpvoted = null,Object? mediaUrls = null,Object? videoUrl = freezed,Object? reporterId = freezed,}) {
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
as int?,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String description,  String category,  String status,  double latitude,  double longitude,  String? geohash,  String ward, @JsonKey(name: 'is_anonymous')  bool isAnonymous, @JsonKey(name: 'is_fuzzed')  bool isFuzzed, @JsonKey(name: 'is_shielded')  bool isShielded, @JsonKey(name: 'reporter_label')  String reporterLabel, @JsonKey(name: 'reporter_name')  String? reporterName, @JsonKey(name: 'reporter_photo_url')  String? reporterPhotoUrl, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'acknowledged_at')  DateTime? acknowledgedAt, @JsonKey(name: 'resolved_at')  DateTime? resolvedAt, @JsonKey(name: 'resolution_proof')  String? resolutionProof, @JsonKey(name: 'resolution_notes')  String? resolutionNotes, @JsonKey(name: 'upvotes_count')  int upvotesCount, @JsonKey(name: 'confirmations_count')  int confirmationsCount, @JsonKey(name: 'disputes_count')  int disputesCount, @JsonKey(name: 'has_upvoted')  bool hasUpvoted, @JsonKey(name: 'media_urls')  List<String> mediaUrls, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'reporter_id')  int? reporterId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Issue() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.status,_that.latitude,_that.longitude,_that.geohash,_that.ward,_that.isAnonymous,_that.isFuzzed,_that.isShielded,_that.reporterLabel,_that.reporterName,_that.reporterPhotoUrl,_that.createdAt,_that.acknowledgedAt,_that.resolvedAt,_that.resolutionProof,_that.resolutionNotes,_that.upvotesCount,_that.confirmationsCount,_that.disputesCount,_that.hasUpvoted,_that.mediaUrls,_that.videoUrl,_that.reporterId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String description,  String category,  String status,  double latitude,  double longitude,  String? geohash,  String ward, @JsonKey(name: 'is_anonymous')  bool isAnonymous, @JsonKey(name: 'is_fuzzed')  bool isFuzzed, @JsonKey(name: 'is_shielded')  bool isShielded, @JsonKey(name: 'reporter_label')  String reporterLabel, @JsonKey(name: 'reporter_name')  String? reporterName, @JsonKey(name: 'reporter_photo_url')  String? reporterPhotoUrl, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'acknowledged_at')  DateTime? acknowledgedAt, @JsonKey(name: 'resolved_at')  DateTime? resolvedAt, @JsonKey(name: 'resolution_proof')  String? resolutionProof, @JsonKey(name: 'resolution_notes')  String? resolutionNotes, @JsonKey(name: 'upvotes_count')  int upvotesCount, @JsonKey(name: 'confirmations_count')  int confirmationsCount, @JsonKey(name: 'disputes_count')  int disputesCount, @JsonKey(name: 'has_upvoted')  bool hasUpvoted, @JsonKey(name: 'media_urls')  List<String> mediaUrls, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'reporter_id')  int? reporterId)  $default,) {final _that = this;
switch (_that) {
case _Issue():
return $default(_that.id,_that.title,_that.description,_that.category,_that.status,_that.latitude,_that.longitude,_that.geohash,_that.ward,_that.isAnonymous,_that.isFuzzed,_that.isShielded,_that.reporterLabel,_that.reporterName,_that.reporterPhotoUrl,_that.createdAt,_that.acknowledgedAt,_that.resolvedAt,_that.resolutionProof,_that.resolutionNotes,_that.upvotesCount,_that.confirmationsCount,_that.disputesCount,_that.hasUpvoted,_that.mediaUrls,_that.videoUrl,_that.reporterId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String description,  String category,  String status,  double latitude,  double longitude,  String? geohash,  String ward, @JsonKey(name: 'is_anonymous')  bool isAnonymous, @JsonKey(name: 'is_fuzzed')  bool isFuzzed, @JsonKey(name: 'is_shielded')  bool isShielded, @JsonKey(name: 'reporter_label')  String reporterLabel, @JsonKey(name: 'reporter_name')  String? reporterName, @JsonKey(name: 'reporter_photo_url')  String? reporterPhotoUrl, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'acknowledged_at')  DateTime? acknowledgedAt, @JsonKey(name: 'resolved_at')  DateTime? resolvedAt, @JsonKey(name: 'resolution_proof')  String? resolutionProof, @JsonKey(name: 'resolution_notes')  String? resolutionNotes, @JsonKey(name: 'upvotes_count')  int upvotesCount, @JsonKey(name: 'confirmations_count')  int confirmationsCount, @JsonKey(name: 'disputes_count')  int disputesCount, @JsonKey(name: 'has_upvoted')  bool hasUpvoted, @JsonKey(name: 'media_urls')  List<String> mediaUrls, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'reporter_id')  int? reporterId)?  $default,) {final _that = this;
switch (_that) {
case _Issue() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.status,_that.latitude,_that.longitude,_that.geohash,_that.ward,_that.isAnonymous,_that.isFuzzed,_that.isShielded,_that.reporterLabel,_that.reporterName,_that.reporterPhotoUrl,_that.createdAt,_that.acknowledgedAt,_that.resolvedAt,_that.resolutionProof,_that.resolutionNotes,_that.upvotesCount,_that.confirmationsCount,_that.disputesCount,_that.hasUpvoted,_that.mediaUrls,_that.videoUrl,_that.reporterId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Issue extends Issue {
  const _Issue({required this.id, required this.title, required this.description, required this.category, required this.status, required this.latitude, required this.longitude, this.geohash, this.ward = 'Ward 45, Urban Central', @JsonKey(name: 'is_anonymous') required this.isAnonymous, @JsonKey(name: 'is_fuzzed') this.isFuzzed = false, @JsonKey(name: 'is_shielded') this.isShielded = false, @JsonKey(name: 'reporter_label') required this.reporterLabel, @JsonKey(name: 'reporter_name') this.reporterName, @JsonKey(name: 'reporter_photo_url') this.reporterPhotoUrl, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'acknowledged_at') this.acknowledgedAt, @JsonKey(name: 'resolved_at') this.resolvedAt, @JsonKey(name: 'resolution_proof') this.resolutionProof, @JsonKey(name: 'resolution_notes') this.resolutionNotes, @JsonKey(name: 'upvotes_count') this.upvotesCount = 0, @JsonKey(name: 'confirmations_count') this.confirmationsCount = 0, @JsonKey(name: 'disputes_count') this.disputesCount = 0, @JsonKey(name: 'has_upvoted') this.hasUpvoted = false, @JsonKey(name: 'media_urls')  List<String> mediaUrls = const <String>[], @JsonKey(name: 'video_url') this.videoUrl, @JsonKey(name: 'reporter_id') this.reporterId}): _mediaUrls = mediaUrls,super._();
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Issue&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&(identical(other.ward, ward) || other.ward == ward)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.isFuzzed, isFuzzed) || other.isFuzzed == isFuzzed)&&(identical(other.isShielded, isShielded) || other.isShielded == isShielded)&&(identical(other.reporterLabel, reporterLabel) || other.reporterLabel == reporterLabel)&&(identical(other.reporterName, reporterName) || other.reporterName == reporterName)&&(identical(other.reporterPhotoUrl, reporterPhotoUrl) || other.reporterPhotoUrl == reporterPhotoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolutionProof, resolutionProof) || other.resolutionProof == resolutionProof)&&(identical(other.resolutionNotes, resolutionNotes) || other.resolutionNotes == resolutionNotes)&&(identical(other.upvotesCount, upvotesCount) || other.upvotesCount == upvotesCount)&&(identical(other.confirmationsCount, confirmationsCount) || other.confirmationsCount == confirmationsCount)&&(identical(other.disputesCount, disputesCount) || other.disputesCount == disputesCount)&&(identical(other.hasUpvoted, hasUpvoted) || other.hasUpvoted == hasUpvoted)&&const DeepCollectionEquality().equals(other._mediaUrls, _mediaUrls)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,category,status,latitude,longitude,geohash,ward,isAnonymous,isFuzzed,isShielded,reporterLabel,reporterName,reporterPhotoUrl,createdAt,acknowledgedAt,resolvedAt,resolutionProof,resolutionNotes,upvotesCount,confirmationsCount,disputesCount,hasUpvoted,const DeepCollectionEquality().hash(_mediaUrls),videoUrl,reporterId]);

@override
String toString() {
  return 'Issue(id: $id, title: $title, description: $description, category: $category, status: $status, latitude: $latitude, longitude: $longitude, geohash: $geohash, ward: $ward, isAnonymous: $isAnonymous, isFuzzed: $isFuzzed, isShielded: $isShielded, reporterLabel: $reporterLabel, reporterName: $reporterName, reporterPhotoUrl: $reporterPhotoUrl, createdAt: $createdAt, acknowledgedAt: $acknowledgedAt, resolvedAt: $resolvedAt, resolutionProof: $resolutionProof, resolutionNotes: $resolutionNotes, upvotesCount: $upvotesCount, confirmationsCount: $confirmationsCount, disputesCount: $disputesCount, hasUpvoted: $hasUpvoted, mediaUrls: $mediaUrls, videoUrl: $videoUrl, reporterId: $reporterId)';
}


}

/// @nodoc
abstract mixin class _$IssueCopyWith<$Res> implements $IssueCopyWith<$Res> {
  factory _$IssueCopyWith(_Issue value, $Res Function(_Issue) _then) = __$IssueCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String description, String category, String status, double latitude, double longitude, String? geohash, String ward,@JsonKey(name: 'is_anonymous') bool isAnonymous,@JsonKey(name: 'is_fuzzed') bool isFuzzed,@JsonKey(name: 'is_shielded') bool isShielded,@JsonKey(name: 'reporter_label') String reporterLabel,@JsonKey(name: 'reporter_name') String? reporterName,@JsonKey(name: 'reporter_photo_url') String? reporterPhotoUrl,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'acknowledged_at') DateTime? acknowledgedAt,@JsonKey(name: 'resolved_at') DateTime? resolvedAt,@JsonKey(name: 'resolution_proof') String? resolutionProof,@JsonKey(name: 'resolution_notes') String? resolutionNotes,@JsonKey(name: 'upvotes_count') int upvotesCount,@JsonKey(name: 'confirmations_count') int confirmationsCount,@JsonKey(name: 'disputes_count') int disputesCount,@JsonKey(name: 'has_upvoted') bool hasUpvoted,@JsonKey(name: 'media_urls') List<String> mediaUrls,@JsonKey(name: 'video_url') String? videoUrl,@JsonKey(name: 'reporter_id') int? reporterId
});




}
/// @nodoc
class __$IssueCopyWithImpl<$Res>
    implements _$IssueCopyWith<$Res> {
  __$IssueCopyWithImpl(this._self, this._then);

  final _Issue _self;
  final $Res Function(_Issue) _then;

/// Create a copy of Issue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? status = null,Object? latitude = null,Object? longitude = null,Object? geohash = freezed,Object? ward = null,Object? isAnonymous = null,Object? isFuzzed = null,Object? isShielded = null,Object? reporterLabel = null,Object? reporterName = freezed,Object? reporterPhotoUrl = freezed,Object? createdAt = null,Object? acknowledgedAt = freezed,Object? resolvedAt = freezed,Object? resolutionProof = freezed,Object? resolutionNotes = freezed,Object? upvotesCount = null,Object? confirmationsCount = null,Object? disputesCount = null,Object? hasUpvoted = null,Object? mediaUrls = null,Object? videoUrl = freezed,Object? reporterId = freezed,}) {
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
as int?,
  ));
}


}

// dart format on
