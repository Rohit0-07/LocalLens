import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/domain/feed_item.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/geo/domain/device_location_service.dart';
import 'package:local_lens/features/geo/presentation/providers/geo_providers.dart';

class _RecordingFeedRepository implements FeedRepository {
  List<({double? latitude, double? longitude})> calls = [];

  @override
  Future<List<FeedItem>> fetchMultiTypeFeed({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0,
    String type = 'all',
    String? cursor,
    int limit = 20,
  }) async {
    calls.add((latitude: latitude, longitude: longitude));
    return const [];
  }

  @override
  Future<List<Issue>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async =>
      [];

  @override
  Future<Issue> fetchIssue(int issueId) => throw UnimplementedError();

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
  }) =>
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
  }) =>
      throw UnimplementedError();

  @override
  Future<Issue> voteQuorum({
    required int issueId,
    required String vote,
    required double latitude,
    required double longitude,
    String? reason,
  }) =>
      throw UnimplementedError();

  @override
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) =>
      throw UnimplementedError();

  @override
  Future<Issue> removeUpvote(int issueId) => throw UnimplementedError();

  @override
  Future<Issue> toggleUpvote(
    int issueId, {
    required double latitude,
    required double longitude,
    required bool currentlyUpvoted,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async => [];

  @override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async => {};

  @override
  Future<void> deleteIssue(int issueId) async {}
}

class _FixedDeviceLocation implements DeviceLocationService {
  const _FixedDeviceLocation();

  @override
  Future<({double lat, double lng})> getCurrentCoordinates() async {
    return (lat: 19.1136, lng: 72.8697);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingFeedRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _RecordingFeedRepository();
    container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(repository),
        deviceLocationProvider.overrideWithValue(const _FixedDeviceLocation()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('default scope is all wards: feed fetched without coordinates',
      () async {
    await container.read(multiTypeFeedProvider.future);

    expect(container.read(feedScopeProvider), FeedScope.allWards);
    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.latitude, isNull);
    expect(repository.calls.single.longitude, isNull);
  });

  test('switching to my ward refetches scoped to device coordinates', () async {
    await container.read(multiTypeFeedProvider.future);

    container.read(feedScopeProvider.notifier).state = FeedScope.myWard;
    await container.read(multiTypeFeedProvider.future);

    expect(repository.calls, hasLength(2));
    expect(repository.calls.last.latitude, 19.1136);
    expect(repository.calls.last.longitude, 72.8697);
  });

  test('switching back to all wards drops the coordinates again', () async {
    await container.read(multiTypeFeedProvider.future);
    container.read(feedScopeProvider.notifier).state = FeedScope.myWard;
    await container.read(multiTypeFeedProvider.future);
    container.read(feedScopeProvider.notifier).state = FeedScope.allWards;
    await container.read(multiTypeFeedProvider.future);

    expect(repository.calls, hasLength(3));
    expect(repository.calls.last.latitude, isNull);
    expect(repository.calls.last.longitude, isNull);
  });
}
