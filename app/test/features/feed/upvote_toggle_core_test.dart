import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/network/api_client.dart';
import 'package:local_lens/core/network/api_exceptions.dart';
import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/data/feed_api.dart';
import 'package:local_lens/features/feed/domain/feed_item.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient()
      : super(baseUrl: 'http://test', accessTokenProvider: () => null);

  String? lastMethod;
  String? lastPath;
  Object? lastBody;
  Map<String, dynamic>? lastQuery;
  dynamic cannedResponse;

  @override
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    lastMethod = 'GET';
    lastPath = path;
    lastQuery = query;
    return cannedResponse;
  }

  @override
  Future<dynamic> postJson(
    String path, {
    Object? body,
    bool expectNoContent = false,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    return cannedResponse;
  }

  @override
  Future<dynamic> deleteJson(
    String path, {
    Object? body,
  }) async {
    lastMethod = 'DELETE';
    lastPath = path;
    lastBody = body;
    return cannedResponse;
  }
}

Map<String, Object?> _sampleIssueJson({
  int id = 10,
  int upvotesCount = 1,
  bool hasUpvoted = false,
  List<String> mediaUrls = const ['https://example.com/img1.jpg'],
  String? videoUrl = 'https://example.com/video.mp4',
  int? reporterId = 77,
}) =>
    {
      'id': id,
      'title': 'Broken footpath on 5th Ave',
      'description': 'Needs repair urgently',
      'category': 'pothole',
      'status': 'open',
      'latitude': 19.1136,
      'longitude': 72.8697,
      'is_anonymous': false,
      'reporter_label': 'Citizen',
      'created_at': '2026-08-16T10:00:00Z',
      'upvotes_count': upvotesCount,
      'has_upvoted': hasUpvoted,
      'media_urls': mediaUrls,
      'video_url': videoUrl,
      'reporter_id': reporterId,
    };

class _MockFeedRepository implements FeedRepository {
  _MockFeedRepository({
    this.issues = const [],
    this.failUpvote = false,
  });

  List<Issue> issues;
  bool failUpvote;
  int upvoteCalls = 0;
  int removeCalls = 0;

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
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) async {
    upvoteCalls++;
    if (failUpvote) {
      throw ApiServerException(
        statusCode: 400,
        code: 'too_far_proximity',
        message: 'Too far away to upvote',
      );
    }
    final current = issues.firstWhere((i) => i.id == issueId);
    return current.copyWith(
      hasUpvoted: true,
      upvotesCount: current.upvotesCount + 1,
    );
  }

  @override
  Future<Issue> removeUpvote(int issueId) async {
    removeCalls++;
    if (failUpvote) {
      throw ApiServerException(
        statusCode: 400,
        code: 'bad_request',
        message: 'Could not remove upvote',
      );
    }
    final current = issues.firstWhere((i) => i.id == issueId);
    return current.copyWith(
      hasUpvoted: false,
      upvotesCount: current.upvotesCount > 0 ? current.upvotesCount - 1 : 0,
    );
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
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async =>
      issues;

  @override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async =>
      {'user_id': userId, 'username': 'citizen_$userId'};

  @override
  Future<void> deleteIssue(int issueId) async {}
}

void main() {
  group('FeedApi Core & Upvote Tests', () {
    late _RecordingApiClient client;
    late FeedApi api;

    setUp(() {
      client = _RecordingApiClient();
      api = FeedApi(client);
    });

    test('upvoteIssue sends POST to /issues/:id/upvote with coordinates', () async {
      client.cannedResponse = _sampleIssueJson(id: 42, upvotesCount: 6, hasUpvoted: true);

      final issue = await api.upvoteIssue(
        42,
        latitude: 19.1136,
        longitude: 72.8697,
      );

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/issues/42/upvote');
      expect(client.lastBody, {
        'latitude': 19.1136,
        'longitude': 72.8697,
      });
      expect(issue.id, 42);
      expect(issue.upvotesCount, 6);
      expect(issue.hasUpvoted, true);
      expect(issue.mediaUrls, ['https://example.com/img1.jpg']);
      expect(issue.videoUrl, 'https://example.com/video.mp4');
      expect(issue.reporterId, 77);
    });

    test('removeUpvote sends DELETE to /issues/:id/upvote via deleteJson', () async {
      client.cannedResponse = _sampleIssueJson(id: 42, upvotesCount: 5, hasUpvoted: false);

      final issue = await api.removeUpvote(42);

      expect(client.lastMethod, 'DELETE');
      expect(client.lastPath, '/issues/42/upvote');
      expect(issue.id, 42);
      expect(issue.upvotesCount, 5);
      expect(issue.hasUpvoted, false);
    });

    test('toggleUpvote delegates to removeUpvote when currentlyUpvoted is true', () async {
      client.cannedResponse = _sampleIssueJson(id: 15, upvotesCount: 2, hasUpvoted: false);

      final issue = await api.toggleUpvote(
        15,
        latitude: 19.0,
        longitude: 72.0,
        currentlyUpvoted: true,
      );

      expect(client.lastMethod, 'DELETE');
      expect(client.lastPath, '/issues/15/upvote');
      expect(issue.hasUpvoted, false);
    });

    test('toggleUpvote delegates to upvoteIssue when currentlyUpvoted is false', () async {
      client.cannedResponse = _sampleIssueJson(id: 15, upvotesCount: 3, hasUpvoted: true);

      final issue = await api.toggleUpvote(
        15,
        latitude: 19.12,
        longitude: 72.88,
        currentlyUpvoted: false,
      );

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/issues/15/upvote');
      expect(client.lastBody, {
        'latitude': 19.12,
        'longitude': 72.88,
      });
      expect(issue.hasUpvoted, true);
    });

    test('fetchUserIssues reads public_issues from /users/:id when userId is provided', () async {
      client.cannedResponse = {
        'id': 42,
        'public_issues': [
          _sampleIssueJson(id: 101),
          _sampleIssueJson(id: 102),
        ],
      };

      final issues = await api.fetchUserIssues(userId: 42, status: 'open');

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, '/users/42');
      expect(issues.length, 2);
      expect(issues.first.id, 101);
    });

    test('fetchUserIssues queries /auth/me/issues when userId is null', () async {
      client.cannedResponse = [
        _sampleIssueJson(id: 201),
      ];

      final issues = await api.fetchUserIssues(status: 'resolved');

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, '/auth/me/issues');
      expect(client.lastQuery, {'status': 'resolved'});
      expect(issues.length, 1);
    });

    test('fetchPublicUserProfile queries /users/:id', () async {
      client.cannedResponse = {
        'id': 88,
        'username': 'civic_hero',
        'points': 250,
      };

      final profile = await api.fetchPublicUserProfile(88);

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, '/users/88');
      expect(profile['username'], 'civic_hero');
      expect(profile['points'], 250);
    });
  });

  group('MultiTypeFeedController toggleUpvote Provider Integration', () {
    test('optimistically upvotes and syncs with repository upvoteIssue call', () async {
      final initialIssue = Issue.fromJson(_sampleIssueJson(
        id: 7,
        upvotesCount: 3,
        hasUpvoted: false,
      ));
      final repo = _MockFeedRepository(issues: [initialIssue]);

      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(multiTypeFeedProvider.future);
      final initialFeed = container.read(multiTypeFeedProvider).value!;
      expect(initialFeed.first.issue!.upvotesCount, 3);
      expect(initialFeed.first.issue!.hasUpvoted, false);

      // Trigger upvote
      await container
          .read(multiTypeFeedProvider.notifier)
          .toggleUpvote(7, 19.1136, 72.8697);

      expect(repo.upvoteCalls, 1);
      expect(repo.removeCalls, 0);

      final state = container.read(multiTypeFeedProvider).value!;
      expect(state.first.issue!.upvotesCount, 4);
      expect(state.first.issue!.hasUpvoted, true);
    });

    test('optimistically removes upvote and syncs with repository removeUpvote call', () async {
      final initialIssue = Issue.fromJson(_sampleIssueJson(
        id: 8,
        upvotesCount: 10,
        hasUpvoted: true,
      ));
      final repo = _MockFeedRepository(issues: [initialIssue]);

      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(multiTypeFeedProvider.future);
      final initialFeed = container.read(multiTypeFeedProvider).value!;
      expect(initialFeed.first.issue!.upvotesCount, 10);
      expect(initialFeed.first.issue!.hasUpvoted, true);

      // Trigger un-upvote
      await container
          .read(multiTypeFeedProvider.notifier)
          .toggleUpvote(8, 19.1136, 72.8697);

      expect(repo.upvoteCalls, 0);
      expect(repo.removeCalls, 1);

      final state = container.read(multiTypeFeedProvider).value!;
      expect(state.first.issue!.upvotesCount, 9);
      expect(state.first.issue!.hasUpvoted, false);
    });

    test('reverts optimistic update on network failure', () async {
      final initialIssue = Issue.fromJson(_sampleIssueJson(
        id: 9,
        upvotesCount: 5,
        hasUpvoted: false,
      ));
      final repo = _MockFeedRepository(
        issues: [initialIssue],
        failUpvote: true,
      );

      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(multiTypeFeedProvider.future);

      await expectLater(
        container
            .read(multiTypeFeedProvider.notifier)
            .toggleUpvote(9, 19.1136, 72.8697),
        throwsA(isA<ApiServerException>()),
      );

      // Reverted state
      final state = container.read(multiTypeFeedProvider).value!;
      expect(state.first.issue!.upvotesCount, 5);
      expect(state.first.issue!.hasUpvoted, false);
    });
  });
}
