import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feedback/app_messenger.dart';
import '../../../core/network/network_providers.dart';
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

final multiTypeFeedProvider = AsyncNotifierProvider<MultiTypeFeedController, List<FeedItem>>(
  MultiTypeFeedController.new,
);

class MultiTypeFeedController extends AsyncNotifier<List<FeedItem>> {
  @override
  Future<List<FeedItem>> build() {
    final repository = ref.watch(feedRepositoryProvider);
    final filter = ref.watch(feedFilterProvider);
    return repository.fetchMultiTypeFeed(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
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
      Issue responseIssue;
      final repoDynamic = repository as dynamic;
      if (currentlyUpvoted) {
        try {
          responseIssue = await repoDynamic.removeUpvote(issueId);
        } on NoSuchMethodError catch (_) {
          responseIssue = await repoDynamic.toggleUpvote(issueId);
        }
      } else {
        try {
          responseIssue = await repoDynamic.upvoteIssue(issueId, latitude, longitude);
        } on NoSuchMethodError catch (_) {
          responseIssue = await repoDynamic.toggleUpvote(issueId);
        }
      }

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
  Future<List<Issue>> build() {
    final repository = ref.watch(feedRepositoryProvider);
    return repository.fetchNearby(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> toggleUpvote(int issueId, double latitude, double longitude) async {
    final previousState = state;
    final currentIssues = state.value;
    if (currentIssues == null) return;

    final index = currentIssues.indexWhere((issue) => issue.id == issueId);
    if (index == -1) return;

    final targetIssue = currentIssues[index];
    final currentlyUpvoted = targetIssue.hasUpvoted;
    final updatedIssue = targetIssue.copyWith(
      hasUpvoted: !currentlyUpvoted,
      upvotesCount: currentlyUpvoted
          ? (targetIssue.upvotesCount > 0 ? targetIssue.upvotesCount - 1 : 0)
          : targetIssue.upvotesCount + 1,
    );

    final updatedList = List<Issue>.from(currentIssues);
    updatedList[index] = updatedIssue;
    state = AsyncData(updatedList);

    try {
      final repository = ref.read(feedRepositoryProvider);
      Issue responseIssue;
      final repoDynamic = repository as dynamic;
      if (currentlyUpvoted) {
        try {
          responseIssue = await repoDynamic.removeUpvote(issueId);
        } on NoSuchMethodError catch (_) {
          responseIssue = await repoDynamic.toggleUpvote(issueId);
        }
      } else {
        try {
          responseIssue = await repoDynamic.upvoteIssue(issueId, latitude, longitude);
        } on NoSuchMethodError catch (_) {
          responseIssue = await repoDynamic.toggleUpvote(issueId);
        }
      }

      final latestIssues = state.value;
      if (latestIssues != null) {
        final latestIndex = latestIssues.indexWhere((i) => i.id == issueId);
        if (latestIndex != -1) {
          final refreshedList = List<Issue>.from(latestIssues);
          refreshedList[latestIndex] = responseIssue;
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
