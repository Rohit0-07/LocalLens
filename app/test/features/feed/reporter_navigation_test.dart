import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/domain/feed_item.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/feed/presentation/widgets/issue_card.dart';

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.session);
  final Session? session;

  @override
  Session? build() => session;
}

class _StubFeedRepository implements FeedRepository {
  @override
  Future<List<Issue>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async =>
      [];

  @override
  Future<List<FeedItem>> fetchMultiTypeFeed({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String type = 'all',
    String? cursor,
    int limit = 20,
  }) async =>
      [];

  @override
  Future<Issue> fetchIssue(int issueId) async =>
      throw UnimplementedError();

  @override
  Future<Issue> createIssue({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required bool isAnonymous,
    bool isFuzzed = false,
    bool isShielded = false,
    List<String> mediaUrls = const [],
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<NearDuplicateCandidate>> checkNearDuplicates({
    required double latitude,
    required double longitude,
    double radiusKm = 0.5,
  }) async =>
      [];

  @override
  Future<Issue> submitResolution({
    required int issueId,
    required String proofUrl,
    String? notes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Issue> voteQuorum({
    required int issueId,
    required String vote,
    required double latitude,
    required double longitude,
    String? reason,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Issue> removeUpvote(int issueId) async =>
      throw UnimplementedError();

  @override
  Future<Issue> toggleUpvote(
    int issueId, {
    required double latitude,
    required double longitude,
    required bool currentlyUpvoted,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async =>
      [];

  @override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async =>
      {'user_id': userId};
}

Issue _createIssue({int id = 1, int? reporterId, int upvotesCount = 0}) {
  return Issue.fromJson({
    'id': id,
    'title': 'Reporter Navigation Issue',
    'description': 'Test description',
    'category': 'road',
    'status': 'open',
    'latitude': 19.1136,
    'longitude': 72.8697,
    'is_anonymous': false,
    'reporter_label': 'Citizen',
    'reporter_id': reporterId,
    'reporter_name': 'Citizen',
    'created_at': '2026-08-16T08:00:00Z',
    'upvotes_count': upvotesCount,
    'has_upvoted': false,
    'media_urls': <String>[],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repo = _StubFeedRepository();

  Widget createTestApp({required Session? session, required Issue issue}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              Scaffold(body: SingleChildScrollView(child: IssueCard(issue: issue))),
        ),
        GoRoute(
          path: RoutePaths.profile,
          builder: (context, state) =>
              const Scaffold(body: Text('OWN_PROFILE_ROUTE')),
        ),
        GoRoute(
          path: RoutePaths.publicProfile,
          builder: (context, state) =>
              Scaffold(body: Text('PUBLIC_PROFILE_${state.pathParameters['id']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(repo),
        sessionProvider.overrideWith(() => _FixedSessionController(session)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('tapping own reporter opens own profile route, not public profile',
      (tester) async {
    final session = const Session(accessToken: 'token', userId: 42, isGuest: false);
    final issue = _createIssue(id: 5, reporterId: 42);

    await tester.pumpWidget(createTestApp(session: session, issue: issue));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('issueCardReporter_5')));
    await tester.pumpAndSettle();

    expect(find.text('PUBLIC_PROFILE_42'), findsNothing);
    expect(find.text('OWN_PROFILE_ROUTE'), findsOneWidget);
  });

  testWidgets('tapping another user reporter opens the public profile route',
      (tester) async {
    final session = const Session(accessToken: 'token', userId: 7, isGuest: false);
    final issue = _createIssue(id: 6, reporterId: 42);

    await tester.pumpWidget(createTestApp(session: session, issue: issue));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('issueCardReporter_6')));
    await tester.pumpAndSettle();

    expect(find.text('PUBLIC_PROFILE_42'), findsOneWidget);
    expect(find.text('OWN_PROFILE_ROUTE'), findsNothing);
  });

  testWidgets('guest tapping a reporter opens the public profile route',
      (tester) async {
    final session = const Session(
      accessToken: 'token',
      userId: 'guest_1',
      anonId: 'anon_1',
      isGuest: true,
    );
    final issue = _createIssue(id: 7, reporterId: 42);

    await tester.pumpWidget(createTestApp(session: session, issue: issue));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('issueCardReporter_7')));
    await tester.pumpAndSettle();

    expect(find.text('PUBLIC_PROFILE_42'), findsOneWidget);
    expect(find.text('OWN_PROFILE_ROUTE'), findsNothing);
  });
}