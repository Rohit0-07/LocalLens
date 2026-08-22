import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../shared/widgets/media_preview_widget.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../auth/presentation/widgets/guest_guard.dart';
import '../../../issue_detail/presentation/widgets/comments_section.dart';
import '../../../issues/presentation/widgets/flag_issue_dialog.dart';
import '../../domain/feed_item.dart';
import '../../domain/win.dart';
import '../feed_providers.dart';
import 'social_action.dart';

/// Twitter-style "COMMUNITY WIN" card with an Instagram-style swipeable
/// before/after gallery. Emerald reads as the reward/success signal across themes.
class WinCard extends ConsumerStatefulWidget {
  final WinItem win;

  const WinCard({super.key, required this.win});

  @override
  ConsumerState<WinCard> createState() => _WinCardState();
}

class _WinCardState extends ConsumerState<WinCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _localHasUpvoted = false;

  List<MediaItem> get _galleryItems => [
    if (widget.win.beforeImageUrl != null)
      MediaItem(
        url: widget.win.beforeImageUrl!,
        label: 'BEFORE: ${widget.win.title}',
      ),
    if (widget.win.afterImageUrl != null)
      MediaItem(
        url: widget.win.afterImageUrl!,
        label: 'AFTER: ${widget.win.title}',
      ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareWin(BuildContext context) async {
    final deepLink = 'locallens://issue/${widget.win.issueId}';
    try {
      await SharePlus.instance.share(
        ShareParams(text: '${widget.win.title} — LocalLens\n$deepLink'),
      );
    } catch (_) {}
  }

  void _flagWin(BuildContext context, WidgetRef ref) {
    final session = ref.read(sessionProvider);
    final isGuestUser = session == null || session.isGuest;
    if (isGuestUser) {
      showDialog(
        context: context,
        builder: (_) => const GuestGuard(),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => FlagIssueDialog(issueId: widget.win.issueId),
      );
    }
  }

  void _showCommentsModal(BuildContext context) {
    final win = widget.win;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          win.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        tooltip: 'View Full Issue',
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push(RoutePaths.issueDetailFor(win.issueId));
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: CommentsSection(issueId: win.issueId),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final win = widget.win;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final galleryItems = _galleryItems;

    // Prefer live upvote state from the feed's issue item when the underlying
    // issue is also in the feed; fall back to local optimistic state.
    final multiFeed = ref.watch(multiTypeFeedProvider);
    final linkedIssue = multiFeed.asData?.value
        .where((item) => item.itemType == FeedItemType.issue)
        .map((item) => item.issue)
        .firstWhere((i) => i?.id == win.issueId, orElse: () => null);
    final hasUpvoted = linkedIssue?.hasUpvoted ?? _localHasUpvoted;
    final upvotesCount =
        linkedIssue?.upvotesCount ?? (_localHasUpvoted ? 1 : 0);

    return Card(
      key: Key('winCard_${win.id}'),
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RoutePaths.issueDetailFor(win.issueId)),
        child: Container(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.win,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'COMMUNITY WIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    key: Key('winCardOverflow_${win.id}'),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        key: Key('flagIssueOption_${win.issueId}'),
                        value: 'flag',
                        onTap: () => _flagWin(context, ref),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: AppColors.urgent,
                            ),
                            const SizedBox(width: 8),
                            Text(context.tr('flag_issue')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                win.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (win.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  win.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),

              // Instagram-style swipeable before / after gallery
              if (galleryItems.isNotEmpty)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: galleryItems.length,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              itemBuilder: (context, index) {
                                final item = galleryItems[index];
                                return GestureDetector(
                                  onTap: () =>
                                      MediaPreviewWidget.openFullScreen(
                                        context,
                                        items: galleryItems,
                                        initialIndex: index,
                                        title: 'Community Win: Before & After',
                                      ),
                                  child: _GalleryImage(item: item),
                                );
                              },
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: _buildLabel(
                                galleryItems[_currentPage].label ==
                                        'BEFORE: ${win.title}'
                                    ? 'BEFORE'
                                    : 'AFTER',
                                _currentPage == 0
                                    ? Colors.amber.shade800
                                    : AppColors.win,
                              ),
                            ),
                            if (galleryItems.length > 1)
                              Positioned(
                                bottom: 8,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    galleryItems.length,
                                    (index) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      width: _currentPage == index ? 16 : 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: _currentPage == index
                                            ? Colors.white
                                            : Colors.white54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swipe_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Swipe to compare before & after',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              if (win.contributorCredits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: win.contributorCredits.map((credit) {
                    return Chip(
                      avatar: const Icon(Icons.person_pin, size: 14),
                      label: Text(credit, style: const TextStyle(fontSize: 12)),
                      labelStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: colorScheme.outlineVariant),
                      backgroundColor: colorScheme.surfaceContainerLow,
                    );
                  }).toList(),
                ),
              ],

              // ── Footer Actions (same row as IssueCard) ────────────────
              const SizedBox(height: 12),
              Row(
                key: Key('winActions_${win.id}'),
                children: [
                  SocialAction(
                    key: Key('upvote_button_${win.issueId}'),
                    icon: hasUpvoted
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_up_outlined,
                    color: hasUpvoted
                        ? AppColors.brand
                        : colorScheme.onSurfaceVariant,
                    backgroundColor: hasUpvoted
                        ? AppColors.brand.withValues(alpha: 0.12)
                        : Colors.transparent,
                    label: Text('$upvotesCount'),
                    onTap: () async {
                      setState(() => _localHasUpvoted = !hasUpvoted);
                      try {
                        await ref
                            .read(multiTypeFeedProvider.notifier)
                            .toggleUpvote(
                              win.issueId,
                              win.latitude,
                              win.longitude,
                              currentlyUpvoted: hasUpvoted,
                            );
                      } catch (err) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(upvoteErrorMessage(err)),
                            ),
                          );
                        }
                        if (mounted) {
                          setState(() => _localHasUpvoted = hasUpvoted);
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  SocialAction(
                    key: Key('comment_button_${win.issueId}'),
                    icon: Icons.chat_bubble_outline_rounded,
                    color: colorScheme.onSurfaceVariant,
                    label: CommentCount(issueId: win.issueId),
                    onTap: () => _showCommentsModal(context),
                  ),
                  const Spacer(),
                  SocialAction(
                    key: Key('share_button_${win.issueId}'),
                    icon: Icons.share_outlined,
                    color: colorScheme.onSurfaceVariant,
                    label: const SizedBox.shrink(),
                    tooltip: context.tr('action_share'),
                    onTap: () => _shareWin(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Full-bleed image inside the swipeable gallery with shimmer + fallback.
class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          resolveMediaUrl(item.url),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return ShimmerLoading(
              child: Container(
                color: isDark
                    ? AppColors.skeletonBaseDark
                    : AppColors.skeletonBase,
              ),
            );
          },
          errorBuilder: (_, _, _) => Container(
            color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE8EEF5),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
