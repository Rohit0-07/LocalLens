import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/feed/presentation/widgets/issue_card.dart';
import 'package:local_lens/features/feed/presentation/widgets/local_talk_card.dart';
import 'package:local_lens/features/issue_detail/data/issue_detail_api.dart';
import 'package:local_lens/features/issue_detail/presentation/screens/issue_detail_screen.dart';
import 'package:local_lens/features/issue_detail/presentation/widgets/comment_card.dart';
import 'package:local_lens/features/profile/presentation/profile_providers.dart';
import 'package:local_lens/features/profile/presentation/screens/profile_screen.dart';
import 'package:local_lens/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:local_lens/features/ward/domain/local_talk_post.dart';

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.session);
  final Session? session;

  @override
  Session? build() => session;
}

class FakeFeedRepositoryForProfile implements FeedRepository {
  final List<Issue> issues;
  final Map<String, dynamic> publicProfileMap;

  FakeFeedRepositoryForProfile({
    this.issues = const [],
    this.publicProfileMap = const {},
  });

  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async {
    if (status == 'resolved') {
      return issues.where((i) => i.status == 'resolved').toList();
    } else if (status == 'active') {
      return issues.where((i) => i.status != 'resolved').toList();
    }
    return issues;
  }

  @override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async {
    if (publicProfileMap.isNotEmpty) return publicProfileMap;
    return {
      'user_id': userId,
      'display_name': 'Aarav Sharma',
      'anon_id': 'anon_0042',
      'role': 'Ward Representative',
      'is_verified': true,
      'ward': 'Ward 45, Urban Central',
      'member_since': '2025-06-15T00:00:00.000',
      'impact_points': 340,
      'level_name': 'Community Sentinel',
      'issues_reported': 8,
      'verified_resolutions': 6,
      'upvotes_received': 92,
      'badges': [
        {
          'key': 'first_report',
          'name': 'First Alert',
          'description': 'Reported first civic issue',
          'icon_name': 'flag',
          'category': 'reporting',
          'threshold': 1,
          'is_unlocked': true,
        },
        {
          'key': 'sentinel',
          'name': 'Community Sentinel',
          'description': 'Earned 250+ impact points',
          'icon_name': 'shield',
          'category': 'impact',
          'threshold': 250,
          'is_unlocked': true,
        },
      ],
    };
  }

  @override
  Future<Issue> fetchIssue(int issueId) async {
    return issues.firstWhere(
      (i) => i.id == issueId,
      orElse: () => Issue(
        id: issueId,
        title: 'Sample Issue $issueId',
        description: 'Description of $issueId',
        category: 'road',
        status: 'escalating',
        latitude: 19.076,
        longitude: 72.877,
        isAnonymous: false,
        reporterLabel: 'Citizen #42',
        reporterId: 42,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('User Profile Posts & Public Profile Tests', () {
    late List<Issue> testIssues;
    late FakeFeedRepositoryForProfile fakeFeedRepo;

    setUp(() {
      testIssues = [
        Issue(
          id: 101,
          title: 'Broken water pipeline on 14th Cross',
          description: 'Water leaking heavily near primary school.',
          category: 'water',
          status: 'unacknowledged',
          latitude: 19.0760,
          longitude: 72.8777,
          ward: 'Ward 45, Urban Central',
          isAnonymous: true,
          reporterLabel: 'Anonymous Citizen',
          reporterId: 42,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          upvotesCount: 8,
        ),
        Issue(
          id: 102,
          title: 'Street lights malfunctioning on Main Boulevard',
          description: 'Entire street is completely dark.',
          category: 'lighting',
          status: 'escalating',
          latitude: 19.0762,
          longitude: 72.8780,
          ward: 'Ward 45, Urban Central',
          isAnonymous: false,
          reporterLabel: 'Aarav Sharma',
          reporterId: 42,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          upvotesCount: 24,
        ),
        Issue(
          id: 103,
          title: 'Pothole repaired near market circle',
          description: 'Road surface patched and tarred.',
          category: 'road',
          status: 'resolved',
          latitude: 19.0755,
          longitude: 72.8790,
          ward: 'Ward 45, Urban Central',
          isAnonymous: false,
          reporterLabel: 'Aarav Sharma',
          reporterId: 42,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
          upvotesCount: 56,
        ),
      ];

      fakeFeedRepo = FakeFeedRepositoryForProfile(issues: testIssues);
    });

    Widget createTestApp({
      required Widget child,
      Session? session =
          const Session(accessToken: 'token', userId: 42, isGuest: false),
      List<Override> extraOverrides = const [],
    }) {
      final profile = UserProfile(
        id: session?.userId ?? 42,
        phone: '+919876543210',
        anonymousIdentity: 'anon_0042',
        anonId: 'anon_0042',
        isGuest: session?.isGuest ?? false,
        issuesCount: 3,
        upvotesCount: 88,
        quorumVotesCount: 6,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => child),
          GoRoute(
            path: RoutePaths.issueDetail,
            builder: (ctx, state) => Scaffold(
              body: Text('IssueDetail:${state.pathParameters['id']}'),
            ),
          ),
          GoRoute(
            path: RoutePaths.publicProfile,
            builder: (ctx, state) => Scaffold(
              body: Text('PublicProfile:${state.pathParameters['id']}'),
            ),
          ),
          GoRoute(
            path: RoutePaths.settings,
            builder: (context, state) =>
                const Scaffold(body: Text('SettingsPage')),
          ),
          GoRoute(
            path: RoutePaths.compose,
            builder: (context, state) =>
                const Scaffold(body: Text('ComposeScreen')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
          sessionProvider.overrideWith(() => _FixedSessionController(session)),
          userProfileProvider.overrideWith((ref) async => profile),
          ...extraOverrides,
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('ProfileScreen displays My Reported Issues section and cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(child: const ProfileScreen()));
      await tester.pumpAndSettle();

      // Check section header
      expect(find.text('My Reported Issues & Activity'), findsOneWidget);

      // Check filter chips exist
      expect(find.byKey(const Key('myIssuesFilter_all')), findsOneWidget);
      expect(find.byKey(const Key('myIssuesFilter_active')), findsOneWidget);
      expect(find.byKey(const Key('myIssuesFilter_resolved')), findsOneWidget);

      // Check issues are displayed
      expect(find.text('Broken water pipeline on 14th Cross'), findsOneWidget);
      expect(find.text('Street lights malfunctioning on Main Boulevard'),
          findsOneWidget);
      expect(find.text('Pothole repaired near market circle'), findsOneWidget);

      // Check upvote counts and category
      expect(find.text('8 upvotes'), findsOneWidget);
      expect(find.text('24 upvotes'), findsOneWidget);
      expect(find.text('56 upvotes'), findsOneWidget);
    });

    testWidgets('Status filter toggles Active and Resolved issues in ProfileScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(child: const ProfileScreen()));
      await tester.pumpAndSettle();

      // Tap Active filter
      await tester.tap(find.byKey(const Key('myIssuesFilter_active')));
      await tester.pumpAndSettle();

      // Active issues should be visible, resolved should be filtered out
      expect(find.text('Broken water pipeline on 14th Cross'), findsOneWidget);
      expect(find.text('Street lights malfunctioning on Main Boulevard'),
          findsOneWidget);
      expect(find.text('Pothole repaired near market circle'), findsNothing);

      // Tap Resolved filter
      await tester.tap(find.byKey(const Key('myIssuesFilter_resolved')));
      await tester.pumpAndSettle();

      // Resolved issue should be visible, active issues should be filtered out
      expect(find.text('Pothole repaired near market circle'), findsOneWidget);
      expect(find.text('Broken water pipeline on 14th Cross'), findsNothing);

      // Tap All filter
      await tester.tap(find.byKey(const Key('myIssuesFilter_all')));
      await tester.pumpAndSettle();

      expect(find.text('Broken water pipeline on 14th Cross'), findsOneWidget);
      expect(find.text('Pothole repaired near market circle'), findsOneWidget);
    });

    testWidgets('Tapping user issue in ProfileScreen navigates to IssueDetailScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(child: const ProfileScreen()));
      await tester.pumpAndSettle();

      final issueCard = find.byKey(const Key('userIssueItem_101'));
      expect(issueCard, findsOneWidget);

      await tester.tap(issueCard);
      await tester.pumpAndSettle();

      expect(find.text('IssueDetail:101'), findsOneWidget);
    });

    testWidgets('Guest session in ProfileScreen shows sign-in CTA for issue history',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const guestSession = Session(
        accessToken: 'guest-token',
        userId: 'guest_99',
        isGuest: true,
      );

      await tester.pumpWidget(createTestApp(
        child: const ProfileScreen(),
        session: guestSession,
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Sign in to view and manage your reported issues history.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'PublicProfileScreen renders hero card, role badge, impact stats, badges, and public issues',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const PublicProfileScreen(userId: 42)),
      );
      await tester.pumpAndSettle();

      // Display name, verified badge & role badge
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Ward Representative'), findsOneWidget);
      expect(find.textContaining('Ward 45, Urban Central'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Member since'), findsOneWidget);

      // Impact stats card
      expect(find.byKey(const Key('publicImpactStatsCard')), findsOneWidget);
      expect(find.text('340 pts'), findsOneWidget);
      expect(find.text('Community Sentinel'), findsAtLeastNWidgets(1));
      expect(find.text('Issues Reported'), findsOneWidget);
      expect(find.text('Verified Solves'), findsOneWidget);
      expect(find.text('Upvotes Recv.'), findsOneWidget);

      // Civic badges
      expect(find.textContaining('Unlocked Civic Badges (2)'), findsOneWidget);
      expect(find.text('First Alert'), findsOneWidget);

      // Public reported issues list
      expect(find.text('Public Reported Issues'), findsOneWidget);
      expect(find.byKey(const Key('publicIssueItem_101')), findsOneWidget);
      expect(find.byKey(const Key('publicIssueItem_102')), findsOneWidget);

      // Tap issue on public profile
      await tester.tap(find.byKey(const Key('publicIssueItem_101')));
      await tester.pumpAndSettle();

      expect(find.text('IssueDetail:101'), findsOneWidget);
    });

    testWidgets('Tapping reporter in IssueCard navigates to PublicProfile',
        (WidgetTester tester) async {
      final issueWithReporter = testIssues.first;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: IssueCard(issue: issueWithReporter),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reporterTap = find.byKey(Key('issueCardReporter_${issueWithReporter.id}'));
      expect(reporterTap, findsOneWidget);

      await tester.tap(reporterTap);
      await tester.pumpAndSettle();

      expect(find.text('PublicProfile:42'), findsOneWidget);
    });

    testWidgets('Tapping reporter in IssueDetailScreen navigates to PublicProfile',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const IssueDetailScreen(issueId: 101),
        ),
      );
      await tester.pumpAndSettle();

      final reporterTap = find.byKey(const Key('issueDetailReporter_101'));
      expect(reporterTap, findsOneWidget);

      await tester.tap(reporterTap);
      await tester.pumpAndSettle();

      expect(find.text('PublicProfile:42'), findsOneWidget);
    });

    testWidgets('Tapping comment author in CommentCard navigates to PublicProfile',
        (WidgetTester tester) async {
      final comment = Comment(
        id: 501,
        issueId: 101,
        anonId: 'anon_0042',
        content: 'Repair work started this morning.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isAuthor: false,
        userId: 42,
      );

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CommentCard(
              comment: comment,
              onReply: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final authorTap = find.byKey(const Key('commentAuthor_501'));
      expect(authorTap, findsOneWidget);

      await tester.tap(authorTap);
      await tester.pumpAndSettle();

      expect(find.text('PublicProfile:42'), findsOneWidget);
    });

    testWidgets('Tapping author in LocalTalkCard navigates to PublicProfile',
        (WidgetTester tester) async {
      final post = LocalTalkPost(
        id: 701,
        wardSlug: 'ward-45',
        authorName: 'Aarav Sharma',
        title: 'Community Cleanliness Drive this Sunday',
        body: 'Join us at the central garden at 8 AM.',
        topic: 'Community',
        repliesCount: 5,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        authorId: 42,
      );

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: LocalTalkCard(post: post),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final authorTap = find.byKey(const Key('localTalkAuthor_701'));
      expect(authorTap, findsOneWidget);

      await tester.tap(authorTap);
      await tester.pumpAndSettle();

      expect(find.text('PublicProfile:42'), findsOneWidget);
    });
  });
}
