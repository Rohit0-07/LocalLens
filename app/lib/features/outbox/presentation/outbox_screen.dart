import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../compose/domain/compose_draft.dart';
import '../../compose/presentation/compose_providers.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../map/presentation/controllers/map_controller.dart';

class OutboxScreen extends ConsumerStatefulWidget {
  const OutboxScreen({super.key});

  @override
  ConsumerState<OutboxScreen> createState() => _OutboxScreenState();
}

class _OutboxScreenState extends ConsumerState<OutboxScreen> {
  bool _syncing = false;
  bool _syncedAnything = false;

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _syncedAnything = false;
    });
    try {
      final outbox = ref.read(offlineOutboxProvider);
      final synced = await outbox.flush();
      if (!mounted) return;
      setState(() => _syncedAnything = synced > 0);
      if (synced > 0) ref.invalidate(multiTypeFeedProvider);
      if (synced > 0) ref.invalidate(mapPinsNotifierProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('outbox_failed_partial'))),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _deleteItem(int index) async {
    await ref.read(offlineOutboxProvider).removeAt(index);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = ref.watch(offlineOutboxProvider).getPendingQueue();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('outbox_title')),
        actions: [
          IconButton(
            key: const Key('outboxRefreshButton'),
            tooltip: context.tr('outbox_sync_now'),
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: _syncing ? null : _syncNow,
          ),
        ],
      ),
      body: _syncing
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? _EmptyOutbox(synced: _syncedAnything)
              : RefreshIndicator(
                  onRefresh: _syncNow,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            context.tr('outbox_pending'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      final draft = items[index];
                      return _OutboxItemCard(
                        draft: draft,
                        onDelete: () => _deleteItem(index),
                      );
                    },
                  ),
                ),
    );
  }
}

class _OutboxItemCard extends StatelessWidget {
  const _OutboxItemCard({
    required this.draft,
    required this.onDelete,
  });

  final ComposeDraft draft;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.cloud_queue_outlined, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.title.isEmpty ? 'Untitled report' : draft.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    draft.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      _MetaTag(text: '#${draft.category}'),
                      if (draft.isAnonymous) _MetaTag(text: 'anon'),
                      if (draft.isShielded) _MetaTag(text: 'shielded'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              key: Key('outboxDelete_${draft.title}'),
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _EmptyOutbox extends StatelessWidget {
  const _EmptyOutbox({required this.synced});

  final bool synced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            synced
                ? context.tr('outbox_synced_all')
                : context.tr('outbox_empty'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('outbox_title'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}