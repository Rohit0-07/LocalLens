import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../geo/presentation/providers/geo_providers.dart';
import '../../geo/presentation/widgets/ward_location_chip.dart';
import '../../compose/presentation/compose_providers.dart';
import '../../notifications/presentation/controllers/notifications_controller.dart';
import '../domain/feed_item.dart';
import 'feed_providers.dart';
import 'widgets/feed_empty_state.dart';
import 'widgets/feed_skeleton_list.dart';
import 'widgets/issue_card.dart';
import 'widgets/local_talk_card.dart';
import 'widgets/notice_card.dart';
import 'widgets/win_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  bool _showHeader = true;
  double _accumulatedDy = 0;

  // Thresholds tuned for smoothness – higher show threshold prevents slight bounce:
  // - hide after ~56px of continuous downward drag
  // - show after ~84px of continuous upward drag (slight up won't trigger)
  static const double _hideThreshold = 56;
  static const double _showThreshold = 84;

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    // Always show when at the very top (overscroll / bounce area).
    if (notification.metrics.pixels <= 0) {
      if (!_showHeader) setState(() => _showHeader = true);
      _accumulatedDy = 0;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta == 0) return false;

      // Direction flipped → reset accumulation (prevents tiny jitter from adding up)
      if ((_accumulatedDy > 0 && delta < 0) ||
          (_accumulatedDy < 0 && delta > 0)) {
        _accumulatedDy = delta;
      } else {
        _accumulatedDy += delta;
      }

      if (_accumulatedDy > _hideThreshold && _showHeader) {
        setState(() {
          _showHeader = false;
          _accumulatedDy = 0;
        });
      } else if (_accumulatedDy < -_showThreshold && !_showHeader) {
        setState(() {
          _showHeader = true;
          _accumulatedDy = 0;
        });
      }
    } else if (notification is ScrollEndNotification) {
      // Idle → reset so next gesture starts fresh; don't auto-show/hide here.
      _accumulatedDy = 0;
    } else if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      _accumulatedDy = 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedAsync = ref.watch(multiTypeFeedProvider);
    final selectedFilter = ref.watch(feedFilterProvider);
    final selectedScope = ref.watch(feedScopeProvider);
    final pendingOutboxCount = ref.watch(offlineOutboxProvider).pendingCount;
    final unreadNotificationCount = ref.watch(unreadNotificationCountProvider);

    final header = Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title + actions row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    key: const Key('feedTitleTap'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      ref.invalidate(feedCoordinatesProvider);
                      ref.read(multiTypeFeedProvider.notifier).refresh();
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.lens_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          context.tr('feed_title'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (pendingOutboxCount > 0)
                    IconButton(
                      key: const Key('feedOutboxButton'),
                      tooltip: context.tr('outbox_title'),
                      icon: Badge(
                        label: Text('$pendingOutboxCount'),
                        backgroundColor: AppColors.brand,
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
                    key: const Key('feedNotificationButton'),
                    tooltip: context.tr('notifications_title'),
                    icon: Badge(
                      isLabelVisible: unreadNotificationCount > 0,
                      label: Text('$unreadNotificationCount'),
                      backgroundColor: AppColors.brand,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: () => context.push(RoutePaths.notifications),
                  ),
                ],
              ),
            ),
            // Ward chip + filters
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
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildScopeChip(
                    context,
                    ref,
                    FeedScope.allWards,
                    context.tr('feed_scope_all'),
                    selectedScope,
                    const Key('feedScopeChip_all'),
                  ),
                  const SizedBox(width: 8),
                  _buildScopeChip(
                    context,
                    ref,
                    FeedScope.myWard,
                    context.tr('feed_scope_my_ward'),
                    selectedScope,
                    const Key('feedScopeChip_my_ward'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    'all',
                    context.tr('feed_filter_all'),
                    selectedFilter,
                    const Key('feedFilterChip_all'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    'issue',
                    context.tr('feed_filter_issues'),
                    selectedFilter,
                    const Key('feedFilterChip_issues'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    'win',
                    context.tr('feed_filter_wins'),
                    selectedFilter,
                    const Key('feedFilterChip_wins'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    'notice',
                    context.tr('feed_filter_notices'),
                    selectedFilter,
                    const Key('feedFilterChip_notices'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    'local_talk',
                    context.tr('feed_filter_talk'),
                    selectedFilter,
                    const Key('feedFilterChip_local_talk'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.15)),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeInOutCubic,
            height: _showHeader ? null : 0,
            child: ClipRect(
              child: AnimatedSlide(
                key: const Key('feedHeader'),
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeInOutCubic,
                offset: _showHeader ? Offset.zero : const Offset(0, -1.0),
                child: header,
              ),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: feedAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: FeedSkeletonList(key: Key('feedSkeleton'), itemCount: 4),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: FeedEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Unavailable',
                    message: 'Feed unavailable',
                    actionLabel: 'Retry',
                    onAction: () => ref.read(multiTypeFeedProvider.notifier).refresh(),
                  ),
                ),
                data: (items) => items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          FeedEmptyState(
                            key: const Key('feedEmptyState'),
                            icon: Icons.check_circle_outline,
                            title: context.tr('feed_empty_title'),
                            message: context.tr('feed_empty_msg'),
                          ),
                        ],
                      )
                    : RefreshIndicator(
                        color: AppColors.brand,
                        onRefresh: () => ref.read(multiTypeFeedProvider.notifier).refresh(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: items.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == items.length) {
                              return _buildEndOfFeedWidget(context);
                            }
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
          ),
        ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      key: key,
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: isDark
          ? AppColors.brand.withValues(alpha: 0.22)
          : AppColors.brandLight,
      backgroundColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? AppColors.brand
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        width: isSelected ? 1.4 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.brand
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      onSelected: (_) {
        ref.read(feedFilterProvider.notifier).state = value;
      },
    );
  }

  Widget _buildScopeChip(
    BuildContext context,
    WidgetRef ref,
    FeedScope value,
    String label,
    FeedScope currentScope,
    Key key,
  ) {
    final isSelected = currentScope == value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      key: key,
      avatar: Icon(
        value == FeedScope.allWards
            ? Icons.public_outlined
            : Icons.location_on_outlined,
        size: 15,
        color: isSelected ? AppColors.brand : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: isDark
          ? AppColors.brand.withValues(alpha: 0.22)
          : AppColors.brandLight,
      backgroundColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? AppColors.brand
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        width: isSelected ? 1.4 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.brand
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      onSelected: (_) {
        ref.read(feedScopeProvider.notifier).state = value;
      },
    );
  }

  Widget _buildEndOfFeedWidget(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      key: const Key('endOfFeedState'),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.brand.withValues(alpha: 0.2)
                  : AppColors.brandLight,
              border: Border.all(
                color: AppColors.brand.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.brand,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('feed_end_of_feed'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('feed_end_of_feed_msg'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
