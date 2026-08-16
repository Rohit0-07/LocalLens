import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../geo/presentation/providers/geo_providers.dart';
import '../../geo/presentation/widgets/ward_location_chip.dart';
import 'compose_providers.dart';
import '../domain/near_duplicate_candidate.dart';
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

  Future<void> _openCameraModal() async {
    final availableSlots = 4 - _attachedMediaList.length;
    if (availableSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 images allowed.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentPosition();

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    final draft = ref.read(composeControllerProvider);
    double? initialLat = position?.latitude ?? draft.latitude;
    double? initialLng = position?.longitude ?? draft.longitude;
    bool isGpsLocked = position != null;

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
            locationService: ref.read(locationServiceProvider),
            initialLat: initialLat,
            initialLng: initialLng,
            isGpsLocked: isGpsLocked,
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
          limit: 4 - _attachedMediaList.length,
        );
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

  Future<void> _useMyLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentPosition();
    final draft = ref.read(composeControllerProvider);
    await ref.read(composeControllerProvider.notifier).update(
          draft.copyWith(
            latitude: position?.latitude,
            longitude: position?.longitude,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          position != null
              ? context.tr('compose_location_locked')
              : context.tr('compose_location_unavailable'),
        ),
      ),
    );
  }

  Future<void> _checkNearDuplicates() async {
    final current = ref.read(composeControllerProvider);
    if (current.latitude == null || current.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('compose_no_location'))),
      );
      return;
    }
    final repo = ref.read(feedRepositoryProvider);
    try {
      final dups = await repo.checkNearDuplicates(
        latitude: current.latitude!,
        longitude: current.longitude!,
      );
      if (context.mounted) await _showNearDuplicates(dups);
    } catch (_) {}
  }

  Future<bool> _showNearDuplicates(
    List<NearDuplicateCandidate> dups,
  ) async {
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dups.isEmpty
                    ? context.tr('near_dup_none_title')
                    : context.tr('near_dup_guard_title'),
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                dups.isEmpty
                    ? context.tr('near_dup_none_body')
                    : context
                        .tr('near_dup_found_body')
                        .replaceFirst('{count}', '${dups.length}'),
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (dups.isNotEmpty)
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: dups.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, index) {
                      final d = dups[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.review,
                        ),
                        title: Text(
                          d.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${d.distanceMeters.toStringAsFixed(0)}m away • #${d.category}',
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.tr('near_dup_continue')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return proceed ?? false;
  }

  Future<void> _publish() async {
    final current = ref.read(composeControllerProvider);
    if (current.latitude != null && current.longitude != null) {
      final repo = ref.read(feedRepositoryProvider);
      try {
        final dups = await repo.checkNearDuplicates(
          latitude: current.latitude!,
          longitude: current.longitude!,
        );
        if (dups.isNotEmpty && context.mounted) {
          final proceed = await _showNearDuplicates(dups);
          if (!proceed || !context.mounted) return;
        }
      } catch (_) {}
    }

    final success = await ref
        .read(composeControllerProvider.notifier)
        .submit(
          mediaBytes: _attachedMediaList.map((m) => m.bytes).toList(),
          isInAppCamera:
              _attachedMediaList.any((m) => m.id.startsWith('cam_')),
        );
    if (!mounted) return;
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
                  _CategoryChoiceChip(
                    category: category,
                    selected: draft.category == category,
                    onSelected: (value) => ref
                        .read(composeControllerProvider.notifier)
                        .update(
                          draft.copyWith(category: value ? category : ''),
                        ),
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
                          separatorBuilder: (ctx, idx) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final media = _attachedMediaList[index];
                            return Container(
                              width: 140,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: media.bytes.length < 500
                                        ? Container(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surfaceContainerHigh,
                                            child: const Center(
                                              child: Icon(
                                                Icons.image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : Image.memory(
                                            media.bytes,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, st) =>
                                                Container(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHigh,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.image,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
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
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          draft.latitude != null
                              ? Icons.my_location_rounded
                              : Icons.location_off_outlined,
                          size: 20,
                          color: draft.latitude != null
                              ? AppColors.brand
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('compose_location_header'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                draft.latitude != null
                                    ? context.tr('compose_location_set')
                                    : context.tr('compose_no_location'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (draft.latitude == null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('useMyLocationButton'),
                          icon: const Icon(Icons.gps_fixed_rounded),
                          label: Text(context.tr('compose_use_my_location')),
                          onPressed: _useMyLocation,
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
              label: Text(context.tr('near_dup_check')),
              onPressed: _checkNearDuplicates,
            ),
            const SizedBox(height: 24),
            _GradientPublishButton(
              enabled: draft.title.length >= 5,
              onPressed: _publish,
              label: context.tr('compose_publish'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category choice chip carrying the category's solid identity dot.
class _CategoryChoiceChip extends StatelessWidget {
  const _CategoryChoiceChip({
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final String category;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = AppColors.categoryColorFor(category);
    return ChoiceChip(
      avatar: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
      label: Text(category),
      selected: selected,
      selectedColor: AppColors.brand.withValues(alpha: 0.14),
      side: BorderSide(
        color: selected ? AppColors.brand : colorScheme.outlineVariant,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.brand : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
      showCheckmark: false,
      onSelected: onSelected,
    );
  }
}

/// Full-width signature CTA: solid brand fill when enabled, neutral
/// grey when disabled.
class _GradientPublishButton extends StatelessWidget {
  const _GradientPublishButton({
    required this.enabled,
    required this.onPressed,
    required this.label,
  });

  final bool enabled;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.brand
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            key: const Key('compose_submit'),
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: enabled
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
