// F-F — Feed/Issues page UI redesign — end-to-end widget tests (test agent owned).
//
// Contract source: F-F plan §4 (T-FF-01 .. T-FF-08). All assertions are
// STRUCTURAL (keys, presence, counts) per the plan — never pixel-perfect layout.
//
// NOTE: the repo-level docs/3_test_plan.md describes a different feature (F-03);
// the F-F test contract is inlined in the phase-6 task and is authoritative here.
// docs/4_interfaces.json is not readable in this phase; keys below are taken
// from the F-F contract and from the existing feed test suite (house fakes).
//
// This file is new and test-agent owned: existing feed test files are untouched.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/auth/presentation/widgets/guest_guard.dart';
import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/domain/feed_item.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/domain/notice.dart';
import 'package:local_lens/features/feed/domain/win.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';

import '../../helpers.dart';
import 'package:local_lens/features/feed/presentation/feed_screen.dart';
import 'package:local_lens/features/ward/data/repositories/ward_repository.dart';
import 'package:local_lens/features/ward/domain/local_talk_post.dart';
import 'package:local_lens/features/ward/domain/ward_detail_out.dart';
import 'package:local_lens/features/ward/domain/ward_list_response.dart';
import 'package:local_lens/features/ward/domain/ward_summary_out.dart';
import 'package:local_lens/features/ward/presentation/providers/ward_providers.dart';
import 'package:local_lens/shared/widgets/media_preview_widget.dart';
import 'package:local_lens/shared/widgets/status_badge.dart';

// ---------------------------------------------------------------------------
// Fakes (house style: fakes live in the test file, never in lib)
// ---------------------------------------------------------------------------

/// Fixed session so guest vs signed-in flag behavior (T-FF-05) is deterministic.
class _FixedSessionController extends SessionController {
  _FixedSessionController(this.session);

  final Session? session;

  @override
  Session? build() => session;
}

/// Feed repository fake: seeds a multi-type feed, supports per-type filtering
/// (mirrors the contract of `fetchMultiTypeFeed(type: ...)`), optional error /
/// pending (skeleton) states, and records toggle calls for the optimistic
/// upvote assertions (T-FF-04).
class _FakeFeedRepository implements FeedRepository {
  _FakeFeedRepository({
    required this.items,
    this.error,
    this.pending,
  });

  final List<FeedItem> items;
  Object? error;
  Completer<List<FeedItem>>? pending;
  int fetchCount = 0;
  int toggleCalls = 0;

  List<FeedItem> _filterByType(String type) {
    switch (type) {
      case 'issue':
        return items.where((i) => i.itemType == FeedItemType.issue).toList();
      case 'win':
        return items.where((i) => i.itemType == FeedItemType.win).toList();
      case 'notice':
        return items.where((i) => i.itemType == FeedItemType.notice).toList();
      case 'local_talk':
        return items.where((i) => i.itemType == FeedItemType.localTalk).toList();
      default:
        return items;
    }
  }

  @override
  Future<List<FeedItem>> fetchMultiTypeFeed({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0,
    String type = 'all',
    String? cursor,
    int limit = 20,
  }) async {
    fetchCount++;
    if (pending != null) {
      return pending!.future;
    }
    if (error != null) {
      throw error!;
    }
    return _filterByType(type);
  }

  @override
  Future<List<Issue>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    return items
        .where((i) => i.itemType == FeedItemType.issue && i.issue != null)
        .map((i) => i.issue!)
        .toList();
  }

  @override
  Future<Issue> fetchIssue(int issueId) async {
    return items
        .firstWhere(
          (i) => i.itemType == FeedItemType.issue && i.issue?.id == issueId,
        )
        .issue!;
  }

  @override
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) async {
    return _applyToggle(issueId, upvote: true);
  }

  @override
  Future<Issue> removeUpvote(int issueId) async {
    return _applyToggle(issueId, upvote: false);
  }

  @override
  Future<Issue> toggleUpvote(
    int issueId, {
    required double latitude,
    required double longitude,
    required bool currentlyUpvoted,
  }) async {
    return _applyToggle(issueId, upvote: !currentlyUpvoted);
  }

  Future<Issue> _applyToggle(int issueId, {required bool upvote}) async {
    toggleCalls++;
    final index = items.indexWhere(
      (i) => i.itemType == FeedItemType.issue && i.issue?.id == issueId,
    );
    final current = items[index].issue!;
    final updated = current.copyWith(
      hasUpvoted: upvote,
      upvotesCount: upvote
          ? current.upvotesCount + 1
          : (current.upvotesCount > 0 ? current.upvotesCount - 1 : 0),
    );
    items[index] = FeedItem(itemType: FeedItemType.issue, issue: updated);
    return updated;
  }

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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<NearDuplicateCandidate>> checkNearDuplicates({
    required double latitude,
    required double longitude,
    String? category,
    double radiusKm = 0.030,
  }) async {
    return [];
  }

  @override
  Future<Issue> submitResolution({
    required int issueId,
    required String proofUrl,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Issue> voteQuorum({
    required int issueId,
    required String vote,
    required double latitude,
    required double longitude,
    String? reason,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async {
    return items
        .where((i) => i.itemType == FeedItemType.issue && i.issue != null)
        .map((i) => i.issue!)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async {
    return {'id': userId};
  }

  @override
  Future<void> deleteIssue(int issueId) async {}
}

/// Ward repository fake (FeedScreen depends on ward providers for the LocalTalk
/// compose surface; same shape as the existing feed suite fakes).
class _FakeWardRepository implements WardRepository {
  @override
  Future<Map<String, dynamic>> createTalkPost({
    required String wardSlug,
    required String title,
    required String body,
    String topic = 'General',
  }) async {
    return {
      'id': 999,
      'ward_slug': wardSlug,
      'author_name': 'Test User',
      'title': title,
      'body': body,
      'topic': topic,
      'replies_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getTalkPosts({
    required String wardSlug,
    int limit = 20,
    int offset = 0,
  }) async =>
      [];

  @override
  Future<WardSummaryOut> getWardByLocation(double latitude, double longitude) async {
    throw UnimplementedError();
  }

  @override
  Future<WardDetailOut> getWardDetail(String slug, {int issuesLimit = 10}) async {
    throw UnimplementedError();
  }

  @override
  Future<WardListResponse> getWards({int limit = 20, int offset = 0}) async {
    throw UnimplementedError();
  }
}

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

Issue _buildIssue({
  int id = 101,
  String title = 'Pothole on Main St',
  String description = 'Deep pothole causing hazard',
  String status = 'open',
  int upvotesCount = 0,
  bool hasUpvoted = false,
  List<String> mediaUrls = const [],
  bool isFuzzed = false,
  bool isShielded = false,
}) {
  return Issue.fromJson({
    'id': id,
    'title': title,
    'description': description,
    'category': 'road',
    'status': status,
    'latitude': 19.1136,
    'longitude': 72.8697,
    'is_anonymous': false,
    'reporter_label': 'Verified citizen',
    'created_at': '2026-08-10T08:00:00Z',
    'upvotes_count': upvotesCount,
    'has_upvoted': hasUpvoted,
    'media_urls': mediaUrls,
    'is_fuzzed': isFuzzed,
    'is_shielded': isShielded,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // One item of each type — the canonical mixed feed used across T-FF-01..08.
  final sampleIssue = _buildIssue(
    id: 101,
    title: 'Pothole on Main St',
    description: 'Deep pothole causing hazard',
    status: 'open',
    upvotesCount: 23,
  );

  final sampleWin = WinItem(
    id: 202,
    issueId: 42,
    title: 'Resolved: Broken Streetlight',
    description: 'Fixture replaced and light restored',
    category: 'lighting',
    ward: 'Ward 45, Urban Central',
    latitude: 19.1136,
    longitude: 72.8697,
    beforeImageUrl: 'http://example.com/before.jpg',
    afterImageUrl: 'http://example.com/after.jpg',
    contributorCredits: ['Citizen John', 'Citizen Mary'],
    createdAt: DateTime.utc(2026, 8, 10),
  );

  final sampleNotice = NoticeItem(
    id: 303,
    title: 'Scheduled Water Outage',
    description: 'Water pipeline maintenance on Tuesday',
    officialHeader: 'MUNICIPAL WATER BOARD',
    validUntil: DateTime.utc(2026, 8, 20),
    ward: 'Ward 45, Urban Central',
    latitude: 19.1136,
    longitude: 72.8697,
    createdAt: DateTime.utc(2026, 8, 10),
  );

  final sampleTalk = LocalTalkPost(
    id: 404,
    wardSlug: 'ward-45-urban-central',
    authorName: 'Neighbor Alice',
    title: 'Garbage Collection Schedule',
    body: 'When does the recycling truck visit our lane?',
    topic: 'Sanitation',
    repliesCount: 4,
    latitude: 19.1136,
    longitude: 72.8697,
    createdAt: DateTime.utc(2026, 8, 10),
  );

  final allItems = [
    FeedItem(itemType: FeedItemType.issue, issue: sampleIssue),
    FeedItem(itemType: FeedItemType.win, win: sampleWin),
    FeedItem(itemType: FeedItemType.notice, notice: sampleNotice),
    FeedItem(itemType: FeedItemType.localTalk, localTalk: sampleTalk),
  ];

  Widget buildTestWidget({
    required FeedRepository feedRepo,
    WardRepository? wardRepo,
    Session? session,
    GoRouter? router,
  }) {
    return ProviderScope(
      overrides: [
        fakeVoterLocationOverride,
        feedRepositoryProvider.overrideWithValue(feedRepo),
        wardRepositoryProvider.overrideWithValue(wardRepo ?? _FakeWardRepository()),
        if (session != null)
          sessionProvider.overrideWith(() => _FixedSessionController(session)),
      ],
      child: router != null
          ? MaterialApp.router(routerConfig: router)
          : const MaterialApp(home: FeedScreen()),
    );
  }

  /// Tall viewport so all four mixed-feed cards are laid out and built by the
  /// lazy ListView (used where "all card types present" is asserted).
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('F-F Feed/Issues UI redesign', () {
    testWidgets('T-FF-01: Home shows a clean mixed feed with one footer actions row per issue card',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeFeedRepository(items: allItems);

      await tester.pumpWidget(buildTestWidget(feedRepo: repo));
      await tester.pumpAndSettle();

      // One card of every type is present.
      expect(find.byKey(const Key('issueCard_101')), findsOneWidget);
      expect(find.byKey(const Key('winCard_202')), findsOneWidget);
      expect(find.byKey(const Key('noticeCard_303')), findsOneWidget);
      expect(find.byKey(const Key('localTalkCard_404')), findsOneWidget);

      // Every issue card exposes exactly ONE footer actions row, plus the
      // status row and header meta, all inside that card.
      final issueCard = find.byKey(const Key('issueCard_101'));
      expect(find.byKey(const Key('issueActions_101')), findsOneWidget);
      expect(
        find.descendant(
          of: issueCard,
          matching: find.byKey(const Key('issueStatusRow_101')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: issueCard,
          matching: find.byKey(const Key('issueHeaderMeta_101')),
        ),
        findsOneWidget,
      );

      // Declutter structure check: no Divider anywhere inside the issue card.
      expect(
        find.descendant(of: issueCard, matching: find.byType(Divider)),
        findsNothing,
      );
    });

    testWidgets('T-FF-02: Filter chips switch card types', (tester) async {
      useTallViewport(tester);
      final repo = _FakeFeedRepository(items: allItems);

      await tester.pumpWidget(buildTestWidget(feedRepo: repo));
      await tester.pumpAndSettle();

      // Issues only.
      await tester.ensureVisible(find.byKey(const Key('feedFilterChip_issues')));
      await tester.tap(find.byKey(const Key('feedFilterChip_issues')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('issueCard_101')), findsOneWidget);
      expect(find.byKey(const Key('winCard_202')), findsNothing);
      expect(find.byKey(const Key('noticeCard_303')), findsNothing);
      expect(find.byKey(const Key('localTalkCard_404')), findsNothing);

      // Wins only.
      await tester.ensureVisible(find.byKey(const Key('feedFilterChip_wins')));
      await tester.tap(find.byKey(const Key('feedFilterChip_wins')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('winCard_202')), findsOneWidget);
      expect(find.byKey(const Key('issueCard_101')), findsNothing);
      expect(find.byKey(const Key('noticeCard_303')), findsNothing);
      expect(find.byKey(const Key('localTalkCard_404')), findsNothing);

      // Notices only.
      await tester.ensureVisible(find.byKey(const Key('feedFilterChip_notices')));
      await tester.tap(find.byKey(const Key('feedFilterChip_notices')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noticeCard_303')), findsOneWidget);
      expect(find.byKey(const Key('issueCard_101')), findsNothing);
      expect(find.byKey(const Key('winCard_202')), findsNothing);
      expect(find.byKey(const Key('localTalkCard_404')), findsNothing);

      // Local talk only.
      await tester.ensureVisible(find.byKey(const Key('feedFilterChip_local_talk')));
      await tester.tap(find.byKey(const Key('feedFilterChip_local_talk')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('localTalkCard_404')), findsOneWidget);
      expect(find.byKey(const Key('issueCard_101')), findsNothing);
      expect(find.byKey(const Key('winCard_202')), findsNothing);
      expect(find.byKey(const Key('noticeCard_303')), findsNothing);

      // Back to the full mixed feed.
      await tester.ensureVisible(find.byKey(const Key('feedFilterChip_all')));
      await tester.tap(find.byKey(const Key('feedFilterChip_all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('issueCard_101')), findsOneWidget);
      expect(find.byKey(const Key('winCard_202')), findsOneWidget);
      expect(find.byKey(const Key('noticeCard_303')), findsOneWidget);
      expect(find.byKey(const Key('localTalkCard_404')), findsOneWidget);
    });

    testWidgets('T-FF-03: Tapping an issue card navigates to the issue detail route',
        (tester) async {
      final repo = _FakeFeedRepository(items: allItems);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: FeedScreen()),
          ),
          // Minimal stub for the issue detail route: renders the tapped id.
          GoRoute(
            path: '/issue/:id',
            builder: (context, state) => Scaffold(
              body: Text('ISSUE_DETAIL_${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestWidget(
          feedRepo: repo,
          router: router,
          session: const Session(accessToken: 't', userId: 42, isGuest: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('issueCard_101')), findsOneWidget);
      await tester.tap(find.byKey(const Key('issueCard_101')));
      await tester.pumpAndSettle();

      expect(find.text('ISSUE_DETAIL_101'), findsOneWidget);
    });

    testWidgets('T-FF-04: Upvote is optimistic and toggles back on second tap',
        (tester) async {
      final repo = _FakeFeedRepository(items: allItems);

      await tester.pumpWidget(buildTestWidget(feedRepo: repo));
      await tester.pumpAndSettle();

      // Seed count is 23 (distinctive to avoid collisions with other numbers).
      expect(find.text('23'), findsOneWidget);

      // First tap: increments immediately (optimistic) and calls the repo once.
      await tester.tap(find.byKey(const Key('upvote_button_101')));
      await tester.pump();
      expect(find.text('24'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(repo.toggleCalls, 1);
      expect(find.text('24'), findsOneWidget);

      // Second tap: decrements immediately and calls the repo once more.
      await tester.tap(find.byKey(const Key('upvote_button_101')));
      await tester.pump();
      expect(find.text('23'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(repo.toggleCalls, 2);
      expect(find.text('23'), findsOneWidget);
    });

    testWidgets('T-FF-05a: Overflow menu reveals flag option and opens FlagIssueDialog for a signed-in user',
        (tester) async {
      final repo = _FakeFeedRepository(items: allItems);

      await tester.pumpWidget(
        buildTestWidget(
          feedRepo: repo,
          session: const Session(accessToken: 't', userId: 42, isGuest: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('issueCardOverflow_101')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('flagIssueOption_101')), findsOneWidget);

      await tester.tap(find.byKey(const Key('flagIssueOption_101')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('flagIssueDialog')), findsOneWidget);
      expect(find.byType(GuestGuard), findsNothing);
    });

    testWidgets('T-FF-05b: Overflow menu flag option opens GuestGuard for a guest session',
        (tester) async {
      final repo = _FakeFeedRepository(items: allItems);

      await tester.pumpWidget(
        buildTestWidget(
          feedRepo: repo,
          session: const Session(
            accessToken: 'g',
            userId: 'guest:1',
            anonId: 'anon:1',
            isGuest: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('issueCardOverflow_101')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('flagIssueOption_101')), findsOneWidget);

      await tester.tap(find.byKey(const Key('flagIssueOption_101')));
      await tester.pumpAndSettle();

      // Real surface: the flag path for guests shows the sign-in guard dialog.
      expect(find.byType(GuestGuard), findsOneWidget);
      expect(find.byKey(const Key('flagIssueDialog')), findsNothing);
    });

    testWidgets('T-FF-06: Issue card content hierarchy (media, fuzz/shield, status hint, action row)',
        (tester) async {
      final richIssue = _buildIssue(
        id: 501,
        title: 'Dangerous open manhole',
        description: 'Missing cover after the storm, a serious hazard for pedestrians.',
        status: 'escalating',
        upvotesCount: 5,
        mediaUrls: ['https://example.com/manhole.jpg'],
        isFuzzed: true,
        isShielded: true,
      );
      final repo = _FakeFeedRepository(
        items: [FeedItem(itemType: FeedItemType.issue, issue: richIssue)],
      );

      await tester.pumpWidget(buildTestWidget(feedRepo: repo));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('issueCard_501'));

      // Title and description preview (presence only).
      expect(find.text('Dangerous open manhole'), findsOneWidget);
      expect(
        find.text('Missing cover after the storm, a serious hazard for pedestrians.'),
        findsOneWidget,
      );

      // Media present for the media-bearing issue.
      expect(
        find.descendant(of: card, matching: find.byType(MediaPreviewWidget)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('issueMedia_501')), findsOneWidget);

      // Fuzz / shield affordance labels.
      expect(find.text('Fuzzed'), findsOneWidget);
      expect(find.text('Shielded'), findsOneWidget);

      // Status badge and the inline ESCALATING hint inside the status row.
      // The badge translates `status_escalating` and uppercases it, so it also
      // renders 'ESCALATING' — both the badge and the inline hint are present.
      expect(
        find.descendant(of: card, matching: find.byType(StatusBadge)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('issueStatusRow_501')),
          matching: find.text('ESCALATING'),
        ),
        findsNWidgets(2),
      );

      // The single footer actions row contains upvote / comment / share.
      final actionsRow = find.byKey(const Key('issueActions_501'));
      expect(actionsRow, findsOneWidget);
      expect(
        find.descendant(
          of: actionsRow,
          matching: find.byKey(const Key('upvote_button_501')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: actionsRow,
          matching: find.byKey(const Key('comment_button_501')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: actionsRow,
          matching: find.byKey(const Key('share_button_501')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('T-FF-07a: Loading state renders the feed skeleton', (tester) async {
      final repo = _FakeFeedRepository(
        items: allItems,
        pending: Completer<List<FeedItem>>(),
      );

      await tester.pumpWidget(buildTestWidget(feedRepo: repo));
      // Do NOT pumpAndSettle before completing: the shimmer stays on screen.
      await tester.pump();

      expect(find.byKey(const Key('feedSkeleton')), findsOneWidget);

      // Complete the fetch: skeleton is replaced by real cards. pumpAndSettle
      // then flushes image-load timers so no timer is left pending at teardown.
      repo.pending!.complete(allItems);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feedSkeleton')), findsNothing);
      expect(find.byKey(const Key('issueCard_101')), findsOneWidget);
    });

    testWidgets('T-FF-07b: Empty state shows the all-clear message', (tester) async {
      final repo = _FakeFeedRepository(items: const []);

      await tester.pumpWidget(buildTestWidget(feedRepo: repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feedEmptyState')), findsOneWidget);
      expect(find.text('All clear around here'), findsOneWidget);
    });

    testWidgets('T-FF-07c: Error state shows Feed unavailable and Retry refetches',
        (tester) async {
      final repo = _FakeFeedRepository(items: allItems, error: StateError('offline'));

      await tester.pumpWidget(buildTestWidget(feedRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Feed unavailable'), findsOneWidget);
      expect(repo.fetchCount, 1);

      repo.error = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchCount, 2);
      expect(find.text('Feed unavailable'), findsNothing);
      expect(find.byKey(const Key('issueCard_101')), findsOneWidget);
    });

    testWidgets('T-FF-07d: End-of-feed state after scrolling', (tester) async {
      final repo = _FakeFeedRepository(items: allItems);

      await tester.pumpWidget(buildTestWidget(feedRepo: repo));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('endOfFeedState')), findsOneWidget);
      expect(find.text("You're all caught up!"), findsOneWidget);
    });

    testWidgets('T-FF-08: No share affordance on a LocalTalk-only feed', (tester) async {
      final repo = _FakeFeedRepository(items: allItems);

      await tester.pumpWidget(buildTestWidget(feedRepo: repo));
      await tester.pumpAndSettle();

      // Mixed feed does carry share affordances (issue/win cards), so the
      // declutter regression guard only applies once only LocalTalk remains.
      await tester.ensureVisible(find.byKey(const Key('feedFilterChip_local_talk')));
      await tester.tap(find.byKey(const Key('feedFilterChip_local_talk')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('localTalkCard_404')), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsNothing);
    });
  });
}
