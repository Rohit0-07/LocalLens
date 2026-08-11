import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/notice.dart';

class NoticeCard extends StatelessWidget {
  final NoticeItem notice;

  const NoticeCard({
    super.key,
    required this.notice,
  });

  void _shareNotice(BuildContext context) {
    final deepLink = 'locallens://notice/${notice.id}';
    Clipboard.setData(ClipboardData(text: deepLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notice link copied: $deepLink'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatValidUntil(DateTime? validUntil) {
    if (validUntil == null) return 'Ongoing';
    return '${validUntil.day}/${validUntil.month}/${validUntil.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: Key('noticeCard_${notice.id}'),
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade200, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        notice.officialHeader.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 12, color: Colors.blue.shade900),
                      const SizedBox(width: 4),
                      Text(
                        'Valid: ${_formatValidUntil(notice.validUntil)}',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  tooltip: 'Share',
                  onPressed: () => _shareNotice(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              notice.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              notice.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  notice.ward,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
