import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/utils/string_formatters.dart';
import '../../feed/domain/issue.dart';
import '../presentation/reels_providers.dart';

/// Instagram-Reels-style vertical, full-screen, infinitely scrolling feed of
/// issues that carry photos. Swipe up to move through each civic "reel".
class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _maybeLoadMore(int index, ReelsState state) {
    if (index >= state.items.length - 2) {
      ref.read(reelsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reelsAsync = ref.watch(reelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: reelsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Reels are unavailable right now',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(reelsProvider.notifier).refresh(),
                child: Text(context.tr('action_retry')),
              ),
            ],
          ),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      color: Colors.white54, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'No reels yet — upload photos with an issue to see them here',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.push(RoutePaths.compose),
                    child: const Text('Create a Reel'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: state.items.length,
                onPageChanged: (index) => _maybeLoadMore(index, state),
                itemBuilder: (context, index) {
                  final issue = state.items[index].issue!;
                  return _ReelPage(issue: issue, index: index);
                },
              ),
              // Header
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
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
                    const SizedBox(width: 10),
                    const Text(
                      'Reels',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const Key('reelsRefreshButton'),
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white70),
                      onPressed: () =>
                          ref.read(reelsProvider.notifier).refresh(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A single full-screen reel: media up top, issue details overlaid bottom.
class _ReelPage extends StatelessWidget {
  const _ReelPage({required this.issue, required this.index});

  final Issue issue;
  final int index;

  @override
  Widget build(BuildContext context) {
    final mediaUrl =
        issue.mediaUrls.isNotEmpty ? issue.mediaUrls.first : null;

    return GestureDetector(
      onTap: () => context.push(RoutePaths.issueDetailFor(issue.id)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mediaUrl != null)
            Image.network(
              resolveMediaUrl(mediaUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPlaceholder(context),
            )
          else
            _buildPlaceholder(context),
          // Gradient scrim for legibility
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          // Bottom info panel
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.categorySurfaceFor(
                          issue.category,
                          isDark: true,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        StringFormatters.humanize(issue.category).toUpperCase(),
                        style: TextStyle(
                          color: AppColors.categoryColorFor(issue.category),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${issue.ward} • ${formatRelativeTime(issue.createdAt)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  issue.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (issue.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    issue.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      issue.reporterLabel,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.thumb_up_outlined,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${issue.upvotesCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    const Icon(Icons.swipe_up_rounded,
                        color: Colors.white54, size: 20),
                  ],
                ),
              ],
            ),
          ),
          // Index chip
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: const Color(0xFF14171F),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, color: Colors.white38, size: 56),
          const SizedBox(height: 8),
          Text(
            issue.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}