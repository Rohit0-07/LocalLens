import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_list.dart';
import '../../feed/domain/feed_item.dart';
import '../../feed/domain/issue.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../feed/presentation/widgets/issue_card.dart';
import '../../feed/presentation/widgets/local_talk_card.dart';
import '../../feed/presentation/widgets/notice_card.dart';
import '../../feed/presentation/widgets/win_card.dart';
import 'advanced_filter_sheet.dart';
import 'search_filters_provider.dart';
import 'search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String text) {
    final trimmed = text.trim();
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).state = trimmed;
    if (trimmed.isEmpty) return;
    _lastQuery = trimmed;
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _runSearch(trimmed);
    });
  }

  void _runSearch(String query) {
    if (query.trim().isEmpty) return;
    ref.read(searchResultsProvider.notifier).runQuery(query);
  }

  void _runRecentSearch(String term) {
    _debounce?.cancel();
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(offset: term.length);
    _lastQuery = term.trim();
    ref.read(searchQueryProvider.notifier).state = term.trim();
    _runSearch(term);
  }

  void _retryLastQuery() {
    if (_lastQuery.isEmpty) return;
    _runSearch(_lastQuery);
  }

  Future<void> _openFilters() async {
    final result = await showAdvancedFilterSheet(
      context,
      initial: ref.read(searchFiltersProvider),
    );
    if (result != null) {
      ref.read(searchFiltersProvider.notifier).apply(result);
      _runSearch(_lastQuery.isEmpty ? _controller.text.trim() : _lastQuery);
    }
  }

  void _clearFilters() {
    ref.read(searchFiltersProvider.notifier).reset();
    _runSearch(_lastQuery);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final recents = ref.watch(recentSearchesProvider);
    final results = ref.watch(searchResultsProvider);
    final filtersActive = ref.watch(searchFiltersProvider).isActive;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('searchField'),
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search issues, categories, wards',
            border: InputBorder.none,
          ),
          onChanged: _onQueryChanged,
        ),
        actions: [
          IconButton(
            key: const Key('filterButton'),
            tooltip: 'Filters',
            icon: filtersActive
                ? Badge(smallSize: 8, child: const Icon(Icons.tune))
                : const Icon(Icons.tune),
            onPressed: _openFilters,
          ),
          if (filtersActive)
            TextButton(
              key: const Key('clearFiltersButton'),
              onPressed: _clearFilters,
              child: const Text('Clear filters'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: query.isEmpty
          ? _buildPreloadedBody(recents)
          : _buildResultsBody(results),
    );
  }

  Widget _buildPreloadedBody(List<String> recents) {
    final feedAsync = ref.watch(multiTypeFeedProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent searches',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('clearRecentSearches'),
                      onPressed: () =>
                          ref.read(recentSearchesProvider.notifier).clear(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recents.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final term = recents[index];
                      return ActionChip(
                        key: Key('recentChip_$term'),
                        avatar: const Icon(Icons.history, size: 18),
                        label: Text(term),
                        onPressed: () => _runRecentSearch(term),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: feedAsync.when(
            loading: () =>
                const Padding(padding: EdgeInsets.all(16), child: SkeletonList()),
            error: (_, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Feed unavailable',
              message: 'We could not load the latest issues right now.',
              actionLabel: 'Retry',
              onAction: () => ref.read(multiTypeFeedProvider.notifier).refresh(),
            ),
            data: (items) => items.isEmpty
                ? const EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No issues yet',
                    message: 'Be the first to report an issue near you.',
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(multiTypeFeedProvider.notifier).refresh(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        switch (item.itemType) {
                          case FeedItemType.win:
                            if (item.win != null) {
                              return WinCard(win: item.win!);
                            }
                          case FeedItemType.notice:
                            if (item.notice != null) {
                              return NoticeCard(notice: item.notice!);
                            }
                          case FeedItemType.localTalk:
                            if (item.localTalk != null) {
                              return LocalTalkCard(post: item.localTalk!);
                            }
                          case FeedItemType.issue:
                            if (item.issue != null) {
                              return IssueCard(issue: item.issue!);
                            }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsBody(AsyncValue<List<Issue>> results) {
    return results.when(
      loading: () =>
          const Padding(padding: EdgeInsets.all(16), child: SkeletonList()),
      error: (_, _) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Search unavailable',
        message: 'We could not reach the server right now.',
        actionLabel: 'Retry',
        onAction: _retryLastQuery,
      ),
      data: (issues) => issues.isEmpty
          ? const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'No issues found',
              message: 'Try a different keyword.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: issues.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => IssueCard(issue: issues[index]),
            ),
    );
  }
}