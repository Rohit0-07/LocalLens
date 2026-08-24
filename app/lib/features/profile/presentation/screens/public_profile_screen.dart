import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/utils/string_formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../feed/domain/issue.dart';
import '../../../rep_dashboard/presentation/rep_dashboard_providers.dart';
import '../profile_providers.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final int userId;

  static const _categoryIcons = <String, IconData>{
    'road': Icons.alt_route_rounded,
    'water': Icons.water_drop_outlined,
    'power': Icons.bolt_rounded,
    'lighting': Icons.lightbulb_outline_rounded,
    'waste': Icons.delete_outline_rounded,
    'sanitation': Icons.recycling_rounded,
    'sewage': Icons.water_rounded,
    'other': Icons.flag_outlined,
  };

  static const _badgeIcons = <String, IconData>{
    'flag': Icons.flag_rounded,
    'shield': Icons.shield_rounded,
    'check_circle': Icons.check_circle_rounded,
    'star': Icons.star_rounded,
    'trophy': Icons.emoji_events_rounded,
    'bolt': Icons.bolt_rounded,
    'lock': Icons.lock_outline_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final profileAsync = ref.watch(publicProfileProvider(userId));
    final issuesAsync = ref.watch(publicUserIssuesProvider(userId));
    final repProfileAsync = ref.watch(publicRepProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile_title')),
        centerTitle: false,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load public profile',
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () {
                  ref.invalidate(publicProfileProvider(userId));
                  ref.invalidate(publicUserIssuesProvider(userId));
                },
                child: Text(context.tr('action_retry')),
              ),
            ],
          ),
        ),
        data: (profile) {
          final memberDateFormatted =
              '${_monthName(profile.memberSince.month)} ${profile.memberSince.year}';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(publicProfileProvider(userId));
              ref.invalidate(publicUserIssuesProvider(userId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Header & Avatar ──────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor:
                                AppColors.anonMask.withValues(alpha: 0.14),
                            child: Icon(
                              _getRoleIcon(profile.role),
                              size: 38,
                              color: AppColors.anonMask,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                profile.displayName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: AppColors.verified,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _RoleBadge(role: profile.role),
                            Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: const Icon(Icons.fingerprint, size: 14),
                              label: Text(
                                'Anon ID: ${_truncateAnonId(profile.anonId)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              backgroundColor:
                                  colorScheme.surfaceContainerHigh,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    profile.ward,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '•',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Member since $memberDateFormatted',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Impact & Reputation Stats Card ───────────────────
                  Card(
                    key: const Key('publicImpactStatsCard'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Impact Score',
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${profile.impactPoints} pts',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.brand.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppColors.brand.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium,
                                      size: 16,
                                      color: AppColors.brand,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      profile.level,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brand,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _MetricItem(
                                label: 'Issues Reported',
                                value: '${profile.issuesReported}',
                                icon: Icons.report_problem_outlined,
                              ),
                              _buildVerticalDivider(colorScheme),
                              _MetricItem(
                                label: 'Verified Solves',
                                value: '${profile.verifiedResolutions}',
                                icon: Icons.verified_outlined,
                              ),
                              _buildVerticalDivider(colorScheme),
                              _MetricItem(
                                label: 'Upvotes Recv.',
                                value: '${profile.upvotesReceived}',
                                icon: Icons.thumb_up_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Representative Performance ────────────────────
                  repProfileAsync.when(
                    data: (repProfile) {
                      if (repProfile == null) {
                        return const SizedBox.shrink();
                      }
                      return Card(
                        key: const Key('publicRepPerformanceCard'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Representative Performance',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _MetricItem(
                                    key: const Key('publicRepResolvedCount'),
                                    label: 'Resolved',
                                    value: '${repProfile.resolvedWardIssues}',
                                    icon: Icons.check_circle_outline,
                                  ),
                                  _buildVerticalDivider(colorScheme),
                                  _MetricItem(
                                    key: const Key('publicRepPendingCount'),
                                    label: 'Pending',
                                    value:
                                        '${repProfile.pendingResponseWardIssues}',
                                    icon: Icons.pending_actions,
                                  ),
                                  _buildVerticalDivider(colorScheme),
                                  _MetricItem(
                                    key: const Key('publicRepInProgressCount'),
                                    label: 'In Progress',
                                    value:
                                        '${repProfile.inProgressWardIssues}',
                                    icon: Icons.build_circle_outlined,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _MetricItem(
                                    key: const Key(
                                        'publicRepAcknowledgedCount'),
                                    label: 'Acknowledged',
                                    value:
                                        '${repProfile.acknowledgedWardIssues}',
                                    icon: Icons.thumb_up_outlined,
                                  ),
                                  _buildVerticalDivider(colorScheme),
                                  _MetricItem(
                                    key: const Key('publicRepResponseRate'),
                                    label: 'Response Rate',
                                    value:
                                        '${repProfile.responseRatePct.toStringAsFixed(1)}%',
                                    icon: Icons.speed_rounded,
                                  ),
                                  _buildVerticalDivider(colorScheme),
                                  _MetricItem(
                                    key: const Key('publicRepAvgResponseTime'),
                                    label: 'Avg Response',
                                    value:
                                        '${repProfile.avgResponseTimeHours.toStringAsFixed(1)}h',
                                    icon: Icons.timer_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // ── Unlocked Civic Badges ─────────────────────────────
                  Text(
                    'Unlocked Civic Badges (${profile.badges.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (profile.badges.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No civic badges unlocked yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: profile.badges.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final badge = profile.badges[index];
                          final badgeIcon =
                              _badgeIcons[badge.iconName.toLowerCase()] ??
                                  Icons.star_rounded;

                          return Container(
                            width: 120,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4)
                                  : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      AppColors.brand.withValues(alpha: 0.15),
                                  child: Icon(
                                    badgeIcon,
                                    size: 18,
                                    color: AppColors.brand,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  badge.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  StringFormatters.humanize(badge.category).toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Public Issues Reported by User ────────────────────
                  Text(
                    'Public Reported Issues',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  issuesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Could not load reported issues.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                    data: (issues) {
                      if (issues.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 36,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No public issues reported by this citizen yet.',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: issues.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final issue = issues[index];
                          return _PublicIssueTile(
                            issue: issue,
                            isDark: isDark,
                            categoryIcon: _categoryIcons[
                                    issue.category.toLowerCase()] ??
                                Icons.flag_outlined,
                            onTap: () => context.push(
                              RoutePaths.issueDetailFor(issue.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'ward representative':
      case 'representative':
        return Icons.how_to_reg_rounded;
      case 'official':
      case 'administrator':
        return Icons.account_balance_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  static String _truncateAnonId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 6)}';
  }

  static String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Widget _buildVerticalDivider(ColorScheme colorScheme) {
    return Container(
      height: 32,
      width: 1,
      color: colorScheme.outlineVariant,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRep = role.toLowerCase().contains('representative');
    final isOfficial = role.toLowerCase().contains('official');

    final color = isRep
        ? AppColors.brand
        : isOfficial
            ? Colors.indigo
            : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRep
                ? Icons.how_to_reg_rounded
                : isOfficial
                    ? Icons.account_balance_rounded
                    : Icons.person_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            role,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PublicIssueTile extends StatelessWidget {
  const _PublicIssueTile({
    required this.issue,
    required this.isDark,
    required this.categoryIcon,
    required this.onTap,
  });

  final Issue issue;
  final bool isDark;
  final IconData categoryIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = AppColors.categoryColorFor(issue.category);
    final categorySurface = AppColors.categorySurfaceFor(
      issue.category,
      isDark: isDark,
    );

    return Card(
      key: Key('publicIssueItem_${issue.id}'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: categorySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon, size: 12, color: categoryColor),
                        const SizedBox(width: 4),
                        Text(
                          StringFormatters.humanize(issue.category).toUpperCase(),
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: issue.status),
                  const Spacer(),
                  Text(
                    formatRelativeTime(issue.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                issue.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${issue.upvotesCount} upvotes',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
