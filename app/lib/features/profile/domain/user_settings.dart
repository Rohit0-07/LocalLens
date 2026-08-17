class UserSettings {
  // Notification Preferences
  final bool pushNotifications;
  final bool dailyWardDigest;
  final bool statusChangeAlerts;
  final bool communityVerificationRequests;
  final bool commentReplies;
  final bool hapticFeedback;

  // Privacy & Anonymity
  final bool defaultPostAnonymously;
  final bool locationFuzzingByDefault;
  final bool shieldedModeByDefault;
  final bool photoExifScrubber;

  // Appearance & Display
  final String language; // 'en', 'hi', 'mr', 'ta', 'te'
  final bool highContrastMode;

  // Data & Storage
  final bool wifiOnlyMediaDownload;
  final int syncWorkerIntervalMinutes; // e.g. 5, 15, 30, 60
  final double offlineCacheSizeMb;

  // Account
  final String profileAlias;
  final bool showDisplayName;

  const UserSettings({
    this.pushNotifications = true,
    this.dailyWardDigest = true,
    this.statusChangeAlerts = true,
    this.communityVerificationRequests = true,
    this.commentReplies = true,
    this.hapticFeedback = true,
    this.defaultPostAnonymously = true,
    this.locationFuzzingByDefault = false,
    this.shieldedModeByDefault = false,
    this.photoExifScrubber = true,
    this.language = 'en',
    this.highContrastMode = false,
    this.wifiOnlyMediaDownload = false,
    this.syncWorkerIntervalMinutes = 15,
    this.offlineCacheSizeMb = 18.4,
    this.profileAlias = '',
    this.showDisplayName = true,
  });

  UserSettings copyWith({
    bool? pushNotifications,
    bool? dailyWardDigest,
    bool? statusChangeAlerts,
    bool? communityVerificationRequests,
    bool? commentReplies,
    bool? hapticFeedback,
    bool? defaultPostAnonymously,
    bool? locationFuzzingByDefault,
    bool? shieldedModeByDefault,
    bool? photoExifScrubber,
    String? language,
    bool? highContrastMode,
    bool? wifiOnlyMediaDownload,
    int? syncWorkerIntervalMinutes,
    double? offlineCacheSizeMb,
    String? profileAlias,
    bool? showDisplayName,
  }) {
    return UserSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      dailyWardDigest: dailyWardDigest ?? this.dailyWardDigest,
      statusChangeAlerts: statusChangeAlerts ?? this.statusChangeAlerts,
      communityVerificationRequests:
          communityVerificationRequests ?? this.communityVerificationRequests,
      commentReplies: commentReplies ?? this.commentReplies,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      defaultPostAnonymously:
          defaultPostAnonymously ?? this.defaultPostAnonymously,
      locationFuzzingByDefault:
          locationFuzzingByDefault ?? this.locationFuzzingByDefault,
      shieldedModeByDefault:
          shieldedModeByDefault ?? this.shieldedModeByDefault,
      photoExifScrubber: photoExifScrubber ?? this.photoExifScrubber,
      language: language ?? this.language,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      wifiOnlyMediaDownload:
          wifiOnlyMediaDownload ?? this.wifiOnlyMediaDownload,
      syncWorkerIntervalMinutes:
          syncWorkerIntervalMinutes ?? this.syncWorkerIntervalMinutes,
      offlineCacheSizeMb: offlineCacheSizeMb ?? this.offlineCacheSizeMb,
      profileAlias: profileAlias ?? this.profileAlias,
      showDisplayName: showDisplayName ?? this.showDisplayName,
    );
  }

  Map<String, dynamic> toJson() => {
        'pushNotifications': pushNotifications,
        'dailyWardDigest': dailyWardDigest,
        'statusChangeAlerts': statusChangeAlerts,
        'communityVerificationRequests': communityVerificationRequests,
        'commentReplies': commentReplies,
        'hapticFeedback': hapticFeedback,
        'defaultPostAnonymously': defaultPostAnonymously,
        'locationFuzzingByDefault': locationFuzzingByDefault,
        'shieldedModeByDefault': shieldedModeByDefault,
        'photoExifScrubber': photoExifScrubber,
        'language': language,
        'highContrastMode': highContrastMode,
        'wifiOnlyMediaDownload': wifiOnlyMediaDownload,
        'syncWorkerIntervalMinutes': syncWorkerIntervalMinutes,
        'offlineCacheSizeMb': offlineCacheSizeMb,
        'profileAlias': profileAlias,
        'showDisplayName': showDisplayName,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      dailyWardDigest: json['dailyWardDigest'] as bool? ?? true,
      statusChangeAlerts: json['statusChangeAlerts'] as bool? ?? true,
      communityVerificationRequests:
          json['communityVerificationRequests'] as bool? ?? true,
      commentReplies: json['commentReplies'] as bool? ?? true,
      hapticFeedback: json['hapticFeedback'] as bool? ?? true,
      defaultPostAnonymously: json['defaultPostAnonymously'] as bool? ?? true,
      locationFuzzingByDefault:
          json['locationFuzzingByDefault'] as bool? ?? false,
      shieldedModeByDefault: json['shieldedModeByDefault'] as bool? ?? false,
      photoExifScrubber: json['photoExifScrubber'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
      highContrastMode: json['highContrastMode'] as bool? ?? false,
      wifiOnlyMediaDownload: json['wifiOnlyMediaDownload'] as bool? ?? false,
      syncWorkerIntervalMinutes:
          (json['syncWorkerIntervalMinutes'] as num?)?.toInt() ?? 15,
      offlineCacheSizeMb:
          (json['offlineCacheSizeMb'] as num?)?.toDouble() ?? 18.4,
      profileAlias: json['profileAlias'] as String? ?? '',
      showDisplayName: json['showDisplayName'] as bool? ?? true,
    );
  }
}
