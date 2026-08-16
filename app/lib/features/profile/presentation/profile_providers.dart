import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/storage/local_store.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../feed/domain/issue.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../gamification/domain/gamification_models.dart';
import '../domain/public_user_profile.dart';
import '../domain/user_profile.dart';
import '../domain/user_settings.dart';

export '../domain/public_user_profile.dart';
export '../domain/user_profile.dart';
export '../domain/user_settings.dart';

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final session = ref.watch(sessionProvider);
  final config = ref.watch(appConfigProvider);

  if (session == null) {
    return const UserProfile(
      id: 'guest',
      anonymousIdentity: 'guest_anon',
      anonId: 'guest_anon',
      isGuest: true,
    );
  }

  if (config.useMockAuth) {
    return UserProfile(
      id: session.userId,
      phone: session.isGuest ? null : '+919876543210',
      email: null,
      displayName: session.isGuest ? null : 'Demo Resident',
      username: session.isGuest ? null : 'demo_resident',
      anonymousIdentity: session.anonId ?? 'anon_mock_123',
      anonId: session.anonId ?? 'anon_mock_123',
      isGuest: session.isGuest,
      issuesCount: session.isGuest ? 0 : 3,
      upvotesCount: session.isGuest ? 0 : 12,
      quorumVotesCount: session.isGuest ? 0 : 5,
    );
  }

  final client = ref.watch(apiClientProvider);
  final data = await client.getJson('/auth/me');
  return UserProfile.fromJson(data as Map<String, dynamic>);
});

/// Filter state for user's reported issues: 'all', 'active', 'resolved'
final myIssuesFilterProvider = StateProvider<String>((ref) => 'all');

/// Fetches issues reported by the currently authenticated user
final myIssuesProvider = FutureProvider<List<Issue>>((ref) async {
  final session = ref.watch(sessionProvider);
  final feedRepo = ref.watch(feedRepositoryProvider);
  final filter = ref.watch(myIssuesFilterProvider);
  final config = ref.watch(appConfigProvider);

  if (session == null || session.isGuest) {
    return const [];
  }

  if (config.useMockAuth) {
    final mockIssues = [
      Issue(
        id: 101,
        title: 'Broken water pipeline leaking on 14th Cross',
        description: 'Large puddle forming near school gate.',
        category: 'water',
        status: 'unacknowledged',
        latitude: 19.0760,
        longitude: 72.8777,
        ward: 'Ward 45, Urban Central',
        isAnonymous: true,
        reporterLabel: 'Anonymous Citizen',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        upvotesCount: 7,
      ),
      Issue(
        id: 102,
        title: 'Street lights malfunctioning on Main Boulevard',
        description: 'Entire block is dark after 7 PM.',
        category: 'lighting',
        status: 'escalating',
        latitude: 19.0762,
        longitude: 72.8780,
        ward: 'Ward 45, Urban Central',
        isAnonymous: false,
        reporterLabel: 'Local Resident',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        upvotesCount: 19,
      ),
      Issue(
        id: 103,
        title: 'Deep pothole filled after road repair',
        description: 'Corporation completed repair work.',
        category: 'road',
        status: 'resolved',
        latitude: 19.0755,
        longitude: 72.8790,
        ward: 'Ward 45, Urban Central',
        isAnonymous: false,
        reporterLabel: 'Local Resident',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
        upvotesCount: 42,
      ),
    ];

    if (filter == 'active') {
      return mockIssues.where((i) => i.status != 'resolved').toList();
    } else if (filter == 'resolved') {
      return mockIssues.where((i) => i.status == 'resolved').toList();
    }
    return mockIssues;
  }

  final statusParam = filter == 'all' ? null : filter;
  final issues = await feedRepo.fetchUserIssues(status: statusParam);
  if (filter == 'active') {
    return issues.where((i) => i.status != 'resolved').toList();
  } else if (filter == 'resolved') {
    return issues.where((i) => i.status == 'resolved').toList();
  }
  return issues;
});

/// Fetches public profile for any user ID
final publicProfileProvider =
    FutureProvider.family<PublicUserProfile, int>((ref, userId) async {
  final config = ref.watch(appConfigProvider);
  final feedRepo = ref.watch(feedRepositoryProvider);

  if (config.useMockAuth) {
    return PublicUserProfile(
      userId: userId,
      displayName: userId == 42 ? 'Aarav Sharma' : 'Citizen #$userId',
      anonId: 'anon_${userId.toString().padLeft(4, '0')}',
      role: userId == 42 ? 'Ward Representative' : 'Citizen',
      isVerified: true,
      ward: 'Ward 45, Urban Central',
      memberSince: DateTime(2025, 6, 15),
      impactPoints: 340,
      level: 'Community Sentinel',
      issuesReported: 8,
      verifiedResolutions: 6,
      upvotesReceived: 92,
      badges: const [
        BadgeItem(
          key: 'first_report',
          name: 'First Alert',
          description: 'Reported first civic issue',
          iconName: 'flag',
          category: 'reporting',
          threshold: 1,
          isUnlocked: true,
        ),
        BadgeItem(
          key: 'community_hero',
          name: 'Community Sentinel',
          description: 'Earned 250+ impact points',
          iconName: 'shield',
          category: 'impact',
          threshold: 250,
          isUnlocked: true,
        ),
        BadgeItem(
          key: 'active_voter',
          name: 'Verification Master',
          description: 'Participated in 5 verification votes',
          iconName: 'check_circle',
          category: 'quorum',
          threshold: 5,
          isUnlocked: true,
        ),
      ],
    );
  }

  try {
    final raw = await feedRepo.fetchPublicUserProfile(userId);
    return PublicUserProfile.fromJson(raw);
  } catch (_) {
    return PublicUserProfile(
      userId: userId,
      displayName: 'Citizen #$userId',
      anonId: 'anon_$userId',
      memberSince: DateTime(2026, 1, 1),
    );
  }
});

/// Fetches public issues reported by a specific user ID
final publicUserIssuesProvider =
    FutureProvider.family<List<Issue>, int>((ref, userId) async {
  final config = ref.watch(appConfigProvider);
  final feedRepo = ref.watch(feedRepositoryProvider);

  if (config.useMockAuth) {
    return [
      Issue(
        id: 201,
        title: 'Damaged footpath tiles near park entrance',
        description: 'Multiple tiles broken creating tripping hazard.',
        category: 'road',
        status: 'escalating',
        latitude: 19.0760,
        longitude: 72.8777,
        ward: 'Ward 45, Urban Central',
        isAnonymous: false,
        reporterLabel: 'Citizen #$userId',
        reporterId: userId,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        upvotesCount: 14,
      ),
      Issue(
        id: 202,
        title: 'Overflowing garbage bin cleared by sanitation crew',
        description: 'Bin cleared and sanitized.',
        category: 'waste',
        status: 'resolved',
        latitude: 19.0770,
        longitude: 72.8785,
        ward: 'Ward 45, Urban Central',
        isAnonymous: false,
        reporterLabel: 'Citizen #$userId',
        reporterId: userId,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 2)),
        upvotesCount: 28,
      ),
    ];
  }

  try {
    return await feedRepo.fetchUserIssues(userId: userId);
  } catch (_) {
    return const [];
  }
});

/// Fine-grained user settings provider
final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  final store = ref.watch(localStoreProvider);
  return UserSettingsNotifier(store);
});

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  final LocalStore _store;

  UserSettingsNotifier(this._store) : super(const UserSettings()) {
    _load();
  }

  void _load() {
    try {
      final raw = _store.getString('user_settings_json');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        state = UserSettings.fromJson(map);
      }
    } catch (_) {}
  }

  Future<void> _save(UserSettings settings) async {
    state = settings;
    try {
      await _store.setString(
          'user_settings_json', jsonEncode(settings.toJson()));
    } catch (_) {}
  }

  Future<void> setPushNotifications(bool val) =>
      _save(state.copyWith(pushNotifications: val));
  Future<void> setDailyWardDigest(bool val) =>
      _save(state.copyWith(dailyWardDigest: val));
  Future<void> setStatusChangeAlerts(bool val) =>
      _save(state.copyWith(statusChangeAlerts: val));
  Future<void> setCommunityVerificationRequests(bool val) =>
      _save(state.copyWith(communityVerificationRequests: val));
  Future<void> setCommentReplies(bool val) =>
      _save(state.copyWith(commentReplies: val));
  Future<void> setHapticFeedback(bool val) =>
      _save(state.copyWith(hapticFeedback: val));
  Future<void> setDefaultPostAnonymously(bool val) =>
      _save(state.copyWith(defaultPostAnonymously: val));
  Future<void> setLocationFuzzingByDefault(bool val) =>
      _save(state.copyWith(locationFuzzingByDefault: val));
  Future<void> setShieldedModeByDefault(bool val) =>
      _save(state.copyWith(shieldedModeByDefault: val));
  Future<void> setPhotoExifScrubber(bool val) =>
      _save(state.copyWith(photoExifScrubber: val));
  Future<void> setLanguage(String val) => _save(state.copyWith(language: val));
  Future<void> setHighContrastMode(bool val) =>
      _save(state.copyWith(highContrastMode: val));
  Future<void> setWifiOnlyMediaDownload(bool val) =>
      _save(state.copyWith(wifiOnlyMediaDownload: val));
  Future<void> setSyncWorkerInterval(int minutes) =>
      _save(state.copyWith(syncWorkerIntervalMinutes: minutes));
  Future<void> setProfileAlias(String alias) =>
      _save(state.copyWith(profileAlias: alias));
  Future<void> clearOfflineCache() =>
      _save(state.copyWith(offlineCacheSizeMb: 0.0));
}
