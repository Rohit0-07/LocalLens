import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../domain/compose_draft.dart';
import 'compose_providers.dart';

class DraftsScreen extends ConsumerStatefulWidget {
  const DraftsScreen({super.key});

  @override
  ConsumerState<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends ConsumerState<DraftsScreen> {
  final Set<String> _selected = {};
  bool _selectMode = false;

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      _selected.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _toggleSelectAll(List<ComposeDraft> drafts) {
    setState(() {
      if (_selected.length == drafts.length) {
        _selected.clear();
      } else {
        _selected.addAll(drafts.map((d) => d.id));
      }
    });
  }

  void _openDraft(ComposeDraft draft) {
    if (_selectMode) {
      _toggleSelect(draft.id);
      return;
    }
    context.push(RoutePaths.compose, extra: draft);
  }

  Future<void> _confirmDelete(ComposeDraft draft) async {
    final confirmed = await _showDeleteDialog(
      title: 'Delete draft?',
      message:
          'Delete "${draft.title.isEmpty ? 'Untitled report' : draft.title}"? '
          'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true) return;
    await ref.read(draftStoreProvider).deleteItem(draft.id);
    ref.invalidate(savedDraftsProvider);
    setState(() => _selected.remove(draft.id));
  }

  Future<void> _confirmBatchDelete() async {
    if (_selected.isEmpty) return;
    final confirmed = await _showDeleteDialog(
      title: 'Delete selected drafts?',
      message:
          'This will permanently delete ${_selected.length} saved '
          'draft${_selected.length == 1 ? '' : 's'}.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true) return;
    final store = ref.read(draftStoreProvider);
    for (final id in _selected.toList()) {
      await store.deleteItem(id);
    }
    ref.invalidate(savedDraftsProvider);
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
  }

  Future<bool?> _showDeleteDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteDraftsButton'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draftsAsync = ref.watch(savedDraftsProvider);
    return Scaffold(
      key: const Key('draftsScreen'),
      appBar: AppBar(
        title: Text(_selectMode ? 'Select drafts' : 'Drafts'),
        actions: _buildAppBarActions(draftsAsync.value ?? const []),
      ),
      body: draftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _DraftsEmptyState(),
        data: (drafts) =>
            drafts.isEmpty ? const _DraftsEmptyState() : _buildList(drafts),
      ),
    );
  }

  List<Widget> _buildAppBarActions(List<ComposeDraft> drafts) {
    if (_selectMode) {
      return [
        IconButton(
          key: const Key('selectAllButton'),
          tooltip: 'Select all',
          icon: Icon(
            drafts.isNotEmpty && _selected.length == drafts.length
                ? Icons.check_box
                : Icons.check_box_outline_blank,
          ),
          onPressed: () => _toggleSelectAll(drafts),
        ),
        IconButton(
          key: const Key('deleteSelectedButton'),
          tooltip: 'Delete selected',
          icon: Icon(
            Icons.delete_sweep_outlined,
            color: _selected.isEmpty
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.error,
          ),
          onPressed: _selected.isEmpty ? null : _confirmBatchDelete,
        ),
        IconButton(
          key: const Key('draftSelectModeDoneButton'),
          tooltip: 'Done',
          icon: const Icon(Icons.done),
          onPressed: _toggleSelectMode,
        ),
      ];
    }
    return [
      IconButton(
        key: const Key('draftSelectModeButton'),
        tooltip: 'Select',
        icon: const Icon(Icons.checklist_rounded),
        onPressed: _toggleSelectMode,
      ),
    ];
  }

  Widget _buildList(List<ComposeDraft> drafts) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: drafts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final draft = drafts[index];
        return _DraftCard(
          draft: draft,
          selectMode: _selectMode,
          selected: _selected.contains(draft.id),
          onTap: () => _openDraft(draft),
          onDelete: () => _confirmDelete(draft),
          onToggleSelect: () => _toggleSelect(draft.id),
        );
      },
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.selectMode,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.onToggleSelect,
  });

  final ComposeDraft draft;
  final bool selectMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final updatedAt = draft.updatedAt ?? draft.createdAt;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        key: Key('draftItem_${draft.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectMode) ...[
                Checkbox(
                  key: Key('draftCheckbox_${draft.id}'),
                  value: selected,
                  onChanged: (_) => onToggleSelect(),
                ),
                const SizedBox(width: 4),
              ],
              if (draft.hasMedia) ...[
                _DraftThumbnail(base64: draft.mediaBytes.first),
                const SizedBox(width: 12),
              ],
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
                      runSpacing: 4,
                      children: [
                        _MetaTag(text: '#${draft.category}'),
                        if (updatedAt != null)
                          _MetaTag(text: _relativeTime(updatedAt)),
                        if (draft.hasMedia)
                          _MetaTag(
                            text: draft.mediaCount == 1
                                ? '1 photo'
                                : '${draft.mediaCount} photos',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!selectMode)
                IconButton(
                  key: Key('draftDelete_${draft.id}'),
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _DraftThumbnail extends StatelessWidget {
  const _DraftThumbnail({required this.base64});

  final String base64;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Uint8List? bytes;
    try {
      final decoded = base64Decode(base64);
      if (decoded.isNotEmpty) bytes = decoded;
    } catch (_) {}

    return Container(
      key: const Key('draftThumbnail'),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant)
          : Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Icon(
                Icons.image_outlined,
                color: colorScheme.onSurfaceVariant,
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

class _DraftsEmptyState extends StatelessWidget {
  const _DraftsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const Key('draftsEmptyState'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.drafts_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No drafts yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Reports you save as drafts will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
