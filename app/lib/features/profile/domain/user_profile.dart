class UserProfile {
  final Object id;
  final String? phone;
  final String? email;
  final String? displayName;
  final String? username;
  final String? dateOfBirth;
  final String? photoUrl;
  final String? bio;
  final int displayNameChangesRemaining;
  final DateTime? bioNextChangeAllowedAt;
  final DateTime? photoNextChangeAllowedAt;
  final String anonymousIdentity;
  final String anonId;
  final bool isGuest;
  final int issuesCount;
  final int upvotesCount;
  final int quorumVotesCount;

  const UserProfile({
    required this.id,
    this.phone,
    this.email,
    this.displayName,
    this.username,
    this.dateOfBirth,
    this.photoUrl,
    this.bio,
    this.displayNameChangesRemaining = 2,
    this.bioNextChangeAllowedAt,
    this.photoNextChangeAllowedAt,
    required this.anonymousIdentity,
    required this.anonId,
    this.isGuest = false,
    this.issuesCount = 0,
    this.upvotesCount = 0,
    this.quorumVotesCount = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final anon = (json['anon_id'] ?? json['anonymous_identity'] ?? '') as String;
    return UserProfile(
      id: json['id'] ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      username: json['username'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      photoUrl: json['photo_url'] as String?,
      bio: json['bio'] as String?,
      displayNameChangesRemaining:
          (json['display_name_changes_remaining'] as num?)?.toInt() ?? 2,
      bioNextChangeAllowedAt:
          _parseNullableDateTime(json['bio_next_change_allowed_at']),
      photoNextChangeAllowedAt:
          _parseNullableDateTime(json['photo_next_change_allowed_at']),
      anonymousIdentity: (json['anonymous_identity'] ?? anon) as String,
      anonId: anon,
      isGuest: json['is_guest'] as bool? ?? false,
      issuesCount: (json['issues_count'] as num?)?.toInt() ?? 0,
      upvotesCount: (json['upvotes_count'] as num?)?.toInt() ?? 0,
      quorumVotesCount: (json['quorum_votes_count'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseNullableDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}