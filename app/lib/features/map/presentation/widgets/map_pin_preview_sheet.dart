import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../data/map_api.dart';

class MapPinPreviewSheet extends StatelessWidget {
  final MapPin pin;
  final VoidCallback? onClose;

  const MapPinPreviewSheet({
    super.key,
    required this.pin,
    this.onClose,
  });

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return Colors.amber.shade700;
      case 'sanitation':
        return Colors.green.shade700;
      case 'water':
        return Colors.blue.shade700;
      case 'lighting':
        return Colors.orange.shade700;
      default:
        return Colors.purple.shade700;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'unacknowledged':
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'unacknowledged':
        return 'Unacknowledged';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _categoryColor(pin.category).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pin.category.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _categoryColor(pin.category),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(pin.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatStatus(pin.status),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _statusColor(pin.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (pin.isShielded) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Location Shielded',
                  child: Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: Colors.indigo.shade600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pin.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  pin.wardName.isNotEmpty ? pin.wardName : 'Unknown Ward',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Icon(Icons.thumb_up_alt_outlined,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${pin.upvotesCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push(RoutePaths.issueDetailFor(pin.id));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View Issue Details'),
            ),
          ),
        ],
      ),
    );
  }
}
