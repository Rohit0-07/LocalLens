import '../../gamification/domain/gamification_models.dart';

class PublicUserProfile {
  final int userId;
  final String displayName;
  final String anonId;
  final String role; // 'Citizen', 'Ward Representative', 'Official'
  final bool isVerified;
  final String ward;
  final DateTime memberSince;
  final int impactPoints;
  final String level;
  final int issuesReported;
  final int verifiedResolutions;
  final int upvotesReceived;
  final List<BadgeItem> badges;

  const PublicUserProfile({
    required this.userId,
    required this.displayName,
    required this.anonId,
    this.role = 'Citizen',
    this.isVerified = true,
    this.ward = 'Ward 45, Urban Central',
    required this.memberSince,
    this.impactPoints = 0,
    this.level = 'Civic Rookie',
    this.issuesReported = 0,
    this.verifiedResolutions = 0,
    this.upvotesReceived = 0,
    this.badges = const [],
  });

  static String levelForPoints(int points) {
    if (points >= 1000) return 'Civic Legend';
    if (points >= 500) return 'District Champion';
    if (points >= 250) return 'Community Sentinel';
    if (points >= 100) return 'Neighborhood Scout';
    return 'Civic Rookie';
  }

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    final userId = (json['user_id'] ?? json['id'] as num?)?.toInt() ?? 0;
    final anonId = (json['anon_id'] ?? json['anonymous_identity'] ?? 'anon_$userId') as String;
    final displayName = (json['display_name'] ?? json['username'] ?? json['name'] ?? anonId) as String;
    final role = (json['role'] ?? 'Citizen') as String;
    final isVerified = json['is_verified'] as bool? ?? (role.toLowerCase() != 'guest');
    final ward = (json['ward'] ?? json['ward_name'] ?? 'Ward 45, Urban Central') as String;
    final memberSinceStr = json['member_since'] ?? json['created_at'] as String?;
    final memberSince = memberSinceStr != null
        ? (DateTime.tryParse(memberSinceStr) ?? DateTime(2026, 1, 1))
        : DateTime(2026, 1, 1);
    final impactPoints =
        (json['impact_points'] ?? json['impact_score'] ?? json['points'] as num?)?.toInt() ?? 0;
    final level = (json['level_name'] ?? json['level'] as String?) ?? levelForPoints(impactPoints);
    final issuesReported =
        (json['issues_reported'] ?? json['issues_count'] as num?)?.toInt() ?? 0;
    final verifiedResolutions =
        (json['verified_resolutions'] ?? json['resolutions_count'] as num?)?.toInt() ?? 0;
    final upvotesReceived =
        (json['upvotes_received'] ?? json['upvotes_count'] as num?)?.toInt() ?? 0;

    final badgesRaw = json['badges'] as List<dynamic>?;
    final badges = badgesRaw != null
        ? badgesRaw.map((b) => BadgeItem.fromJson(b as Map<String, dynamic>)).toList()
        : <BadgeItem>[];

    return PublicUserProfile(
      userId: userId,
      displayName: displayName,
      anonId: anonId,
      role: role,
      isVerified: isVerified,
      ward: ward,
      memberSince: memberSince,
      impactPoints: impactPoints,
      level: level,
      issuesReported: issuesReported,
      verifiedResolutions: verifiedResolutions,
      upvotesReceived: upvotesReceived,
      badges: badges,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'id': userId,
        'display_name': displayName,
        'anon_id': anonId,
        'role': role,
        'is_verified': isVerified,
        'ward': ward,
        'member_since': memberSince.toIso8601String(),
        'impact_points': impactPoints,
        'level': level,
        'issues_reported': issuesReported,
        'verified_resolutions': verifiedResolutions,
        'upvotes_received': upvotesReceived,
        'badges': badges.map((b) => b.toJson()).toList(),
      };
}
