import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

/// Shimmer skeleton for the feed list, matching the NEW decluttered card
/// geometry: header row (avatar + name/meta bars), title bar, status bar,
/// and a lighter media block.
class FeedSkeletonList extends StatelessWidget {
  const FeedSkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) => const _FeedSkeletonCard(),
      ),
    );
  }
}

class _FeedSkeletonCard extends StatelessWidget {
  const _FeedSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: avatar + name / meta bars ──────────────────
            Row(
              children: [
                _bar(width: 36, height: 36, borderRadius: 18, isDark: isDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(width: 120, height: 12, isDark: isDark),
                      const SizedBox(height: 6),
                      _bar(width: 190, height: 10, isDark: isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Title bar ───────────────────────────────────────────────
            _bar(width: double.infinity, height: 16, isDark: isDark),
            const SizedBox(height: 6),
            _bar(width: 220, height: 16, isDark: isDark),
            const SizedBox(height: 10),
            // ── Status bar ──────────────────────────────────────────────
            _bar(width: 96, height: 22, borderRadius: 8, isDark: isDark),
            const SizedBox(height: 10),
            // ── Media block ─────────────────────────────────────────────
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBase,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({
    required double width,
    required double height,
    required bool isDark,
    double borderRadius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}