import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/domain/feed_item.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/feed/presentation/widgets/issue_card.dart';
import 'package:local_lens/shared/widgets/media_preview_widget.dart';
import 'package:local_lens/shared/widgets/status_badge.dart';

class _FakeFeedRepository implements FeedRepository {
  _FakeFeedRepository({required this.issues});

  List<Issue> issues;
  bool shouldFail = false;
  int toggleCalls = 0;

  @override
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) async {
    toggleCalls++;
    if (shouldFail) throw Exception('Upvote failed');
    final index = issues.indexWhere((i) => i.id == issueId);
    final current = issues[index];
    final updated = current.copyWith(
      hasUpvoted: true,
      upvotesCount: current.upvotesCount + 1,
    );
    issues[index] = updated;
    return updated;
  }

  @override
  Future<Issue> removeUpvote(int issueId) async {
    toggleCalls++;
    if (shouldFail) throw Exception('Remove upvote failed');
    final index = issues.indexWhere((i) => i.id == issueId);
    final current = issues[index];
    final updated = current.copyWith(
      hasUpvoted: false,
      upvotesCount: current.upvotesCount > 0 ? current.upvotesCount - 1 : 0,
    );
    issues[index] = updated;
    return updated;
  }

  @override
  Future<Issue> toggleUpvote(
    int issueId, {
    required double latitude,
    required double longitude,
    required bool currentlyUpvoted,
  }) async {
    if (currentlyUpvoted) {
      return removeUpvote(issueId);
    } else {
      return upvoteIssue(issueId, latitude: latitude, longitude: longitude);
    }
  }

  @override
  Future<List<FeedItem>> fetchMultiTypeFeed({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String type = 'all',
    String? cursor,
    int limit = 20,
  }) async {
    return issues.map((i) => FeedItem(itemType: FeedItemType.issue, issue: i)).toList();
  }

  @override
  Future<List<Issue>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async =>
      issues;

  @override
  Future<Issue> fetchIssue(int issueId) async =>
      issues.firstWhere((i) => i.id == issueId);

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
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async =>
      issues;

  @override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async =>
      {'user_id': userId};
}

Issue _createIssue({
  int id = 1,
  String title = 'Dangerous Pothole on Main St',
  String description = 'A huge pothole in the middle of the street.',
  String category = 'road',
  String status = 'open',
  int upvotesCount = 10,
  bool hasUpvoted = false,
  List<String> mediaUrls = const [],
  String? videoUrl,
  String? resolutionProof,
  bool isAnonymous = false,
}) {
  return Issue.fromJson({
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'status': status,
    'latitude': 19.1136,
    'longitude': 72.8697,
    'is_anonymous': isAnonymous,
    'reporter_label': isAnonymous ? 'Anonymous Neighbor' : 'Citizen John',
    'created_at': '2026-08-16T08:00:00Z',
    'upvotes_count': upvotesCount,
    'has_upvoted': hasUpvoted,
    'media_urls': mediaUrls,
    'video_url': videoUrl,
    'resolution_proof': resolutionProof,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IssueCard Presentation & Media Display Tests', () {
    testWidgets('renders issue card with title, category badge, and status badge',
        (tester) async {
      final issue = _createIssue(id: 101, title: 'Broken Water Pipe', category: 'water');
      final repo = _FakeFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Broken Water Pipe'), findsOneWidget);
      expect(find.text('WATER'), findsOneWidget);
      expect(find.byType(StatusBadge), findsOneWidget);
      expect(find.text('Citizen John'), findsOneWidget);
    });

    testWidgets('renders MediaPreviewWidget when mediaUrls or videoUrl is present',
        (tester) async {
      final issue = _createIssue(
        id: 102,
        title: 'Street Lighting Problem',
        category: 'lighting',
        mediaUrls: ['https://example.com/lamp1.jpg', 'https://example.com/lamp2.jpg'],
        videoUrl: 'https://example.com/lamp_demo.mp4',
      );
      final repo = _FakeFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MediaPreviewWidget), findsOneWidget);
      expect(find.byKey(const Key('issueMedia_102')), findsOneWidget);
    });

    testWidgets('does not render MediaPreviewWidget when no media is present',
        (tester) async {
      final issue = _createIssue(id: 103, mediaUrls: [], videoUrl: null, resolutionProof: null);
      final repo = _FakeFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MediaPreviewWidget), findsNothing);
    });

    testWidgets('tapping image in MediaPreviewWidget opens fullscreen modal',
        (tester) async {
      final issue = _createIssue(
        id: 104,
        mediaUrls: ['https://example.com/pothole.jpg'],
      );
      final repo = _FakeFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mediaFinder = find.byKey(const Key('issueMedia_104'));
      expect(mediaFinder, findsOneWidget);

      await tester.tap(mediaFinder);
      await tester.pumpAndSettle();

      // Fullscreen viewer should be opened
      expect(find.byType(MediaFullScreenViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Close fullscreen viewer
      final closeBtn = find.byKey(const Key('closeFullScreenMedia'));
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.byType(MediaFullScreenViewer), findsNothing);
    });

    testWidgets('tapping video in MediaPreviewWidget opens video player sheet',
        (tester) async {
      final issue = _createIssue(
        id: 105,
        videoUrl: 'https://example.com/demo.mp4',
      );
      final repo = _FakeFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mediaFinder = find.byKey(const Key('issueMedia_105'));
      expect(mediaFinder, findsOneWidget);

      await tester.tap(mediaFinder);
      await tester.pumpAndSettle();

      // Video player sheet should be shown
      expect(find.byType(VideoPlayerSheet), findsOneWidget);
      expect(find.byKey(const Key('videoPlayerPlayPause')), findsOneWidget);
      expect(find.byKey(const Key('videoPlayerMuteToggle')), findsOneWidget);

      // Toggle play/pause
      await tester.tap(find.byKey(const Key('videoPlayerPlayPause')));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);

      // Toggle mute
      await tester.tap(find.byKey(const Key('videoPlayerMuteToggle')));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'tapping upvote button toggles off immediately when hasUpvoted is true',
        (tester) async {
      final issue = _createIssue(
        id: 106,
        upvotesCount: 15,
        hasUpvoted: true,
      );
      final repo = _FakeFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('15'), findsOneWidget);

      final upvoteBtn = find.byKey(const Key('upvote_button_106'));
      expect(upvoteBtn, findsOneWidget);

      await tester.tap(upvoteBtn);
      // Check optimistic update
      await tester.pump();
      expect(find.text('14'), findsOneWidget);

      // Settle network
      await tester.pumpAndSettle();
      expect(repo.toggleCalls, 1);
      expect(find.text('14'), findsOneWidget);
    });

    testWidgets(
        'tapping upvote button toggles on immediately when hasUpvoted is false',
        (tester) async {
      final issue = _createIssue(
        id: 107,
        upvotesCount: 4,
        hasUpvoted: false,
      );
      final repo = _FakeFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4'), findsOneWidget);

      final upvoteBtn = find.byKey(const Key('upvote_button_107'));
      await tester.tap(upvoteBtn);
      await tester.pump();
      expect(find.text('5'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(repo.toggleCalls, 1);
      expect(find.text('5'), findsOneWidget);
    });
  });
}
