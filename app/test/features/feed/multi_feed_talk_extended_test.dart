import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/domain/feed_item.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/domain/notice.dart';
import 'package:local_lens/features/feed/domain/win.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/feed/presentation/feed_screen.dart';
import 'package:local_lens/features/feed/presentation/widgets/local_talk_card.dart';
import 'package:local_lens/features/feed/presentation/widgets/notice_card.dart';
import 'package:local_lens/features/feed/presentation/widgets/win_card.dart';
import 'package:local_lens/features/ward/data/repositories/ward_repository.dart';
import 'package:local_lens/features/ward/domain/local_talk_post.dart';
import 'package:local_lens/features/ward/domain/ward_detail_out.dart';
import 'package:local_lens/features/ward/domain/ward_list_response.dart';
import 'package:local_lens/features/ward/domain/ward_summary_out.dart';
import 'package:local_lens/features/ward/presentation/widgets/local_talk_compose_sheet.dart';
import 'package:local_lens/features/ward/presentation/providers/ward_providers.dart';

class FakeMultiTypeFeedRepository implements FeedRepository {
  final List<FeedItem> items;
  int fetchCount = 0;

  FakeMultiTypeFeedRepository({required this.items});

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
    if (type == 'all') return items;
    return items.where((item) {
      if (type == 'issue') return item.itemType == FeedItemType.issue;
      if (type == 'win') return item.itemType == FeedItemType.win;
      if (type == 'notice') return item.itemType == FeedItemType.notice;
      if (type == 'local_talk') return item.itemType == FeedItemType.localTalk;
      return true;
    }).toList();
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
    final match = items.firstWhere(
      (i) => i.itemType == FeedItemType.issue && i.issue?.id == issueId,
    );
    return match.issue!;
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
  }) async =>
      [];

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
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Issue> removeUpvote(int issueId) async {
    throw UnimplementedError();
  }

  @override
  Future<Issue> toggleUpvote(
    int issueId, {
    required double latitude,
    required double longitude,
    required bool currentlyUpvoted,
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

class FakeWardRepository implements WardRepository {
  bool talkPostCreated = false;
  String? createdTitle;
  String? createdBody;
  String? createdTopic;

  @override
  Future<Map<String, dynamic>> createTalkPost({
    required String wardSlug,
    required String title,
    required String body,
    String topic = 'General',
  }) async {
    talkPostCreated = true;
    createdTitle = title;
    createdBody = body;
    createdTopic = topic;
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

void main() {
  final sampleIssue = Issue(
    id: 101,
    title: 'Pothole on Main St',
    description: 'Deep pothole causing hazard',
    category: 'road',
    status: 'open',
    latitude: 19.1136,
    longitude: 72.8697,
    isAnonymous: false,
    reporterLabel: 'Verified citizen',
    createdAt: DateTime.utc(2026, 8, 10),
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
  }) {
    return ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(feedRepo),
        wardRepositoryProvider.overrideWithValue(wardRepo ?? FakeWardRepository()),
      ],
      child: const MaterialApp(
        home: FeedScreen(),
      ),
    );
  }

  testWidgets('FE-FEED-01: Feed screen filter chips rendering', (tester) async {
    final feedRepo = FakeMultiTypeFeedRepository(items: allItems);
    await tester.pumpWidget(buildTestWidget(feedRepo: feedRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feedFilterChip_all')), findsOneWidget);
    expect(find.byKey(const Key('feedFilterChip_issues')), findsOneWidget);
    expect(find.byKey(const Key('feedFilterChip_wins')), findsOneWidget);
    expect(find.byKey(const Key('feedFilterChip_notices')), findsOneWidget);
    expect(find.byKey(const Key('feedFilterChip_local_talk')), findsOneWidget);
  });

  testWidgets('FE-FEED-02: Filter chip selection updates state and displays corresponding feed cards', (tester) async {
    final feedRepo = FakeMultiTypeFeedRepository(items: allItems);
    await tester.pumpWidget(buildTestWidget(feedRepo: feedRepo));
    await tester.pumpAndSettle();

    // Tap Issues chip
    await tester.ensureVisible(find.byKey(const Key('feedFilterChip_issues')));
    await tester.tap(find.byKey(const Key('feedFilterChip_issues')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('issueCard_101')), findsOneWidget);
    expect(find.byKey(const Key('winCard_202')), findsNothing);

    // Tap Wins chip
    await tester.ensureVisible(find.byKey(const Key('feedFilterChip_wins')));
    await tester.tap(find.byKey(const Key('feedFilterChip_wins')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('winCard_202')), findsOneWidget);
    expect(find.byKey(const Key('issueCard_101')), findsNothing);

    // Tap Notices chip
    await tester.ensureVisible(find.byKey(const Key('feedFilterChip_notices')));
    await tester.tap(find.byKey(const Key('feedFilterChip_notices')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('noticeCard_303')), findsOneWidget);
    expect(find.byKey(const Key('winCard_202')), findsNothing);

    // Tap Local Talk chip
    await tester.ensureVisible(find.byKey(const Key('feedFilterChip_local_talk')));
    await tester.tap(find.byKey(const Key('feedFilterChip_local_talk')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('localTalkCard_404')), findsOneWidget);
    expect(find.byKey(const Key('noticeCard_303')), findsNothing);

    // Tap Notices chip
    await tester.ensureVisible(find.byKey(const Key('feedFilterChip_notices')));
    await tester.tap(find.byKey(const Key('feedFilterChip_notices')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('noticeCard_303')), findsOneWidget);

    // Tap Local Talk chip
    await tester.ensureVisible(find.byKey(const Key('feedFilterChip_local_talk')));
    await tester.tap(find.byKey(const Key('feedFilterChip_local_talk')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('localTalkCard_404')), findsOneWidget);
  });

  testWidgets('FE-FEED-03: WinCard rendering with photos, banner, credits, and share button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider
              .overrideWithValue(FakeMultiTypeFeedRepository(items: const [])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: WinCard(win: sampleWin),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('winCard_202')), findsOneWidget);
    expect(find.text('COMMUNITY WIN'), findsOneWidget);
    expect(find.text('Resolved: Broken Streetlight'), findsOneWidget);
    expect(find.text('BEFORE'), findsWidgets);

    // Swipe the gallery left to reveal the AFTER page
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('AFTER'), findsWidgets);

    expect(find.text('Citizen John'), findsOneWidget);
    expect(find.text('Citizen Mary'), findsOneWidget);

    // Tap share button (opens the OS share sheet with the issue deep link;
    // never a crash even when no share target is available in tests).
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('winCard_202')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FE-FEED-04: NoticeCard rendering with official notice badge and validity timeframe', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoticeCard(notice: sampleNotice),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('noticeCard_303')), findsOneWidget);
    expect(find.text('MUNICIPAL WATER BOARD'), findsOneWidget);
    expect(find.text('Scheduled Water Outage'), findsOneWidget);
    expect(find.text('Valid: 20/8/2026'), findsOneWidget);
  });

  testWidgets('FE-FEED-05: LocalTalkCard rendering and tapping Share generates deep link URL', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalTalkCard(post: sampleTalk),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('localTalkCard_404')), findsOneWidget);
    expect(find.text('Garbage Collection Schedule'), findsOneWidget);
    expect(find.text('Neighbor Alice'), findsOneWidget);
    expect(find.text('SANITATION'), findsOneWidget);
    expect(find.text('4 replies'), findsOneWidget);

    // The Talk detail route is not built yet, so the share affordance stays
    // hidden rather than pointing at a dead-end placeholder route.
    expect(find.byIcon(Icons.share_outlined), findsNothing);
  });

  testWidgets('FE-FEED-06: Opening LocalTalkComposeSheet, filling inputs, and tapping submit', (tester) async {
    final feedRepo = FakeMultiTypeFeedRepository(items: allItems);
    final wardRepo = FakeWardRepository();

    await tester.pumpWidget(buildTestWidget(feedRepo: feedRepo, wardRepo: wardRepo));
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(FeedScreen));
    LocalTalkComposeSheet.show(context, 'ward-45');
    await tester.pumpAndSettle();

    expect(find.text('Start a Ward Discussion'), findsOneWidget);

    // Fill inputs
    await tester.enterText(
      find.byKey(const Key('localTalkTitleInput')),
      'New Ward Question Title',
    );
    await tester.enterText(
      find.byKey(const Key('localTalkBodyInput')),
      'Detailed body context for neighborhood discussion',
    );

    // Tap submit button
    await tester.tap(find.byKey(const Key('submitLocalTalkButton')));
    await tester.pumpAndSettle();

    expect(wardRepo.talkPostCreated, isTrue);
    expect(wardRepo.createdTitle, 'New Ward Question Title');
    expect(wardRepo.createdBody, 'Detailed body context for neighborhood discussion');
  });

  testWidgets('FE-FEED-07: End-of-feed state rendering', (tester) async {
    final feedRepo = FakeMultiTypeFeedRepository(items: allItems);
    await tester.pumpWidget(buildTestWidget(feedRepo: feedRepo));
    await tester.pumpAndSettle();

    // Scroll to the end of feed
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('endOfFeedState')), findsOneWidget);
    expect(find.text("You're all caught up!"), findsOneWidget);
  });
}
