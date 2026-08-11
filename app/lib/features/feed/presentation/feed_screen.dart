import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_list.dart';
import '../../geo/presentation/providers/geo_providers.dart';
import '../../geo/presentation/widgets/ward_location_chip.dart';
import '../../outbox/presentation/outbox_screen.dart';
import '../../compose/presentation/compose_providers.dart';
import '../domain/feed_item.dart';
import 'feed_providers.dart';
import 'widgets/issue_card.dart';
import 'widgets/local_talk_card.dart';
import 'widgets/notice_card.dart';
import 'widgets/win_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(multiTypeFeedProvider);
    final selectedFilter = ref.watch(feedFilterProvider);
    final pendingOutboxCount =
        ref.watch(offlineOutboxProvider).pendingCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('feed_title'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (pendingOutboxCount > 0)
            IconButton(
              key: const Key('feedOutboxButton'),
              tooltip: context.tr('outbox_title'),
              icon: Badge(
                label: Text('$pendingOutboxCount'),
                child: const Icon(Icons.cloud_upload_outlined),
              ),
              onPressed: () => context.push(RoutePaths.outbox),
            ),
          IconButton(
            tooltip: context.tr('action_search'),
            icon: const Icon(Icons.search),
            onPressed: () => context.push(RoutePaths.search),
          ),
          IconButton(
            tooltip: context.tr('action_notifications'),
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(RoutePaths.notifications),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Column(
            children: [
              Align(
                key: const Key('feedAreaLabel'),
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: WardLocationChip(
                    state: ref.watch(wardLocationProvider),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip(context, ref, 'all',
                        context.tr('feed_filter_all'), selectedFilter,
                        const Key('feedFilterChip_all')),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, ref, 'issue',
                        context.tr('feed_filter_issues'), selectedFilter,
                        const Key('feedFilterChip_issues')),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, ref, 'win',
                        context.tr('feed_filter_wins'), selectedFilter,
                        const Key('feedFilterChip_wins')),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, ref, 'notice',
                        context.tr('feed_filter_notices'), selectedFilter,
                        const Key('feedFilterChip_notices')),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, ref, 'local_talk',
                        context.tr('feed_filter_talk'), selectedFilter,
                        const Key('feedFilterChip_local_talk')),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: feedAsync.when(
        loading: () =>
            const Padding(padding: EdgeInsets.all(16), child: SkeletonList()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            icon: Icons.cloud_off_outlined,
            title: context.tr('feed_unavailable'),
            message: context.tr('feed_unavailable_msg'),
            actionLabel: context.tr('action_retry'),
            onAction: () => ref.read(multiTypeFeedProvider.notifier).refresh(),
          ),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.check_circle_outline,
                title: context.tr('feed_empty_title'),
                message: context.tr('feed_empty_msg'),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(multiTypeFeedProvider.notifier).refresh(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return _buildEndOfFeedWidget(context);
                    }
                    final item = items[index];
                    switch (item.itemType) {
                      case FeedItemType.win:
                        if (item.win != null) return WinCard(win: item.win!);
                        break;
                      case FeedItemType.notice:
                        if (item.notice != null) return NoticeCard(notice: item.notice!);
                        break;
                      case FeedItemType.localTalk:
                        if (item.localTalk != null) return LocalTalkCard(post: item.localTalk!);
                        break;
                      case FeedItemType.issue:
                        if (item.issue != null) return IssueCard(issue: item.issue!);
                        break;
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String value,
    String label,
    String currentFilter,
    Key key,
  ) {
    final isSelected = currentFilter == value;
    return FilterChip(
      key: key,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(feedFilterProvider.notifier).state = value;
      },
    );
  }

  Widget _buildEndOfFeedWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const Key('endOfFeedState'),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.task_alt, color: theme.colorScheme.primary, size: 36),
          const SizedBox(height: 8),
          Text(
            context.tr('feed_end_of_feed'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('feed_end_of_feed_msg'),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
