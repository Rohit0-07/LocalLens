import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feedback/app_messenger.dart';
import '../../../core/network/network_providers.dart';
import '../../geo/presentation/providers/geo_providers.dart';
import '../data/feed_api.dart';
import '../domain/feed_repository.dart';
import '../domain/issue.dart';

import '../domain/feed_item.dart';

const defaultLatitude = 19.1136;
const defaultLongitude = 72.8697;

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedApi(ref.watch(apiClientProvider)),
);

final feedFilterProvider = StateProvider<String>((ref) => 'all');

/// Resolves the coordinates to query the feed with, awaiting the device
/// location while falling back to the default reference point. Awaiting the
/// future (rather than reading the async value) guarantees a single fetch:
/// the notifier stays loading until coordinates resolve, so no
/// rebuild-and-refetch loop is triggered when the provider completes.
Future<({double lat, double lng})> _feedCoords(Ref ref) async {
  try {
    return await ref.watch(feedCoordinatesProvider.future);
  } catch (_) {
    return (lat: defaultLatitude, lng: defaultLongitude);
  }
}

/// Performs the upvote API call. The concrete repository may expose
/// `upvoteIssue`/`removeUpvote` or a single `toggleUpvote`; dispatch to
/// whichever exists. Prefer the matching call for [currentlyUpvoted] so the
/// server is told to add or remove an upvote explicitly.
Future<Issue> _performUpvote(
  FeedRepository repository,
  int issueId,
  double latitude,
  double longitude,
  bool currentlyUpvoted,
) async {
  final repoDynamic = repository as dynamic;
  if (currentlyUpvoted) {
    try {
      return await repoDynamic.removeUpvote(issueId);
    } on NoSuchMethodError catch (_) {
      return await repoDynamic.toggleUpvote(issueId);
    }
  }
  try {
    return await repoDynamic.upvoteIssue(issueId, latitude, longitude);
  } on NoSuchMethodError catch (_) {
    return await repoDynamic.toggleUpvote(issueId);
  }
}

final multiTypeFeedProvider = AsyncNotifierProvider<MultiTypeFeedController, List<FeedItem>>(
  MultiTypeFeedController.new,
);

class MultiTypeFeedController extends AsyncNotifier<List<FeedItem>> {
  @override
  Future<List<FeedItem>> build() async {
    final repository = ref.watch(feedRepositoryProvider);
    final filter = ref.watch(feedFilterProvider);
    final coords = await _feedCoords(ref);
    return repository.fetchMultiTypeFeed(
      latitude: coords.lat,
      longitude: coords.lng,
      type: filter,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> toggleUpvote(int issueId, double latitude, double longitude) async {
    final previousState = state;
    final currentItems = state.value;
    if (currentItems == null) return;

    final index = currentItems.indexWhere(
        (item) => item.itemType == FeedItemType.issue && item.issue?.id == issueId);
    if (index == -1) return;

    final targetIssue = currentItems[index].issue!;
    final currentlyUpvoted = targetIssue.hasUpvoted;
    final updatedIssue = targetIssue.copyWith(
      hasUpvoted: !currentlyUpvoted,
      upvotesCount: currentlyUpvoted
          ? (targetIssue.upvotesCount > 0 ? targetIssue.upvotesCount - 1 : 0)
          : targetIssue.upvotesCount + 1,
    );

    final updatedList = List<FeedItem>.from(currentItems);
    updatedList[index] = FeedItem(itemType: FeedItemType.issue, issue: updatedIssue);
    state = AsyncData(updatedList);

    try {
      final repository = ref.read(feedRepositoryProvider);
      final responseIssue = await _performUpvote(
        repository,
        issueId,
        latitude,
        longitude,
        currentlyUpvoted,
      );

      final latestItems = state.value;
      if (latestItems != null) {
        final latestIndex = latestItems.indexWhere(
            (i) => i.itemType == FeedItemType.issue && i.issue?.id == issueId);
        if (latestIndex != -1) {
          final refreshedList = List<FeedItem>.from(latestItems);
          refreshedList[latestIndex] =
              FeedItem(itemType: FeedItemType.issue, issue: responseIssue);
          state = AsyncData(refreshedList);
        }
      }
    } catch (err) {
      state = previousState;
      ref.read(appMessengerProvider.notifier).show('Failed to toggle upvote');
      rethrow;
    }
  }
}

final feedProvider = AsyncNotifierProvider<FeedController, List<Issue>>(
  FeedController.new,
);

class FeedController extends AsyncNotifier<List<Issue>> {
  @override
  Future<List<Issue>> build() async {
    final repository = ref.watch(feedRepositoryProvider);
    final coords = await _feedCoords(ref);
    return repository.fetchNearby(
      latitude: coords.lat,
      longitude: coords.lng,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
