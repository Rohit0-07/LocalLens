import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/captured_media.dart';
import 'media_library_providers.dart';
import 'widgets/media_watermark_badge.dart';

/// Route extra for the captured-media library.
class MediaLibraryScreenArgs {
  const MediaLibraryScreenArgs({this.pickMode = false});

  final bool pickMode;
}

class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key, this.pickMode = false});

  /// When true the screen acts as a multi-select picker: tapping an item
  /// toggles selection and the footer button pops with the selected list.
  final bool pickMode;

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  final Set<String> _selected = {};
  bool _selectMode = false;

  @override
  void initState() {
    super.initState();
    _selectMode = widget.pickMode;
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

  void _toggleSelectAll(List<CapturedMedia> items) {
    setState(() {
      if (_selected.length == items.length) {
        _selected.clear();
      } else {
        _selected.addAll(items.map((m) => m.id));
      }
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      _selected.clear();
    });
  }

  Future<void> _confirmDelete() async {
    if (_selected.isEmpty) return;
    final items = ref.read(capturedMediaListProvider);
    final toDelete = items.where((m) => _selected.contains(m.id)).toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete captured photos?'),
        content: Text(
          'This will permanently remove ${toDelete.length} captured '
          'photo${toDelete.length == 1 ? '' : 's'} from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteMediaButton'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final blocked = await ref
        .read(capturedMediaListProvider.notifier)
        .deleteWithServer(toDelete);
    if (!mounted) return;
    setState(() {
      _selected.clear();
      if (!widget.pickMode) _selectMode = false;
    });
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$blocked — kept in your library')),
      );
    }
  }

  void _addSelected() {
    if (_selected.isEmpty) return;
    final items = ref.read(capturedMediaListProvider);
    final picked = items.where((m) => _selected.contains(m.id)).toList();
    Navigator.pop(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(capturedMediaListProvider);
    return Scaffold(
      key: const Key('mediaLibraryScreen'),
      appBar: AppBar(
        title: Text(_selectMode ? 'Select photos' : 'Captured media'),
        actions: _buildAppBarActions(items),
      ),
      body: items.isEmpty
          ? const _MediaLibraryEmptyState()
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final media = items[index];
                      return _MediaTile(
                        media: media,
                        selectMode: _selectMode,
                        selected: _selected.contains(media.id),
                        onTap: () {
                          if (_selectMode) {
                            _toggleSelect(media.id);
                          } else if (widget.pickMode) {
                            _toggleSelect(media.id);
                          }
                        },
                        onDelete: () => _confirmSingleDelete(media),
                        onToggleSelect: () => _toggleSelect(media.id),
                      );
                    },
                  ),
                ),
                if (widget.pickMode)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('addSelectedMediaButton'),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            _selected.isEmpty
                                ? 'Add to report'
                                : 'Add ${_selected.length} photo${_selected.length == 1 ? '' : 's'}',
                          ),
                          onPressed: _selected.isEmpty ? null : _addSelected,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _confirmSingleDelete(CapturedMedia media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete captured photo?'),
        content: const Text(
          'This will permanently remove this photo from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteMediaButton'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final blocked = await ref
        .read(capturedMediaListProvider.notifier)
        .deleteWithServer([media]);
    if (!mounted) return;
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$blocked — kept in your library')),
      );
    }
  }

  List<Widget> _buildAppBarActions(List<CapturedMedia> items) {
    if (_selectMode) {
      return [
        IconButton(
          key: const Key('mediaSelectAllButton'),
          tooltip: 'Select all',
          icon: Icon(
            items.isNotEmpty && _selected.length == items.length
                ? Icons.check_box
                : Icons.check_box_outline_blank,
          ),
          onPressed: () => _toggleSelectAll(items),
        ),
        IconButton(
          key: const Key('mediaDeleteSelectedButton'),
          tooltip: 'Delete selected',
          icon: Icon(
            Icons.delete_sweep_outlined,
            color: _selected.isEmpty
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.error,
          ),
          onPressed: _selected.isEmpty ? null : _confirmDelete,
        ),
        if (!widget.pickMode)
          IconButton(
            key: const Key('mediaSelectModeDoneButton'),
            tooltip: 'Done',
            icon: const Icon(Icons.done),
            onPressed: _toggleSelectMode,
          ),
      ];
    }
    return [
      IconButton(
        key: const Key('mediaSelectModeButton'),
        tooltip: 'Select',
        icon: const Icon(Icons.checklist_rounded),
        onPressed: _toggleSelectMode,
      ),
    ];
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.media,
    required this.selectMode,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.onToggleSelect,
  });

  final CapturedMedia media;
  final bool selectMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Uint8List? bytes;
    try {
      final decoded = base64Decode(media.bytesBase64);
      if (decoded.isNotEmpty) bytes = decoded;
    } catch (_) {}

    return GestureDetector(
      key: Key('mediaItem_${media.id}'),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null && bytes.isNotEmpty)
              Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => const Center(
                  child: Icon(Icons.image, size: 32, color: Colors.grey),
                ),
              )
            else
              const Center(
                child: Icon(Icons.image, size: 32, color: Colors.grey),
              ),
            if (selectMode)
              Positioned(
                top: 4,
                left: 4,
                child: Checkbox(
                  key: Key('mediaCheckbox_${media.id}'),
                  value: selected,
                  onChanged: (_) => onToggleSelect(),
                ),
              ),
            if (!selectMode)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  key: Key('mediaDelete_${media.id}'),
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                  ),
                  onPressed: onDelete,
                ),
              ),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Row(
                children: [
                  Flexible(
                    child: MediaWatermarkBadge(
                      isVerified: media.isVerified,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    media.hasGps ? Icons.gps_fixed : Icons.gps_off,
                    size: 14,
                    color: media.hasGps ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaLibraryEmptyState extends StatelessWidget {
  const _MediaLibraryEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const Key('mediaLibraryEmptyState'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No captured photos yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Photos you take with the in-app camera are saved here.',
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