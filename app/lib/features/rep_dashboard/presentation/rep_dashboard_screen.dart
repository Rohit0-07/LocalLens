import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_list.dart';
import '../../../../shared/widgets/status_badge.dart';
import 'rep_dashboard_providers.dart';
import 'widgets/post_official_response_dialog.dart';

class RepDashboardScreen extends ConsumerWidget {
  const RepDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asyncProfile = ref.watch(repProfileProvider);
    final activeFilter = ref.watch(wardIssuesFilterProvider);
    final asyncWardIssues = ref.watch(wardIssuesProvider(activeFilter));

    return Scaffold(
      key: const Key('repDashboardScreen'),
      appBar: AppBar(
        title: Text(context.tr('rep_dashboard_title')),
      ),
      body: asyncProfile.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonList(),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            icon: Icons.lock_outline,
            title: 'Access Denied',
            message: err.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(repProfileProvider),
          ),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(repProfileProvider);
            ref.invalidate(wardIssuesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Rep Profile Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.officialName,
                                    key: const Key('repProfileName'),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    profile.title,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              key: const Key('repProfileWard'),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                profile.ward,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        key: const Key('metricTotalWardIssues'),
                        label: 'Total Ward Issues',
                        value: '${profile.totalWardIssues}',
                        icon: Icons.list_alt,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        key: const Key('metricEscalatedWardIssues'),
                        label: 'Escalated',
                        value: '${profile.escalatedWardIssues}',
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        key: const Key('metricPendingResponseWardIssues'),
                        label: 'Pending Response',
                        value: '${profile.pendingResponseWardIssues}',
                        icon: Icons.pending_actions,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        key: const Key('wardFilterChip_all'),
                        label: Text(context.tr('rep_filter_all')),
                        selected: activeFilter == 'all',
                        onSelected: (_) => ref.read(wardIssuesFilterProvider.notifier).state = 'all',
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        key: const Key('wardFilterChip_escalated'),
                        label: Text(context.tr('rep_filter_escalated')),
                        selected: activeFilter == 'escalated',
                        onSelected: (_) => ref.read(wardIssuesFilterProvider.notifier).state = 'escalated',
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        key: const Key('wardFilterChip_needs_response'),
                        label: Text(context.tr('rep_filter_needs_response')),
                        selected: activeFilter == 'needs_response',
                        onSelected: (_) => ref.read(wardIssuesFilterProvider.notifier).state = 'needs_response',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ward Issues List
                asyncWardIssues.when(
                  loading: () => const SizedBox(height: 300, child: SkeletonList(itemCount: 3)),
                  error: (err, stack) => EmptyState(
                    icon: Icons.error_outline,
                    title: 'Failed to load ward issues',
                    message: err.toString(),
                  ),
                  data: (wardIssuesResponse) {
                    if (wardIssuesResponse.items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No ward issues found',
                        message: 'No issues match the selected filter.',
                      );
                    }
                    return ListView.separated(
                      key: const Key('wardIssueList'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: wardIssuesResponse.items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final issue = wardIssuesResponse.items[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        issue.title,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(status: issue.status),
                                  ],
                                ),
                                if (issue.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    issue.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${issue.category} • ${issue.ward}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    FilledButton.icon(
                                      key: Key('respondToIssueButton_${issue.id}'),
                                      icon: const Icon(Icons.reply, size: 16),
                                      label: Text(context.tr('rep_official_response')),
                                      onPressed: () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (_) => PostOfficialResponseDialog(issueId: issue.id),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
