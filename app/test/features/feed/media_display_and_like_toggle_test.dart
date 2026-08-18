import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/domain/feed_item.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/domain/win.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/feed/presentation/widgets/local_talk_card.dart';
import 'package:local_lens/features/feed/presentation/widgets/win_card.dart';
import 'package:local_lens/features/issue_detail/presentation/screens/issue_detail_screen.dart';
import 'package:local_lens/features/ward/domain/local_talk_post.dart';
import 'package:local_lens/shared/widgets/media_preview_widget.dart';

class _FakeFeedRepository implements FeedRepository {
  _FakeFeedRepository({required this.issues});

  List<Issue> issues;
  bool shouldFail = false;
  int upvoteCallCount = 0;
  int removeCallCount = 0;

  @override
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) async {
    upvoteCallCount++;
    if (shouldFail) throw Exception('Network failure');
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
    removeCallCount++;
    if (shouldFail) throw Exception('Network failure');
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
    String? category,
    double radiusKm = 0.030,
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

  @override
  Future<void> deleteIssue(int issueId) async {}
}

Issue _sampleIssue({
  int id = 50,
  int upvotes = 7,
  bool hasUpvoted = false,
  List<String> mediaUrls = const [],
  String? videoUrl,
  String? resolutionProof,
}) {
  return Issue.fromJson({
    'id': id,
    'title': 'Sewage Blockage on 3rd Cross',
    'description': 'Overflowing sewage drain near park.',
    'category': 'sewage',
    'status': 'open',
    'latitude': 19.1136,
    'longitude': 72.8697,
    'is_anonymous': false,
    'reporter_label': 'Neighbor Anita',
    'created_at': '2026-08-16T09:30:00Z',
    'upvotes_count': upvotes,
    'has_upvoted': hasUpvoted,
    'media_urls': mediaUrls,
    'video_url': videoUrl,
    'resolution_proof': resolutionProof,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaPreviewWidget Unit & Display Tests', () {
    testWidgets('renders single image thumbnail and opens fullscreen viewer on tap',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaPreviewWidget(
              mediaUrls: ['https://example.com/photo1.jpg'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MediaPreviewWidget), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      await tester.tap(find.byType(MediaPreviewWidget));
      await tester.pumpAndSettle();

      expect(find.byType(MediaFullScreenViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Close fullscreen modal
      await tester.tap(find.byKey(const Key('closeFullScreenMedia')));
      await tester.pumpAndSettle();

      expect(find.byType(MediaFullScreenViewer), findsNothing);
    });

    testWidgets('renders dual images side-by-side', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaPreviewWidget(
              mediaUrls: [
                'https://example.com/photo1.jpg',
                'https://example.com/photo2.jpg',
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('renders 3+ images with grid layout and +N counter',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaPreviewWidget(
              mediaUrls: [
                'https://example.com/1.jpg',
                'https://example.com/2.jpg',
                'https://example.com/3.jpg',
                'https://example.com/4.jpg',
                'https://example.com/5.jpg',
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show 3 images plus +2 counter overlay
      expect(find.byType(Image), findsNWidgets(3));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('detects video url and displays video badge and play button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaPreviewWidget(
              videoUrl: 'https://example.com/evidence.mp4',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VIDEO'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Tap to open video player sheet
      await tester.tap(find.byType(MediaPreviewWidget));
      await tester.pumpAndSettle();

      expect(find.byType(VideoPlayerSheet), findsOneWidget);
      expect(find.text('Video Demo'), findsOneWidget);
      expect(find.text('LocalLens HD Video Stream'), findsOneWidget);
      expect(find.byKey(const Key('videoPlayerPlayPause')), findsOneWidget);
    });

    testWidgets('MediaGalleryView renders horizontal gallery of items',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaGalleryView(
              mediaUrls: [
                'https://example.com/img1.jpg',
                'https://example.com/img2.jpg',
              ],
              videoUrl: 'https://example.com/clip.mp4',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MediaGalleryView), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(MediaPreviewWidget), findsNWidgets(3));
    });
  });

  group('WinCard & LocalTalkCard Media Integration Tests', () {
    testWidgets('WinCard before/after gallery swipes and opens fullscreen modal on tap',
        (tester) async {
      final win = WinItem(
        id: 1,
        issueId: 99,
        title: 'Community Garden Cleared & Restored',
        description: 'Overgrowth cleared and flowers planted.',
        category: 'sanitation',
        ward: 'Ward 45, Urban Central',
        latitude: 19.1136,
        longitude: 72.8697,
        beforeImageUrl: 'https://example.com/before.jpg',
        afterImageUrl: 'https://example.com/after.jpg',
        contributorCredits: ['Anita', 'Rahul'],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WinCard(win: win),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COMMUNITY WIN'), findsOneWidget);
      expect(find.text('Community Garden Cleared & Restored'), findsOneWidget);
      expect(find.text('BEFORE'), findsWidgets);

      // Swipe the gallery left to reveal the AFTER page
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('AFTER'), findsWidgets);

      // Swipe back to the BEFORE page and tap the image
      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();
      final gallery = find.byType(PageView);
      await tester.tapAt(tester.getCenter(gallery));
      await tester.pumpAndSettle();

      expect(find.byType(MediaFullScreenViewer), findsOneWidget);
      expect(find.text('Community Win: Before & After'), findsOneWidget);

      await tester.tap(find.byKey(const Key('closeFullScreenMedia')));
      await tester.pumpAndSettle();
    });

    testWidgets('LocalTalkCard displays attached media preview and video',
        (tester) async {
      final post = LocalTalkPost(
        id: 7,
        wardSlug: 'ward-45',
        authorName: 'Ramesh Patel',
        title: 'Road widening work underway on 2nd Main',
        body: 'Check the attached photo and video clip of the progress.',
        topic: 'infrastructure',
        repliesCount: 4,
        createdAt: DateTime.now(),
        mediaUrls: ['https://example.com/road_progress.jpg'],
        videoUrl: 'https://example.com/road_clip.mp4',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocalTalkCard(post: post),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Road widening work underway on 2nd Main'), findsOneWidget);
      expect(find.byType(MediaPreviewWidget), findsOneWidget);
      expect(find.byKey(const Key('localTalkMedia_7')), findsOneWidget);
    });
  });

  group('IssueDetailScreen Media Display & Upvote Toggle Interaction Tests', () {
    testWidgets('IssueDetailScreen displays attached media and video preview',
        (tester) async {
      final issue = _sampleIssue(
        id: 50,
        mediaUrls: ['https://example.com/sewage1.jpg'],
        videoUrl: 'https://example.com/sewage_video.mp4',
      );
      final repo = _FakeFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: IssueDetailScreen(issueId: 50),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sewage Blockage on 3rd Cross'), findsWidgets);
      expect(find.text('SEWAGE'), findsOneWidget);
      expect(find.byKey(const Key('issueDetailMedia_50')), findsOneWidget);
      expect(find.byType(MediaPreviewWidget), findsOneWidget);
    });

    testWidgets('IssueDetailScreen upvote button toggles off when hasUpvoted is true',
        (tester) async {
      final issue = _sampleIssue(
        id: 51,
        upvotes: 20,
        hasUpvoted: true,
      );
      final repo = _FakeFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: IssueDetailScreen(issueId: 51),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('20'), findsOneWidget);

      final upvoteBtn = find.byKey(const Key('upvote_button_51'));
      expect(upvoteBtn, findsOneWidget);

      await tester.tap(upvoteBtn);
      await tester.pumpAndSettle();

      expect(repo.removeCallCount, 1);
      expect(find.text('19'), findsOneWidget);
    });

    testWidgets('IssueDetailScreen upvote button toggles on when hasUpvoted is false',
        (tester) async {
      final issue = _sampleIssue(
        id: 52,
        upvotes: 5,
        hasUpvoted: false,
      );
      final repo = _FakeFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: IssueDetailScreen(issueId: 52),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);

      final upvoteBtn = find.byKey(const Key('upvote_button_52'));
      expect(upvoteBtn, findsOneWidget);

      await tester.tap(upvoteBtn);
      await tester.pumpAndSettle();

      expect(repo.upvoteCallCount, 1);
      expect(find.text('6'), findsOneWidget);
    });
  });
}
