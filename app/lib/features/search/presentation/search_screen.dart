import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/string_formatters.dart';
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
import '../domain/search_error_kind.dart';
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
    _runSearch(_lastQuery);
  }

  Future<void> _openFilters() async {
    final result = await showAdvancedFilterSheet(
      context,
      initial: ref.read(searchFiltersProvider),
    );
    if (result != null) {
      ref.read(searchFiltersProvider.notifier).apply(result);
      final query = _controller.text.trim();
      _runSearch(query);
    }
  }

  void _clearFilters() {
    ref.read(searchFiltersProvider.notifier).reset();
    _runSearch(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final recents = ref.watch(recentSearchesProvider);
    final results = ref.watch(searchResultsProvider);
    final filters = ref.watch(searchFiltersProvider);
    final filtersActive = filters.isActive;

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
          onSubmitted: (text) {
            final trimmed = text.trim();
            if (trimmed.isNotEmpty) {
              _lastQuery = trimmed;
              _runSearch(trimmed);
            }
          },
        ),
        actions: [
          IconButton(
            key: const Key('filterButton'),
            tooltip: context.tr('filter_title'),
            icon: filtersActive
                ? Badge(smallSize: 8, child: const Icon(Icons.tune))
                : const Icon(Icons.tune),
            onPressed: _openFilters,
          ),
          if (filtersActive)
            TextButton(
              key: const Key('clearFiltersButton'),
              onPressed: _clearFilters,
              child: Text(context.tr('search_clear_filters')),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Active Ward Filter Display ─────────────────────
          if (filters.ward != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.location_city, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Ward: ${StringFormatters.formatWard(filters.ward)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.read(searchFiltersProvider.notifier).setWard(null);
                      _runSearch(_controller.text.trim());
                    },
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          // ── Active Account Filter Display ──────────────────
          if (filters.account != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.alternate_email_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Account: @${filters.account}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.read(searchFiltersProvider.notifier).apply(filters.copyWith(account: null));
                      _runSearch(_controller.text.trim());
                    },
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          // ── Body ──────────────────────────────────────────
          Expanded(
            child: query.isEmpty && !filtersActive
                ? _buildPreloadedBody(recents)
                : _buildResultsBody(results),
          ),
        ],
      ),
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
                      child: Text(context.tr('search_clear')),
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
                            break;
                          case FeedItemType.notice:
                            if (item.notice != null) {
                              return NoticeCard(notice: item.notice!);
                            }
                            break;
                          case FeedItemType.localTalk:
                            if (item.localTalk != null) {
                              return LocalTalkCard(post: item.localTalk!);
                            }
                            break;
                          case FeedItemType.issue:
                            if (item.issue != null) {
                              return IssueCard(issue: item.issue!);
                            }
                            break;
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
      error: (error, _) => _buildSearchErrorState(classifySearchError(error)),
      data: (issues) => issues.isEmpty
          ? const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'No issues found',
              message: 'Try a different keyword or adjust your filters.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: issues.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => IssueCard(issue: issues[index]),
            ),
    );
  }

  Widget _buildSearchErrorState(SearchErrorKind kind) {
    return switch (kind) {
      SearchErrorKind.network => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Search unavailable',
        message:
            'We could not reach the server. Check your connection and make '
            'sure the app can reach the backend.',
        actionLabel: 'Retry',
        onAction: _retryLastQuery,
      ),
      SearchErrorKind.rateLimited => EmptyState(
        icon: Icons.timer_outlined,
        title: 'Too many searches',
        message: 'You have made too many searches. Please wait a moment and '
            'try again.',
        actionLabel: 'Retry',
        onAction: _retryLastQuery,
      ),
      SearchErrorKind.invalidQuery => EmptyState(
        icon: Icons.search_off_outlined,
        title: 'Adjust your search',
        message: 'Your search could not be processed. Try different keywords '
            'or filters.',
        actionLabel: 'Retry',
        onAction: _retryLastQuery,
      ),
      SearchErrorKind.server => EmptyState(
        icon: Icons.error_outline,
        title: 'Search failed',
        message: 'The server ran into a problem. Please try again.',
        actionLabel: 'Retry',
        onAction: _retryLastQuery,
      ),
      SearchErrorKind.unauthorized => EmptyState(
        icon: Icons.lock_outline,
        title: 'Session expired',
        message: 'Please sign in again to search.',
        actionLabel: 'Retry',
        onAction: _retryLastQuery,
      ),
      SearchErrorKind.unexpected => EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message:
            'The server returned an unexpected response. Please try again.',
        actionLabel: 'Retry',
        onAction: _retryLastQuery,
      ),
    };
  }
}
