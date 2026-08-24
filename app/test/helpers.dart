import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_lens/features/auth/domain/auth_repository.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/domain/feed_item.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';

List<Override> mockOverrides({
  AuthRepository? authRepository,
  FeedRepository? feedRepository,
}) {
  return [
    fakeVoterLocationOverride,
    if (authRepository != null)
      authRepositoryProvider.overrideWithValue(authRepository),
    if (feedRepository != null)
      feedRepositoryProvider.overrideWithValue(feedRepository),
  ];
}

/// Provides a deterministic device location so proximity-checked votes
/// (upvote / quorum) go through without platform location services.
final fakeVoterLocationOverride = voterLocationProvider.overrideWithValue(
  () async => (lat: defaultLatitude, lng: defaultLongitude),
);



class FakeAuthRepository implements AuthRepository {
  String? requestedPhone;
  String? requestedEmail;

  @override
  Future<void> requestOtp(String phone) async {
    requestedPhone = phone;
  }

  @override
  Future<Session> verifyOtp({
    required String phone,
    required String code,
  }) async {
    if (code != '000000') {
      throw StateError('bad code');
    }
    return Session(accessToken: 'test-token', userId: 42);
  }

  @override
  Future<void> requestEmailOtp(String email) async {
    requestedEmail = email;
  }

  @override
  Future<Session> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    if (code != '000000') {
      throw StateError('bad code');
    }
    return const Session(accessToken: 'email-token', userId: 101, isGuest: false);
  }

  @override
  Future<Session> loginAsGuest() async {
    return const Session(accessToken: 'guest-token', userId: 'guest:1234', isGuest: true);
  }
}

class FakeFeedRepository implements FeedRepository {
  FakeFeedRepository({this.error, this.issues = const []});

  Object? error;
  final List<Issue> issues;
  int fetchCount = 0;

  @override
  Future<List<Issue>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    fetchCount += 1;
    if (error != null) throw error!;
    return issues;
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
    final list = await fetchNearby(
      latitude: latitude ?? defaultLatitude,
      longitude: longitude ?? defaultLongitude,
      radiusKm: radiusKm,
    );
    return list.map((i) => FeedItem(itemType: FeedItemType.issue, issue: i)).toList();
  }

  @override
  Future<Issue> fetchIssue(int issueId) async {
    return issues.firstWhere(
      (i) => i.id == issueId,
      orElse: () => buildIssue(id: issueId),
    );
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
    return buildIssue(title: title);
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
    return buildIssue(id: issueId, status: 'pending_quorum');
  }

  @override
  Future<Issue> voteQuorum({
    required int issueId,
    required String vote,
    required double latitude,
    required double longitude,
    String? reason,
  }) async {
    return buildIssue(id: issueId, status: vote == 'confirm' ? 'resolved' : 'disputed');
  }

  @override
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) async {
    return buildIssue(id: issueId);
  }

  @override
  Future<Issue> removeUpvote(int issueId) async {
    return buildIssue(id: issueId);
  }

  @override
  Future<Issue> toggleUpvote(
    int issueId, {
    required double latitude,
    required double longitude,
    required bool currentlyUpvoted,
  }) async {
    return buildIssue(id: issueId);
  }

  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async {
    return issues;
  }

@override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async {
    return {'id': userId, 'username': 'citizen_$userId'};
  }

  @override
  Future<void> deleteIssue(int issueId) async {}
}


Issue buildIssue({
  int id = 1,
  String title = 'Deep pothole near the bus stop',
  String status = 'open',
}) {
  return Issue(
    id: id,
    title: title,
    description: 'A very deep pothole',
    category: 'road',
    status: status,
    latitude: 19.1136,
    longitude: 72.8697,
    isAnonymous: false,
    reporterLabel: 'Verified citizen',
    createdAt: DateTime.utc(2026, 8, 9, 10),
  );
}
