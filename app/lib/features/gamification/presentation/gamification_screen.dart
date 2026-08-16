import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/widgets/guest_guard.dart';
import '../domain/gamification_models.dart';
import 'gamification_providers.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(gamificationProfileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: const Key('gamificationScreen'),
      appBar: AppBar(
        title: Text(context.tr('gamification_title')),
      ),
      body: profileAsync.when(
        data: (profile) => _buildContent(context, ref, profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load gamification profile',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => ref.read(gamificationProfileProvider.notifier).refreshProfile(),
                child: Text(context.tr('action_retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, GamificationProfile profile) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(gamificationProfileProvider.notifier).refreshProfile();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImpactScoreCard(profile: profile),
            const SizedBox(height: 16.0),
            _StreakBanner(profile: profile),
            const SizedBox(height: 16.0),
            _BadgesGrid(userBadges: profile.badges),
            const SizedBox(height: 16.0),
            _ActivityBreakdownCard(counts: profile.activityCounts),
          ],
        ),
      ),
    );
  }
}

class _ImpactScoreCard extends StatelessWidget {
  const _ImpactScoreCard({required this.profile});

  final GamificationProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double progressFraction = profile.nextLevelScore == null || profile.nextLevelScore == 0
        ? 1.0
        : (profile.impactScore / profile.nextLevelScore!).clamp(0.0, 1.0);

    return Card(
      key: const Key('impactScoreCard'),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              '${profile.impactScore}',
              key: const Key('impactScoreValue'),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Impact Points',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              profile.levelName,
              key: const Key('levelNameLabel'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: LinearProgressIndicator(
                key: const Key('levelProgressBar'),
                value: progressFraction,
                minHeight: 10.0,
                backgroundColor: colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            if (profile.nextLevelScore != null) ...[
              const SizedBox(height: 8.0),
              Text(
                'Next Level: ${profile.nextLevelScore} pts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StreakBanner extends ConsumerWidget {
  const _StreakBanner({required this.profile});

  final GamificationProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: const Key('streakBanner'),
      color: colorScheme.secondaryContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: colorScheme.onSecondaryContainer,
                  size: 28,
                ),
                const SizedBox(width: 8.0),
                Text(
                  '${profile.streakDays} Day Streak',
                  key: const Key('streakDaysCounter'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              key: const Key('claimStreakButton'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: () async {
                if (profile.isGuest) {
                  showDialog(
                    context: context,
                    builder: (_) => const GuestGuard(),
                  );
                } else {
                  await ref.read(claimStreakNotifierProvider.notifier).claimStreak();
                  final claimState = ref.read(claimStreakNotifierProvider);
                  claimState.whenOrNull(
                    error: (err, st) {
                      final message = err.toString().replaceAll('Exception: ', '').replaceAll('AppError: ', '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
                  );
                }
              },
              child: Text(context.tr('gamification_claim_streak')),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  const _BadgesGrid({required this.userBadges});

  final List<BadgeItem> userBadges;

  static const List<Map<String, String>> staticBadges = [
    {'key': 'first_report', 'name': 'First Report'},
    {'key': 'civic_voter', 'name': 'Civic Voter'},
    {'key': 'quorum_hero', 'name': 'Verification Hero'},
    {'key': 'neighborhood_voice', 'name': 'Neighborhood Voice'},
    {'key': 'streak_master', 'name': 'Streak Master'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Civic Badges',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        GridView.count(
          key: const Key('badgesGrid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.85,
          children: staticBadges.map((bInfo) {
            final key = bInfo['key']!;
            final defaultName = bInfo['name']!;

            final userBadge = userBadges.cast<BadgeItem?>().firstWhere(
                  (b) => b?.key == key,
                  orElse: () => null,
                );

            final isUnlocked = userBadge?.isUnlocked ?? false;
            final unlockedAt = userBadge?.unlockedAt;

            return Card(
              key: Key('badgeCard_$key'),
              color: isUnlocked
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUnlocked ? Icons.stars : Icons.lock,
                      size: 32,
                      color: isUnlocked
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.outline,
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      userBadge?.name ?? defaultName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isUnlocked && unlockedAt != null) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        unlockedAt.toIso8601String().substring(0, 10),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ActivityBreakdownCard extends StatelessWidget {
  const _ActivityBreakdownCard({required this.counts});

  final ActivityCounts counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: const Key('activityBreakdownCard'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            _ActivityMetricRow(
              label: 'Issues Created: ${counts.issuesCreated}',
              ptsLabel: '+${counts.issuesCreated * 50} pts',
              icon: Icons.report_problem_outlined,
              color: colorScheme.primary,
            ),
            const Divider(height: 16.0),
            _ActivityMetricRow(
              label: 'Upvotes Cast: ${counts.upvotesCast}',
              ptsLabel: '+${counts.upvotesCast * 5} pts',
              icon: Icons.thumb_up_outlined,
              color: colorScheme.secondary,
            ),
            const Divider(height: 16.0),
            _ActivityMetricRow(
              label: 'Verification Votes: ${counts.quorumVotesCast}',
              ptsLabel: '+${counts.quorumVotesCast * 20} pts',
              icon: Icons.how_to_vote_outlined,
              color: AppColors.seed,
            ),
            const Divider(height: 16.0),
            _ActivityMetricRow(
              label: 'Comments Posted: ${counts.commentsPosted}',
              ptsLabel: '+${counts.commentsPosted * 10} pts',
              icon: Icons.comment_outlined,
              color: colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityMetricRow extends StatelessWidget {
  const _ActivityMetricRow({
    required this.label,
    required this.ptsLabel,
    required this.icon,
    required this.color,
  });

  final String label;
  final String ptsLabel;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12.0),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          ptsLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
