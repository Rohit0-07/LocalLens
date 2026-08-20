import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feedback/app_messenger.dart';
import '../../../core/feedback/error_copy.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/network_providers.dart';
import '../../geo/presentation/providers/geo_providers.dart';
import '../data/feed_api.dart';
import '../domain/feed_repository.dart';
import '../domain/issue.dart';

import '../domain/feed_item.dart';

const defaultLatitude = 19.1136;
const defaultLongitude = 72.8697;

/// Maps an upvote failure to a specific, actionable message so the user
/// knows *why* the vote failed (proximity / rate limit / guest) instead of
/// a generic error.
String upvoteErrorMessage(Object err) {
  final lower = err.toString().toLowerCase();
  if (err is ApiServerException) {
    final code = err.code.toLowerCase();
    if (code.contains('proximity') ||
        code.contains('too_far') ||
        lower.contains('proximity') ||
        lower.contains('too far')) {
      return 'You must be near this issue to upvote it';
    }
    if (code.contains('rate') ||
        lower.contains('rate') ||
        lower.contains('too many')) {
      return 'Too many upvotes. Please try again in a moment';
    }
    if (code.contains('guest') ||
        lower.contains('guest') ||
        lower.contains('sign in')) {
      return 'Please sign in to upvote issues';
    }
  }
  return friendlyErrorMessage(err, fallback: 'Failed to toggle upvote');
}

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
    final coords = ref.read(feedCoordinatesProvider).valueOrNull;
    if (coords != null) return coords;
    return (lat: defaultLatitude, lng: defaultLongitude);
  } catch (_) {
    return (lat: defaultLatitude, lng: defaultLongitude);
  }
}

/// Performs the upvote API call cleanly using [FeedRepository].
/// Calls [FeedRepository.removeUpvote] when [currentlyUpvoted] is true,
/// and [FeedRepository.upvoteIssue] when false.
Future<Issue> _performUpvote(
  FeedRepository repository,
  int issueId,
  double latitude,
  double longitude,
  bool currentlyUpvoted,
) async {
  if (currentlyUpvoted) {
    return repository.removeUpvote(issueId);
  } else {
    return repository.upvoteIssue(
      issueId,
      latitude: latitude,
      longitude: longitude,
    );
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
    ref.invalidate(feedCoordinatesProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> toggleUpvote(
    int issueId,
    double latitude,
    double longitude, {
    bool? currentlyUpvoted,
  }) async {
    final previousState = state;
    final currentItems = state.value;

    final index = currentItems?.indexWhere(
          (item) =>
              item.itemType == FeedItemType.issue && item.issue?.id == issueId,
        ) ??
        -1;

    final isUpvoted = (index != -1 && currentItems != null)
        ? currentItems[index].issue!.hasUpvoted
        : (currentlyUpvoted ?? false);

    if (currentItems != null && index != -1) {
      final targetIssue = currentItems[index].issue!;
      final updatedIssue = targetIssue.copyWith(
        hasUpvoted: !isUpvoted,
        upvotesCount: isUpvoted
            ? (targetIssue.upvotesCount > 0 ? targetIssue.upvotesCount - 1 : 0)
            : targetIssue.upvotesCount + 1,
      );

      final updatedList = List<FeedItem>.from(currentItems);
      updatedList[index] =
          FeedItem(itemType: FeedItemType.issue, issue: updatedIssue);
      state = AsyncData(updatedList);
    }

    try {
      final repository = ref.read(feedRepositoryProvider);
      final responseIssue = await _performUpvote(
        repository,
        issueId,
        latitude,
        longitude,
        isUpvoted,
      );

      final latestItems = state.value;
      if (latestItems != null) {
        final latestIndex = latestItems.indexWhere(
          (i) => i.itemType == FeedItemType.issue && i.issue?.id == issueId,
        );
        if (latestIndex != -1) {
          final refreshedList = List<FeedItem>.from(latestItems);
          refreshedList[latestIndex] =
              FeedItem(itemType: FeedItemType.issue, issue: responseIssue);
          state = AsyncData(refreshedList);
        }
      }
    } catch (err) {
      state = previousState;
      ref.read(appMessengerProvider.notifier).show(upvoteErrorMessage(err));
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
    ref.invalidate(feedCoordinatesProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
