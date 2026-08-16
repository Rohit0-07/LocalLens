import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/domain/feed_item.dart';
import '../../feed/domain/feed_repository.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../geo/presentation/providers/geo_providers.dart';

/// A paginated, cursor-driven list of issues with media for the Reels-style
/// vertical infinite feed. Only issues that actually have attached media are
/// surfaced, so every reel is visually driven.
class ReelsState {
  final List<FeedItem> items;
  final String? cursor;
  final bool hasMore;
  final bool isLoadingMore;

  const ReelsState({
    this.items = const [],
    this.cursor,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  ReelsState copyWith({
    List<FeedItem>? items,
    String? cursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ReelsState(
      items: items ?? this.items,
      cursor: cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final reelsProvider =
    AsyncNotifierProvider<ReelsController, ReelsState>(ReelsController.new);

class ReelsController extends AsyncNotifier<ReelsState> {
  FeedRepository get _repo => ref.read(feedRepositoryProvider);

  Future<({double lat, double lng})> _coords() async {
    try {
      return await ref.watch(feedCoordinatesProvider.future);
    } catch (_) {
      return (lat: defaultLatitude, lng: defaultLongitude);
    }
  }

  @override
  Future<ReelsState> build() async {
    return _fetchPage();
  }

  Future<ReelsState> _fetchPage({String? cursor}) async {
    final coords = await _coords();
    final items = await _repo.fetchMultiTypeFeed(
      latitude: coords.lat,
      longitude: coords.lng,
      type: 'issue',
      cursor: cursor,
      limit: 10,
    );
    final mediaItems =
        items.where((i) => i.issue?.mediaUrls.isNotEmpty ?? false).toList();
    final last = mediaItems.isNotEmpty ? mediaItems.last : (items.isNotEmpty ? items.last : null);
    return ReelsState(
      items: mediaItems,
      cursor: last?.issue?.createdAt.toUtc().toIso8601String(),
      hasMore: items.length >= 10,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetchPage(cursor: current.cursor);
      final merged = ReelsState(
        items: [...current.items, ...next.items],
        cursor: next.cursor ?? current.cursor,
        hasMore: next.hasMore,
        isLoadingMore: false,
      );
      state = AsyncData(merged);
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}