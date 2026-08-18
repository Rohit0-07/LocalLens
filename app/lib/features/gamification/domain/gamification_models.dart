class BadgeItem {
  final String key;
  final String name;
  final String description;
  final String iconName;
  final String category;
  final int threshold;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const BadgeItem({
    required this.key,
    required this.name,
    required this.description,
    required this.iconName,
    required this.category,
    required this.threshold,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    final keyVal = (json['key'] ?? json['badge_key'] ?? json['badge_id'] ?? json['id'] ?? '').toString();
    final unlockedAtStr = json['unlocked_at'] as String?;
    final unlockedAt = unlockedAtStr != null ? DateTime.tryParse(unlockedAtStr) : null;
    final isUnlocked = json['is_unlocked'] as bool? ?? (unlockedAt != null);

    return BadgeItem(
      key: keyVal,
      name: (json['name'] ?? keyVal).toString(),
      description: (json['description'] ?? '').toString(),
      iconName: (json['icon_name'] ?? 'lock').toString(),
      category: (json['category'] ?? 'general').toString(),
      threshold: (json['threshold'] as num?)?.toInt() ?? 1,
      isUnlocked: isUnlocked,
      unlockedAt: unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'badge_id': key,
        'badge_key': key,
        'name': name,
        'description': description,
        'icon_name': iconName,
        'category': category,
        'threshold': threshold,
        'is_unlocked': isUnlocked,
        'unlocked_at': unlockedAt?.toIso8601String(),
      };
}

class ActivityCounts {
  final int issuesCreated;
  final int upvotesCast;
  final int quorumVotesCast;
  final int commentsPosted;

  const ActivityCounts({
    this.issuesCreated = 0,
    this.upvotesCast = 0,
    this.quorumVotesCast = 0,
    this.commentsPosted = 0,
  });

  factory ActivityCounts.fromJson(Map<String, dynamic> json) {
    return ActivityCounts(
      issuesCreated: (json['issues_created'] as num?)?.toInt() ?? 0,
      upvotesCast: (json['upvotes_cast'] as num?)?.toInt() ?? 0,
      quorumVotesCast: (json['quorum_votes_cast'] as num?)?.toInt() ?? 0,
      commentsPosted: (json['comments_posted'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'issues_created': issuesCreated,
        'upvotes_cast': upvotesCast,
        'quorum_votes_cast': quorumVotesCast,
        'comments_posted': commentsPosted,
      };
}

class GamificationProfile {
  final int? userId;
  final bool isGuest;
  final int impactScore;
  final int level;
  final String levelName;
  final int? nextLevelScore;
  final int streakDays;
  final String? lastStreakDate;
  final bool canClaimStreak;
  final List<BadgeItem> badges;
  final ActivityCounts activityCounts;

  const GamificationProfile({
    this.userId,
    required this.isGuest,
    required this.impactScore,
    required this.level,
    required this.levelName,
    this.nextLevelScore,
    required this.streakDays,
    this.lastStreakDate,
    required this.canClaimStreak,
    required this.badges,
    required this.activityCounts,
  });

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    final badgesList = (json['badges'] as List<dynamic>?)
            ?.map((e) => BadgeItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final actJson = json['activity_counts'] as Map<String, dynamic>?;
    final activityCounts = actJson != null
        ? ActivityCounts.fromJson(actJson)
        : const ActivityCounts();

    return GamificationProfile(
      userId: (json['user_id'] as num?)?.toInt(),
      isGuest: json['is_guest'] as bool? ?? false,
      impactScore: (json['impact_score'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelName: (json['level_name'] as String?) ?? 'Civic Rookie',
      nextLevelScore: (json['next_level_score'] as num?)?.toInt(),
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      lastStreakDate: json['last_streak_date'] as String?,
      canClaimStreak: json['can_claim_streak'] as bool? ?? false,
      badges: badgesList,
      activityCounts: activityCounts,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'is_guest': isGuest,
        'impact_score': impactScore,
        'level': level,
        'level_name': levelName,
        'next_level_score': nextLevelScore,
        'streak_days': streakDays,
        'last_streak_date': lastStreakDate,
        'can_claim_streak': canClaimStreak,
        'badges': badges.map((b) => b.toJson()).toList(),
        'activity_counts': activityCounts.toJson(),
      };

  GamificationProfile copyWith({
    int? userId,
    bool? isGuest,
    int? impactScore,
    int? level,
    String? levelName,
    int? nextLevelScore,
    int? streakDays,
    String? lastStreakDate,
    bool? canClaimStreak,
    List<BadgeItem>? badges,
    ActivityCounts? activityCounts,
  }) {
    return GamificationProfile(
      userId: userId ?? this.userId,
      isGuest: isGuest ?? this.isGuest,
      impactScore: impactScore ?? this.impactScore,
      level: level ?? this.level,
      levelName: levelName ?? this.levelName,
      nextLevelScore: nextLevelScore ?? this.nextLevelScore,
      streakDays: streakDays ?? this.streakDays,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      canClaimStreak: canClaimStreak ?? this.canClaimStreak,
      badges: badges ?? this.badges,
      activityCounts: activityCounts ?? this.activityCounts,
    );
  }
}

class StreakClaimResult {
  final int streakDays;
  final int pointsEarned;
  final int impactScore;
  final String message;

  const StreakClaimResult({
    required this.streakDays,
    required this.pointsEarned,
    required this.impactScore,
    required this.message,
  });

  factory StreakClaimResult.fromJson(Map<String, dynamic> json) {
    return StreakClaimResult(
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 15,
      impactScore: (json['impact_score'] as num?)?.toInt() ?? 0,
      message: (json['message'] as String?) ?? 'Daily streak claimed!',
    );
  }

  Map<String, dynamic> toJson() => {
        'streak_days': streakDays,
        'points_earned': pointsEarned,
        'impact_score': impactScore,
        'message': message,
      };
}

class BadgeMetadata {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String category;
  final int threshold;

  const BadgeMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.category,
    required this.threshold,
  });

  factory BadgeMetadata.fromJson(Map<String, dynamic> json) {
    final idVal = (json['id'] ?? json['key'] ?? json['badge_key'] ?? '') as String;
    return BadgeMetadata(
      id: idVal,
      name: (json['name'] ?? idVal) as String,
      description: (json['description'] ?? '') as String,
      iconName: (json['icon_name'] ?? 'star') as String,
      category: (json['category'] ?? 'general') as String,
      threshold: (json['threshold'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': id,
        'name': name,
        'description': description,
        'icon_name': iconName,
        'category': category,
        'threshold': threshold,
      };
}
