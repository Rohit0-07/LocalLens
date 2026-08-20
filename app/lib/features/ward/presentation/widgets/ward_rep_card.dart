import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../rep_dashboard/presentation/rep_dashboard_providers.dart';
import '../../domain/ward_representative_out.dart';

class WardRepCard extends ConsumerWidget {
  const WardRepCard({
    super.key,
    required this.representative,
    this.onTap,
  });

  final WardRepresentativeOut representative;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repProfileAsync = ref.watch(publicRepProfileProvider(representative.userId));
    final repProfile = repProfileAsync.valueOrNull;
    final showMetrics = representative.userId > 0 && repProfile != null;
    final isTappable = onTap != null || representative.userId > 0;

    return Card(
      key: const Key('wardRepCard'),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
            return;
          }
          if (representative.userId > 0) {
            context.push(RoutePaths.publicProfileFor(representative.userId));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 28,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                representative.officialName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              representative.isUnclaimed
                                  ? Icons.hourglass_top_rounded
                                  : Icons.verified_rounded,
                              size: 16,
                              color: representative.isUnclaimed
                                  ? Colors.amber.shade800
                                  : AppColors.resolved,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          representative.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                representative.department.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            if (representative.handle != null &&
                                representative.handle!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '@${representative.handle}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            Text(
                              representative.isUnclaimed
                                  ? '• Unclaimed'
                                  : '• Verified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: representative.isUnclaimed
                                    ? Colors.amber.shade800
                                    : AppColors.resolved,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isTappable)
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              if (showMetrics) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RepMetric(
                        key: const Key('wardRepResolvedMetric'),
                        label: 'Resolved',
                        value: '${repProfile.resolvedWardIssues}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.resolved,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RepMetric(
                        key: const Key('wardRepPendingMetric'),
                        label: 'Pending',
                        value: '${repProfile.pendingResponseWardIssues}',
                        icon: Icons.pending_actions,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RepMetric(
                        key: const Key('wardRepResponseRateMetric'),
                        label: 'Response Rate',
                        value: '${repProfile.responseRatePct.toStringAsFixed(1)}%',
                        icon: Icons.speed_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RepMetric extends StatelessWidget {
  const _RepMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}