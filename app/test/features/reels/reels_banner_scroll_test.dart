import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/domain/feed_item.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/geo/domain/device_location_service.dart';
import 'package:local_lens/features/geo/presentation/providers/geo_providers.dart';
import 'package:local_lens/features/reels/presentation/reels_screen.dart';

Issue _issue(int id) => Issue(
      id: id,
      title: 'Reel issue $id',
      description: 'desc $id',
      category: 'road',
      status: 'open',
      latitude: 19.1136,
      longitude: 72.8697,
      isAnonymous: false,
      reporterLabel: 'tester',
      createdAt: DateTime.utc(2026, 1, 1, 12, 0, id),
      mediaUrls: ['https://example.com/img_$id.jpg'],
    );

class _FakeLocation implements DeviceLocationService {
  @override
  Future<({double lat, double lng})> getCurrentCoordinates() async => (lat: 19.1136, lng: 72.8697);
}

class _FakeFeedRepository implements FeedRepository {
  final List<FeedItem> items = [
    FeedItem(itemType: FeedItemType.issue, issue: _issue(1)),
    FeedItem(itemType: FeedItemType.issue, issue: _issue(2)),
    FeedItem(itemType: FeedItemType.issue, issue: _issue(3)),
  ];

  @override
  Future<List<FeedItem>> fetchMultiTypeFeed({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0,
    String type = 'all',
    String? cursor,
    int limit = 20,
  }) async =>
      items;

  @override
  Future<List<Issue>> fetchNearby({required double latitude, required double longitude, double radiusKm = 5.0}) async => [];
  @override
  Future<Issue> fetchIssue(int issueId) => throw UnimplementedError();
  @override
  Future<Issue> createIssue({required String title, required String description, required String category, required double latitude, required double longitude, required bool isAnonymous, bool isFuzzed = false, bool isShielded = false, List<String> mediaUrls = const []}) => throw UnimplementedError();
  @override
  Future<List<NearDuplicateCandidate>> checkNearDuplicates({required double latitude, required double longitude, String? category, double radiusKm = 0.030}) async => [];
  @override
  Future<Issue> submitResolution({required int issueId, required String proofUrl, String? notes}) => throw UnimplementedError();
  @override
  Future<Issue> voteQuorum({required int issueId, required String vote, required double latitude, required double longitude, String? reason}) => throw UnimplementedError();
  @override
  Future<Issue> upvoteIssue(int issueId, {required double latitude, required double longitude}) => throw UnimplementedError();
  @override
  Future<Issue> removeUpvote(int issueId) => throw UnimplementedError();
  @override
  Future<Issue> toggleUpvote(int issueId, {required double latitude, required double longitude, required bool currentlyUpvoted}) => throw UnimplementedError();
  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async => [];
  @override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async => {};
  @override
  Future<void> deleteIssue(int issueId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('header is visible initially', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(_FakeFeedRepository()),
          deviceLocationProvider.overrideWithValue(_FakeLocation()),
        ],
        child: const MaterialApp(home: ReelsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reelsHeader')), findsOneWidget);
    final slide = tester.widget<AnimatedSlide>(find.byKey(const Key('reelsHeader')));
    expect(slide.offset, Offset.zero);
  });

  testWidgets('header hides on scroll down and shows on scroll up', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(_FakeFeedRepository()),
          deviceLocationProvider.overrideWithValue(_FakeLocation()),
        ],
        child: const MaterialApp(home: ReelsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    AnimatedSlide slide = tester.widget<AnimatedSlide>(find.byKey(const Key('reelsHeader')));
    expect(slide.offset, Offset.zero);

    // Scroll down via drag (reverse direction) — PageView vertical swipe up
    await tester.drag(find.byType(PageView), const Offset(0, -300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();

    slide = tester.widget<AnimatedSlide>(find.byKey(const Key('reelsHeader')));
    expect(slide.offset, const Offset(0, -1.5));

    // Scroll up via drag (forward direction) — swipe down
    await tester.drag(find.byType(PageView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();

    slide = tester.widget<AnimatedSlide>(find.byKey(const Key('reelsHeader')));
    expect(slide.offset, Offset.zero);
  });
}
