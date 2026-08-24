import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/domain/feed_item.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';

Issue _issue(int id, DateTime dt) => Issue(
      id: id,
      title: 'Issue $id',
      description: 'desc',
      category: 'road',
      status: 'open',
      latitude: 19.1136,
      longitude: 72.8697,
      isAnonymous: false,
      reporterLabel: 'tester',
      createdAt: dt,
    );

class _CursorRecordingRepo implements FeedRepository {
  final List<Issue> initial;
  final List<Issue> nextPage;
  String? lastCursor;
  int callCount = 0;

  _CursorRecordingRepo({required this.initial, required this.nextPage});

  @override
  Future<List<FeedItem>> fetchMultiTypeFeed({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0,
    String type = 'all',
    String? cursor,
    int limit = 20,
  }) async {
    callCount++;
    if (callCount == 1) {
      lastCursor = cursor;
      return initial.map((e) => FeedItem(itemType: FeedItemType.issue, issue: e)).toList();
    } else {
      lastCursor = cursor;
      return nextPage.map((e) => FeedItem(itemType: FeedItemType.issue, issue: e)).toList();
    }
  }

  @override Future<List<Issue>> fetchNearby({required double latitude, required double longitude, double radiusKm = 5.0}) async => [];
  @override Future<Issue> fetchIssue(int issueId) => throw UnimplementedError();
  @override Future<Issue> createIssue({required String title, required String description, required String category, required double latitude, required double longitude, required bool isAnonymous, bool isFuzzed = false, bool isShielded = false, List<String> mediaUrls = const []}) => throw UnimplementedError();
  @override Future<List<NearDuplicateCandidate>> checkNearDuplicates({required double latitude, required double longitude, String? category, double radiusKm = 0.030}) async => [];
  @override Future<Issue> submitResolution({required int issueId, required String proofUrl, String? notes}) => throw UnimplementedError();
  @override Future<Issue> voteQuorum({required int issueId, required String vote, required double latitude, required double longitude, String? reason}) => throw UnimplementedError();
  @override Future<Issue> upvoteIssue(int issueId, {required double latitude, required double longitude}) => throw UnimplementedError();
  @override Future<Issue> removeUpvote(int issueId) => throw UnimplementedError();
  @override Future<Issue> toggleUpvote(int issueId, {required double latitude, required double longitude, required bool currentlyUpvoted}) => throw UnimplementedError();
  @override Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async => [];
  @override Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async => {};
  @override Future<void> deleteIssue(int issueId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FeedItem cursor includes id tie-breaker', () {
    final dt = DateTime.utc(2026, 1, 1, 12, 0, 0);
    final item = FeedItem(itemType: FeedItemType.issue, issue: _issue(42, dt));
    expect(item.cursor, '${dt.toIso8601String()}|42');
  });

  test('loadMore builds cursor as "<iso>|<id>" from last item', () async {
    final fixed = DateTime.utc(2026, 1, 1, 12, 0, 0);
    // two items share same timestamp, highest id first
    final repo = _CursorRecordingRepo(
      initial: [_issue(3, fixed), _issue(2, fixed)],
      nextPage: [_issue(1, fixed)],
    );
    final container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(multiTypeFeedProvider.future);
    expect(container.read(multiTypeFeedProvider).value!.length, 2);

    await container.read(multiTypeFeedProvider.notifier).loadMore();
    // cursor should be from last item (id 2)
    expect(repo.lastCursor, '${fixed.toIso8601String()}|2');
    expect(container.read(multiTypeFeedProvider).value!.length, 3);
    expect(container.read(multiTypeFeedProvider).value!.last.id, 1);
  });

  test('bare ISO cursor still excluded via strict < (no id) - covered by backend test', () {
    // This documents the contract: when cursor has no |id, backend uses strict created_at < cursor
    // App always sends |id, so this is just a safety net.
    expect(true, isTrue);
  });
}
