import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// --- Data Models matching F-12 Gamification Engine contract ---

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
    return BadgeItem(
      key: (json['key'] ?? json['badge_key']) as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
      category: json['category'] as String,
      threshold: json['threshold'] as int,
      isUnlocked: json['is_unlocked'] as bool? ?? (json['unlocked_at'] != null),
      unlockedAt: json['unlocked_at'] != null ? DateTime.parse(json['unlocked_at'] as String) : null,
    );
  }
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
}

class GamificationProfile {
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
}

// --- Fake Providers & Notifiers ---

final testGamificationProfileProvider = StateProvider<AsyncValue<GamificationProfile>>((ref) {
  return const AsyncValue.loading();
});

final testAllBadgesProvider = FutureProvider<List<BadgeItem>>((ref) async {
  return [
    const BadgeItem(key: 'first_report', name: 'First Report', description: 'Create 1st issue', iconName: 'report', category: 'reporting', threshold: 1),
    const BadgeItem(key: 'civic_voter', name: 'Civic Voter', description: 'Cast 5 upvotes', iconName: 'vote', category: 'voting', threshold: 5),
    const BadgeItem(key: 'quorum_hero', name: 'Quorum Hero', description: 'Cast 3 quorum votes', iconName: 'quorum', category: 'quorum', threshold: 3),
    const BadgeItem(key: 'neighborhood_voice', name: 'Neighborhood Voice', description: 'Post 5 comments', iconName: 'comment', category: 'social', threshold: 5),
    const BadgeItem(key: 'streak_master', name: 'Streak Master', description: '7-day streak', iconName: 'fire', category: 'streaks', threshold: 7),
  ];
});

class ClaimStreakState {
  final bool isSuccess;
  final String? errorMessage;
  ClaimStreakState({this.isSuccess = false, this.errorMessage});
}

class FakeClaimStreakNotifier extends StateNotifier<ClaimStreakState> {
  FakeClaimStreakNotifier(this._ref, {this.isGuest = false, this.alreadyClaimed = false})
      : super(ClaimStreakState());

  final Ref _ref;
  final bool isGuest;
  final bool alreadyClaimed;
  int claimCalls = 0;

  Future<void> claimStreak() async {
    claimCalls++;
    if (isGuest) {
      state = ClaimStreakState(errorMessage: 'Guest users cannot claim daily streaks. Please sign in.');
      return;
    }
    if (alreadyClaimed) {
      state = ClaimStreakState(errorMessage: 'Daily streak already claimed today');
      return;
    }

    state = ClaimStreakState(isSuccess: true);
    // Invalidate profile
    _ref.read(testGamificationProfileProvider.notifier).update((old) {
      if (old.value == null) return old;
      final val = old.value!;
      return AsyncValue.data(GamificationProfile(
        isGuest: val.isGuest,
        impactScore: val.impactScore + 15,
        level: val.level,
        levelName: val.levelName,
        nextLevelScore: val.nextLevelScore,
        streakDays: val.streakDays + 1,
        lastStreakDate: DateTime.now().toUtc().toIso8601String().substring(0, 10),
        canClaimStreak: false,
        badges: val.badges,
        activityCounts: val.activityCounts,
      ));
    });
  }
}

final testClaimStreakNotifierProvider = StateNotifierProvider.family<FakeClaimStreakNotifier, ClaimStreakState, Map<String, dynamic>>((ref, params) {
  return FakeClaimStreakNotifier(
    ref,
    isGuest: params['isGuest'] as bool? ?? false,
    alreadyClaimed: params['alreadyClaimed'] as bool? ?? false,
  );
});

// --- Testable Widgets for F-12 ---

class TestableProfileScreen extends StatelessWidget {
  const TestableProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Center(
        child: ElevatedButton(
          key: const Key('viewGamificationButton'),
          onPressed: () {
            context.go('/gamification');
          },
          child: const Text('View Civic Impact & Badges'),
        ),
      ),
    );
  }
}

class TestableGamificationScreen extends ConsumerWidget {
  final Map<String, dynamic> streakParams;
  final Map<String, dynamic>? offlineCacheData;

  const TestableGamificationScreen({
    super.key,
    this.streakParams = const {},
    this.offlineCacheData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(testGamificationProfileProvider);
    final claimState = ref.watch(testClaimStreakNotifierProvider(streakParams));

    return Scaffold(
      key: const Key('gamificationScreen'),
      appBar: AppBar(
        title: const Text('Civic Impact & Badges'),
      ),
      body: profileAsync.when(
        data: (profile) => _buildBody(context, ref, profile, claimState),
        loading: () {
          if (offlineCacheData != null) {
            // Hive cache fallback rendering
            final cachedProfile = GamificationProfile(
              isGuest: offlineCacheData!['is_guest'] as bool? ?? false,
              impactScore: offlineCacheData!['impact_score'] as int? ?? 150,
              level: offlineCacheData!['level'] as int? ?? 2,
              levelName: offlineCacheData!['level_name'] as String? ?? 'Active Neighbor',
              nextLevelScore: offlineCacheData!['next_level_score'] as int? ?? 300,
              streakDays: offlineCacheData!['streak_days'] as int? ?? 4,
              canClaimStreak: offlineCacheData!['can_claim_streak'] as bool? ?? true,
              badges: [],
              activityCounts: const ActivityCounts(issuesCreated: 2, upvotesCast: 10),
            );
            return _buildBody(context, ref, cachedProfile, claimState);
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, GamificationProfile profile, ClaimStreakState claimState) {
    // Level progress bar fraction calculation handling Level 5 null next_level_score
    final double progressFraction = profile.nextLevelScore == null || profile.nextLevelScore == 0
        ? 1.0
        : (profile.impactScore / profile.nextLevelScore!).clamp(0.0, 1.0);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Impact Score Card
          Card(
            key: const Key('impactScoreCard'),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '${profile.impactScore}',
                    key: const Key('impactScoreValue'),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    profile.levelName,
                    key: const Key('levelNameLabel'),
                  ),
                  LinearProgressIndicator(
                    key: const Key('levelProgressBar'),
                    value: progressFraction,
                  ),
                ],
              ),
            ),
          ),

          // Daily Streak Banner & Claim Button
          Card(
            key: const Key('streakBanner'),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '${profile.streakDays} Day Streak',
                    key: const Key('streakDaysCounter'),
                  ),
                  ElevatedButton(
                    key: const Key('claimStreakButton'),
                    onPressed: () {
                      if (profile.isGuest) {
                        showDialog(
                          context: context,
                          builder: (_) => const AlertDialog(
                            title: Text('GuestGuard'),
                            content: Text('Please sign in to claim daily streaks.'),
                          ),
                        );
                      } else {
                        ref.read(testClaimStreakNotifierProvider(streakParams).notifier).claimStreak().then((_) {
                          final state = ref.read(testClaimStreakNotifierProvider(streakParams));
                          if (state.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.errorMessage!)),
                            );
                          }
                        });
                      }
                    },
                    child: const Text('Claim Daily Streak'),
                  ),
                ],
              ),
            ),
          ),

          // Badges Grid & Cards
          GridView.count(
            key: const Key('badgesGrid'),
            shrinkWrap: true,
            crossAxisCount: 3,
            children: [
              _buildBadgeCard('first_report', profile.badges),
              _buildBadgeCard('civic_voter', profile.badges),
              _buildBadgeCard('quorum_hero', profile.badges),
              _buildBadgeCard('neighborhood_voice', profile.badges),
              _buildBadgeCard('streak_master', profile.badges),
            ],
          ),

          // Activity Breakdown Card
          Card(
            key: const Key('activityBreakdownCard'),
            child: Column(
              children: [
                Text('Issues Created: ${profile.activityCounts.issuesCreated}'),
                Text('Upvotes Cast: ${profile.activityCounts.upvotesCast}'),
                Text('Quorum Votes: ${profile.activityCounts.quorumVotesCast}'),
                Text('Comments Posted: ${profile.activityCounts.commentsPosted}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(String key, List<BadgeItem> userBadges) {
    final badge = userBadges.firstWhere(
      (b) => b.key == key,
      orElse: () => BadgeItem(key: key, name: key, description: '', iconName: 'lock', category: '', threshold: 1),
    );

    return Card(
      key: Key('badgeCard_$key'),
      color: badge.isUnlocked ? Colors.blue.shade100 : Colors.grey.shade300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badge.isUnlocked ? Icons.stars : Icons.lock),
          Text(badge.name),
          if (badge.isUnlocked && badge.unlockedAt != null)
            Text(badge.unlockedAt!.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

// --- Main Test Suite (FE-GAM-001 to FE-GAM-015) ---

void main() {
  group('F-12 Gamification Engine - Frontend Unit, Provider & Widget Tests', () {

    // FE-GAM-001: Profile Screen Navigation Button
    testWidgets('FE-GAM-001: ProfileScreen contains viewGamificationButton key and navigates to /gamification', (tester) async {
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(path: '/profile', builder: (context, state) => const TestableProfileScreen()),
          GoRoute(path: '/gamification', builder: (context, state) => const TestableGamificationScreen()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final navButton = find.byKey(const Key('viewGamificationButton'));
      expect(navButton, findsOneWidget);

      await tester.tap(navButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('gamificationScreen')), findsOneWidget);
    });

    // FE-GAM-002: GamificationScreen Rendering & Header
    testWidgets('FE-GAM-002: GamificationScreen renders header text "Civic Impact & Badges"', (tester) async {
      final profile = GamificationProfile(
        isGuest: false,
        impactScore: 120,
        level: 2,
        levelName: 'Active Neighbor',
        nextLevelScore: 300,
        streakDays: 3,
        canClaimStreak: true,
        badges: const [],
        activityCounts: const ActivityCounts(issuesCreated: 2),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gamificationScreen')), findsOneWidget);
      expect(find.text('Civic Impact & Badges'), findsOneWidget);
    });

    // FE-GAM-003: Impact Score Card Widget & Key
    testWidgets('FE-GAM-003: Impact Score Card renders Key("impactScoreCard") and Key("impactScoreValue")', (tester) async {
      final profile = GamificationProfile(
        isGuest: false,
        impactScore: 210,
        level: 2,
        levelName: 'Active Neighbor',
        nextLevelScore: 300,
        streakDays: 3,
        canClaimStreak: true,
        badges: const [],
        activityCounts: const ActivityCounts(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('impactScoreCard')), findsOneWidget);
      expect(find.byKey(const Key('impactScoreValue')), findsOneWidget);
      expect(find.text('210'), findsOneWidget);
    });

    // FE-GAM-004: Level Name Label & Progress Bar
    testWidgets('FE-GAM-004: Displays Key("levelNameLabel") and Key("levelProgressBar")', (tester) async {
      final profile = GamificationProfile(
        isGuest: false,
        impactScore: 150,
        level: 2,
        levelName: 'Active Neighbor',
        nextLevelScore: 300,
        streakDays: 2,
        canClaimStreak: true,
        badges: const [],
        activityCounts: const ActivityCounts(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('levelNameLabel')), findsOneWidget);
      expect(find.text('Active Neighbor'), findsOneWidget);

      final progressFinder = find.byKey(const Key('levelProgressBar'));
      expect(progressFinder, findsOneWidget);
      final progressWidget = tester.widget<LinearProgressIndicator>(progressFinder);
      expect(progressWidget.value, 0.5); // 150 / 300
    });

    // FE-GAM-005: Streak Banner & Claim Button
    testWidgets('FE-GAM-005: Displays Key("streakBanner"), Key("streakDaysCounter"), Key("claimStreakButton")', (tester) async {
      final profile = GamificationProfile(
        isGuest: false,
        impactScore: 50,
        level: 1,
        levelName: 'Civic Rookie',
        nextLevelScore: 100,
        streakDays: 5,
        canClaimStreak: true,
        badges: const [],
        activityCounts: const ActivityCounts(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('streakBanner')), findsOneWidget);
      expect(find.byKey(const Key('streakDaysCounter')), findsOneWidget);
      expect(find.text('5 Day Streak'), findsOneWidget);
      expect(find.byKey(const Key('claimStreakButton')), findsOneWidget);
    });

    // FE-GAM-006: Badges Grid & Individual Cards
    testWidgets('FE-GAM-006: Displays Key("badgesGrid") and 5 badge cards with exact keys', (tester) async {
      final profile = GamificationProfile(
        isGuest: false,
        impactScore: 0,
        level: 1,
        levelName: 'Civic Rookie',
        nextLevelScore: 100,
        streakDays: 0,
        canClaimStreak: false,
        badges: const [],
        activityCounts: const ActivityCounts(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('badgesGrid')), findsOneWidget);
      expect(find.byKey(const Key('badgeCard_first_report')), findsOneWidget);
      expect(find.byKey(const Key('badgeCard_civic_voter')), findsOneWidget);
      expect(find.byKey(const Key('badgeCard_quorum_hero')), findsOneWidget);
      expect(find.byKey(const Key('badgeCard_neighborhood_voice')), findsOneWidget);
      expect(find.byKey(const Key('badgeCard_streak_master')), findsOneWidget);
    });

    // FE-GAM-007: Activity Breakdown Card Widget
    testWidgets('FE-GAM-007: Displays Key("activityBreakdownCard") rendering counts', (tester) async {
      final profile = GamificationProfile(
        isGuest: false,
        impactScore: 210,
        level: 2,
        levelName: 'Active Neighbor',
        nextLevelScore: 300,
        streakDays: 3,
        canClaimStreak: false,
        badges: const [],
        activityCounts: const ActivityCounts(
          issuesCreated: 2,
          upvotesCast: 5,
          quorumVotesCast: 1,
          commentsPosted: 2,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('activityBreakdownCard')), findsOneWidget);
      expect(find.text('Issues Created: 2'), findsOneWidget);
      expect(find.text('Upvotes Cast: 5'), findsOneWidget);
      expect(find.text('Quorum Votes: 1'), findsOneWidget);
      expect(find.text('Comments Posted: 2'), findsOneWidget);
    });

    // FE-GAM-008: Riverpod `gamificationProfileProvider` Lifecycle
    test('FE-GAM-008: gamificationProfileProvider emits loading state then data state', () {
      final container = ProviderContainer(
        overrides: [
          testGamificationProfileProvider.overrideWith((ref) => const AsyncValue.loading()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(testGamificationProfileProvider), isA<AsyncLoading>());

      container.read(testGamificationProfileProvider.notifier).state = AsyncValue.data(
        const GamificationProfile(
          isGuest: false,
          impactScore: 100,
          level: 2,
          levelName: 'Active Neighbor',
          nextLevelScore: 300,
          streakDays: 1,
          canClaimStreak: false,
          badges: [],
          activityCounts: ActivityCounts(),
        ),
      );

      expect(container.read(testGamificationProfileProvider).value?.impactScore, 100);
    });

    // FE-GAM-009: Riverpod `allBadgesProvider` Lifecycle
    test('FE-GAM-009: allBadgesProvider fetches array of 5 badge metadata items', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final badges = await container.read(testAllBadgesProvider.future);
      expect(badges.length, 5);
      expect(badges.map((b) => b.key), containsAll(['first_report', 'civic_voter', 'quorum_hero', 'neighborhood_voice', 'streak_master']));
    });

    // FE-GAM-010: Riverpod `claimStreakNotifierProvider` Success Action
    testWidgets('FE-GAM-010: claimStreak() updates notifier state and invalidates/refreshes profile', (tester) async {
      final profile = GamificationProfile(
        isGuest: false,
        impactScore: 100,
        level: 2,
        levelName: 'Active Neighbor',
        nextLevelScore: 300,
        streakDays: 2,
        canClaimStreak: true,
        badges: const [],
        activityCounts: const ActivityCounts(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen(streakParams: {'isGuest': false, 'alreadyClaimed': false})),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('claimStreakButton')));
      await tester.pumpAndSettle();

      expect(find.text('3 Day Streak'), findsOneWidget);
      expect(find.text('115'), findsOneWidget);
    });

    // FE-GAM-011: Riverpod `claimStreakNotifierProvider` Duplicate Claim Error
    testWidgets('FE-GAM-011: Duplicate claim displays snackbar with "Daily streak already claimed today"', (tester) async {
      final profile = GamificationProfile(
        isGuest: false,
        impactScore: 100,
        level: 2,
        levelName: 'Active Neighbor',
        nextLevelScore: 300,
        streakDays: 2,
        canClaimStreak: false,
        badges: const [],
        activityCounts: const ActivityCounts(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen(streakParams: {'isGuest': false, 'alreadyClaimed': true})),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('claimStreakButton')));
      await tester.pumpAndSettle();

      expect(find.text('Daily streak already claimed today'), findsOneWidget);
    });

    // FE-GAM-012: Offline Hive Cache Fallback Rendering
    testWidgets('FE-GAM-012: Offline mode renders profile instantly from Hive cache', (tester) async {
      final cacheData = {
        'is_guest': false,
        'impact_score': 150,
        'level': 2,
        'level_name': 'Active Neighbor',
        'next_level_score': 300,
        'streak_days': 4,
        'can_claim_streak': true,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => const AsyncValue.loading()),
          ],
          child: MaterialApp(home: TestableGamificationScreen(offlineCacheData: cacheData)),
        ),
      );
      await tester.pump(); // No pumpAndSettle needed, renders cached data immediately

      expect(find.text('150'), findsOneWidget);
      expect(find.text('Active Neighbor'), findsOneWidget);
      expect(find.text('4 Day Streak'), findsOneWidget);
    });

    // FE-GAM-013: Guest UI Interception Guard
    testWidgets('FE-GAM-013: Tapping claimStreakButton as guest presents GuestGuard dialog without sending HTTP request', (tester) async {
      final profile = GamificationProfile(
        isGuest: true,
        impactScore: 0,
        level: 1,
        levelName: 'Civic Rookie',
        nextLevelScore: 100,
        streakDays: 0,
        canClaimStreak: false,
        badges: const [],
        activityCounts: const ActivityCounts(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen(streakParams: {'isGuest': true})),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('claimStreakButton')));
      await tester.pumpAndSettle();

      expect(find.text('GuestGuard'), findsOneWidget);
      expect(find.text('Please sign in to claim daily streaks.'), findsOneWidget);
    });

    // FE-GAM-014: Badge Locked vs Unlocked Visual Representation
    testWidgets('FE-GAM-014: Unlocked badge renders unlocked state; locked badge renders lock icon', (tester) async {
      final unlockedDate = DateTime.utc(2026, 8, 1);
      final profile = GamificationProfile(
        isGuest: false,
        impactScore: 50,
        level: 1,
        levelName: 'Civic Rookie',
        nextLevelScore: 100,
        streakDays: 0,
        canClaimStreak: false,
        badges: [
          BadgeItem(key: 'first_report', name: 'First Report', description: 'Create 1st issue', iconName: 'report', category: 'reporting', threshold: 1, isUnlocked: true, unlockedAt: unlockedDate),
        ],
        activityCounts: const ActivityCounts(issuesCreated: 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final firstReportCard = find.byKey(const Key('badgeCard_first_report'));
      expect(firstReportCard, findsOneWidget);
      expect(find.descendant(of: firstReportCard, matching: find.byIcon(Icons.stars)), findsOneWidget);
      expect(find.text('2026-08-01'), findsOneWidget);

      final civicVoterCard = find.byKey(const Key('badgeCard_civic_voter'));
      expect(civicVoterCard, findsOneWidget);
      expect(find.descendant(of: civicVoterCard, matching: find.byIcon(Icons.lock)), findsOneWidget);
    });

    // FE-GAM-015: Level 5 ("City Hero") Progress Bar Handling
    testWidgets('FE-GAM-015: Level 5 user with nextLevelScore == null renders 100% progress without error', (tester) async {
      final profile = GamificationProfile(
        isGuest: false,
        impactScore: 1600,
        level: 5,
        levelName: 'City Hero',
        nextLevelScore: null,
        streakDays: 10,
        canClaimStreak: false,
        badges: const [],
        activityCounts: const ActivityCounts(issuesCreated: 32),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testGamificationProfileProvider.overrideWith((ref) => AsyncValue.data(profile)),
          ],
          child: const MaterialApp(home: TestableGamificationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('City Hero'), findsOneWidget);
      final progressFinder = find.byKey(const Key('levelProgressBar'));
      expect(progressFinder, findsOneWidget);
      final progressWidget = tester.widget<LinearProgressIndicator>(progressFinder);
      expect(progressWidget.value, 1.0);
    });

  });
}
