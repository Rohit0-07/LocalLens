import 'package:flutter/material.dart';
import '../../domain/ward_detail_out.dart';

class WardMetricCard extends StatelessWidget {
  const WardMetricCard({
    required super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WardMetricsGrid extends StatelessWidget {
  const WardMetricsGrid({super.key, required this.wardDetail});

  final WardDetailOut wardDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: WardMetricCard(
                key: const Key('wardMetricTotal'),
                title: 'Total Issues',
                value: '${wardDetail.totalIssues}',
                icon: Icons.bar_chart_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: WardMetricCard(
                key: const Key('wardMetricActive'),
                title: 'Active',
                value: '${wardDetail.activeIssues}',
                icon: Icons.pending_actions_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: WardMetricCard(
                key: const Key('wardMetricEscalated'),
                title: 'Escalated',
                value: '${wardDetail.escalatedIssues}',
                icon: Icons.priority_high_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: WardMetricCard(
                key: const Key('wardMetricResolved'),
                title: 'Resolved',
                value: '${wardDetail.resolvedIssues}',
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        WardMetricCard(
          key: const Key('wardMetricResolutionRate'),
          title: 'Resolution Rate',
          value: '${wardDetail.resolutionRatePct}%',
          icon: Icons.trending_up_rounded,
        ),
      ],
    );
  }
}
