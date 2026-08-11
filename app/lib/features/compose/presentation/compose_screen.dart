import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../geo/presentation/providers/geo_providers.dart';
import '../../geo/presentation/widgets/ward_location_chip.dart';
import 'compose_providers.dart';
import 'widgets/camera_viewfinder.dart';
import 'widgets/media_watermark_badge.dart';

const _categories = [
  'road',
  'water',
  'power',
  'lighting',
  'waste',
  'sewage',
  'other',
];

class _AttachedMedia {
  final String id;
  final Uint8List bytes;
  final bool isVerified;

  _AttachedMedia({
    required this.id,
    required this.bytes,
    required this.isVerified,
  });
}

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final List<_AttachedMedia> _attachedMediaList = [];

  void _openCameraModal() {
    final availableSlots = 4 - _attachedMediaList.length;
    if (availableSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 images allowed.')),
      );
      return;
    }

    final draft = ref.read(composeControllerProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          height: MediaQuery.of(modalCtx).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: CameraViewfinder(
            initialLat: draft.latitude,
            initialLng: draft.longitude,
            isGpsLocked: true,
            onPhotoCaptured: (bytes, lat, lng) {
              if (_attachedMediaList.length < 4) {
                setState(() {
                  _attachedMediaList.add(
                    _AttachedMedia(
                      id: 'cam_${DateTime.now().microsecondsSinceEpoch}',
                      bytes: bytes,
                      isVerified: true,
                    ),
                  );
                });
              }
              Navigator.pop(modalCtx);
            },
            onGalleryPickSelected: (images) {
              _addGalleryImages(images);
              Navigator.pop(modalCtx);
            },
          ),
        );
      },
    );
  }

  Future<void> _addGalleryImages([List<Uint8List>? images]) async {
    List<Uint8List> actualImages = images ?? [];

    if (actualImages.isEmpty) {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickMultiImage(
            limit: 4 - _attachedMediaList.length);
        for (final file in picked) {
          actualImages.add(await file.readAsBytes());
        }
      } catch (_) {}
    }

    final availableSlots = 4 - _attachedMediaList.length;
    if (availableSlots <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 4 images allowed.')),
        );
      }
      return;
    }

    if (actualImages.isEmpty) return;

    setState(() {
      for (final bytes in actualImages.take(availableSlots)) {
        _attachedMediaList.add(
          _AttachedMedia(
            id: 'gallery_${DateTime.now().microsecondsSinceEpoch}_${_attachedMediaList.length}',
            bytes: bytes,
            isVerified: false,
          ),
        );
      }
    });
  }

  void _removeMedia(String id) {
    setState(() {
      _attachedMediaList.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(composeControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('compose_title')),
        actions: [
          Padding(
            key: const Key('composeLocationChip'),
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: WardLocationChip(state: ref.watch(wardLocationProvider)),
            ),
          ),
          if (draft.hasContent)
            IconButton(
              tooltip: context.tr('compose_discard'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref.read(composeControllerProvider.notifier).submit();
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: const Key('compose_title'),
              maxLength: 100,
              decoration: InputDecoration(
                labelText: context.tr('compose_whats_wrong'),
                hintText: 'Deep pothole near the bus stop',
              ),
              onChanged: (value) => ref
                  .read(composeControllerProvider.notifier)
                  .update(draft.copyWith(title: value)),
            ),
            TextField(
              key: const Key('compose_description'),
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: context.tr('compose_details'),
                hintText: 'How big, how long, what happens...',
              ),
              onChanged: (value) => ref
                  .read(composeControllerProvider.notifier)
                  .update(draft.copyWith(description: value)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in _categories)
                  ChoiceChip(
                    label: Text(category),
                    selected: draft.category == category,
                    onSelected: (_) => ref
                        .read(composeControllerProvider.notifier)
                        .update(draft.copyWith(category: category)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('compose_media'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('openCameraButton'),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(context.tr('compose_take_photo')),
                          onPressed: _openCameraModal,
                        ),
                        OutlinedButton.icon(
                          key: const Key('openGalleryButton'),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(context.tr('compose_add_gallery')),
                          onPressed: () => _addGalleryImages(),
                        ),
                      ],
                    ),
                    if (_attachedMediaList.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedMediaList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final media = _attachedMediaList[index];
                            return Container(
                              width: 140,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: media.bytes.length < 500
                                        ? Container(
                                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                            child: const Center(
                                              child: Icon(Icons.image, size: 40, color: Colors.grey),
                                            ),
                                          )
                                        : Image.memory(
                                            media.bytes,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                              child: const Center(
                                                child: Icon(Icons.image, size: 40, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    left: 4,
                                    right: 4,
                                    child: MediaWatermarkBadge(
                                      isVerified: media.isVerified,
                                      isCompact: true,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        key: Key('removeMedia_${media.id}'),
                                        padding: EdgeInsets.zero,
                                        iconSize: 16,
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        onPressed: () => _removeMedia(media.id),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              key: const Key('compose_fuzz_mode'),
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('compose_fuzz')),
              subtitle: Text(context.tr('compose_fuzz_sub')),
              value: draft.isFuzzed,
              onChanged: (value) => ref
                  .read(composeControllerProvider.notifier)
                  .update(draft.copyWith(isFuzzed: value)),
            ),
            SwitchListTile(
              key: const Key('compose_shield_mode'),
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('compose_shield')),
              subtitle: Text(context.tr('compose_shield_sub')),
              value: draft.isShielded,
              onChanged: (value) => ref
                  .read(composeControllerProvider.notifier)
                  .update(draft.copyWith(isShielded: value)),
            ),
            SwitchListTile(
              key: const Key('compose_anonymous'),
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('compose_anonymous')),
              subtitle: const Text('Zero-retention identity derivation'),
              value: draft.isAnonymous,
              onChanged: (value) => ref
                  .read(composeControllerProvider.notifier)
                  .update(draft.copyWith(isAnonymous: value)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('check_near_duplicates_button'),
              icon: const Icon(Icons.find_in_page_outlined),
              label: const Text('Check for Near-Duplicates'),
              onPressed: () async {
                final lat = draft.latitude ?? defaultLatitude;
                final lng = draft.longitude ?? defaultLongitude;
                final repo = ref.read(feedRepositoryProvider);
                try {
                  final dups = await repo.checkNearDuplicates(
                    latitude: lat,
                    longitude: lng,
                  );
                  if (!context.mounted) return;
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dups.isEmpty
                                ? 'No Near-Duplicates Found'
                                : 'Near-Duplicate Guard',
                            style: Theme.of(ctx).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dups.isEmpty
                                ? 'No similar issues reported within 500m.'
                                : 'Found ${dups.length} similar issue(s) reported nearby. Please check to avoid duplicate flooding:',
                            style: Theme.of(ctx).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          for (final d in dups)
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                              title: Text(d.title),
                              subtitle: Text(
                                '${d.distanceMeters.toStringAsFixed(0)}m away • #${d.category}',
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Continue Reporting'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } catch (_) {}
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('compose_submit'),
                onPressed: draft.title.length < 5
                    ? null
                    : () async {
                        final success = await ref
                            .read(composeControllerProvider.notifier)
                            .submit();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? context.tr('compose_published')
                                  : context.tr('compose_outbox_msg'),
                            ),
                          ),
                        );
                        context.go(RoutePaths.feed);
                        ref.invalidate(multiTypeFeedProvider);
                      },
                child: Text(context.tr('compose_publish')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
