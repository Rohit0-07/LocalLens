import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../domain/ward_detail_out.dart';

class WardHeroBanner extends StatelessWidget {
  const WardHeroBanner({super.key, required this.wardDetail});

  final WardDetailOut wardDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      key: const Key('wardHeroBanner'),
      elevation: 0,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    wardDetail.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    wardDetail.code,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  backgroundColor: colorScheme.surface,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  '${wardDetail.centerLatitude.toStringAsFixed(4)}, '
                  '${wardDetail.centerLongitude.toStringAsFixed(4)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            if (wardDetail.topCategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in wardDetail.topCategories)
                    Chip(
                      key: Key('wardTopCategoryChip_$category'),
                      visualDensity: VisualDensity.compact,
                      label: Text(category),
                      labelStyle: theme.textTheme.labelMedium,
                      backgroundColor: colorScheme.surface,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                ],
              ),
            ],
            if (wardDetail.updatedAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated ${_formatUpdatedAt(wardDetail.updatedAt!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('wardHeroViewMapButton'),
                onPressed: () => context.go(RoutePaths.map),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('View Map'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatUpdatedAt(DateTime updatedAt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = updatedAt.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}
