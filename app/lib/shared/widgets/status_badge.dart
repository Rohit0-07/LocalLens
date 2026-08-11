import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  static const _colors = <String, Color>{
    'open': Color(0xFFC62828),
    'escalating': Color(0xFFC62828),
    'review': Color(0xFFEF6C00),
    'pending_verification': Color(0xFFEF6C00),
    'resolved': Color(0xFF2E7D32),
    'disputed': Color(0xFF6A1B9A),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Theme.of(context).colorScheme.outline;
    final label = status.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.tr('status_$status') == 'status_$status'
            ? label
            : context.tr('status_$status').toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
