import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../shared/widgets/media_preview_widget.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../domain/win.dart';

/// Twitter-style "COMMUNITY WIN" card with an Instagram-style swipeable
/// before/after gallery. Emerald reads as the reward/success signal across themes.
class WinCard extends StatefulWidget {
  final WinItem win;

  const WinCard({super.key, required this.win});

  @override
  State<WinCard> createState() => _WinCardState();
}

class _WinCardState extends State<WinCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
        ShareParams(
          text: '${widget.win.title} — LocalLens\n$deepLink',
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final win = widget.win;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final galleryItems = _galleryItems;

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
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  tooltip: 'Share',
                  onPressed: () => _shareWin(context),
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
                                  title:
                                      'Community Win: Before & After',
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
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: List.generate(
                                  galleryItems.length,
                                  (index) => AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
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
                      Icon(Icons.swipe_rounded,
                          size: 14, color: colorScheme.onSurfaceVariant),
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
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    backgroundColor: colorScheme.surfaceContainerLow,
                  );
                }).toList(),
              ),
            ],
          ],
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
                color: isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBase,
              ),
            );
          },
          errorBuilder: (_, _, _) => Container(
            color: isDark
                ? const Color(0xFF1E2430)
                : const Color(0xFFE8EEF5),
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
