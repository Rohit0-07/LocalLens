import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/string_formatters.dart';
import '../../feed/presentation/feed_providers.dart';
import '../../geo/presentation/providers/geo_providers.dart';
import '../../geo/presentation/widgets/ward_location_chip.dart';
import '../../map/presentation/controllers/map_controller.dart';
import 'compose_providers.dart';
import '../domain/captured_media.dart';
import '../domain/compose_draft.dart';
import '../domain/near_duplicate_candidate.dart';
import 'media_library_providers.dart';
import 'media_library_screen.dart';
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

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key, this.draft});

  /// A saved draft opened from the Drafts page. When present the composition
  /// is pre-filled (including the saved media bytes) so it can be edited and
  /// saved back onto the same draft id.
  final ComposeDraft? draft;

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final List<CapturedMedia> _attachedMediaList = [];

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    if (draft == null) return;
    // Defer the provider mutation until after the first build frame so we do
    // not modify a Riverpod provider while the widget tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(composeControllerProvider.notifier).loadDraft(draft);
    });
    for (final media in draft.media.take(4)) {
      if (media.bytesBase64.isEmpty) continue;
      _attachedMediaList.add(media);
    }
  }

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
                final media = CapturedMedia(
                  id: 'cam_${DateTime.now().microsecondsSinceEpoch}',
                  bytesBase64: base64Encode(bytes),
                  capturedLat: lat,
                  capturedLng: lng,
                  capturedAt: DateTime.now(),
                  isVerified: lat != null && lng != null,
                );
                unawaited(ref.read(capturedMediaStoreProvider).save(media));
                setState(() {
                  _attachedMediaList.add(media);
                });
              }
              Navigator.pop(modalCtx);
            },
          ),
        );
      },
    );
  }

  Future<void> _openLibrary() async {
    final availableSlots = 4 - _attachedMediaList.length;
    if (availableSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 images allowed.')),
      );
      return;
    }
    final picked =
        await context.push<List<CapturedMedia>>(
          RoutePaths.capturedMedia,
          extra: const MediaLibraryScreenArgs(pickMode: true),
        );
    if (picked == null || picked.isEmpty || !mounted) return;
    final existing = _attachedMediaList.map((m) => m.id).toSet();
    final fresh = picked
        .where((m) => !existing.contains(m.id))
        .take(availableSlots)
        .toList();
    if (fresh.isEmpty) return;
    setState(() {
      _attachedMediaList.addAll(fresh);
    });
  }

  void _removeMedia(String id) {
    setState(() {
      _attachedMediaList.removeWhere((item) => item.id == id);
    });
  }

  Future<void> _saveAsDraft() async {
    await ref
        .read(composeControllerProvider.notifier)
        .saveAsDraft(media: _attachedMediaList.toList());
    ref.invalidate(savedDraftsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Draft saved')));
  }

  Future<void> _useMyLocation() async {
    // Resolve through the same coordinate source the home feed queries so a
    // locked location always lands inside the feed's radius (see
    // `geo_providers.feedCoordinatesProvider`). Falls back to the reference
    // point so a GPS failure still yields a visible issue.
    double? lockedLat;
    double? lockedLng;
    try {
      final coords = await ref.read(feedCoordinatesProvider.future);
      lockedLat = coords.lat;
      lockedLng = coords.lng;
    } catch (_) {
      try {
        final locationService = ref.read(locationServiceProvider);
        final position = await locationService.getCurrentPosition();
        lockedLat = position?.latitude;
        lockedLng = position?.longitude;
      } catch (_) {}
    }

    final draft = ref.read(composeControllerProvider);
    await ref
        .read(composeControllerProvider.notifier)
        .update(draft.copyWith(latitude: lockedLat, longitude: lockedLng));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lockedLat != null && lockedLng != null
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
        category: current.category,
        radiusKm: 0.030,
      );
      if (context.mounted) await _showNearDuplicates(dups);
    } catch (_) {}
  }

  Future<bool> _showNearDuplicates(List<NearDuplicateCandidate> dups) async {
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.urgent,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('near_dup_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('near_dup_warning'),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (dups.isEmpty)
                Text(context.tr('near_dup_none'))
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: dups.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (ctx, idx) {
                      final d = dups[idx];
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: AppColors.review,
                        ),
                        title: Text(
                          d.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${d.distanceMeters.toStringAsFixed(0)}m away • ${StringFormatters.formatCategory(d.category)}',
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
          category: current.category,
          radiusKm: 0.030,
        );
        if (dups.isNotEmpty && context.mounted) {
          final proceed = await _showNearDuplicates(dups);
          if (!proceed || !context.mounted) return;
        }
      } catch (_) {}
    }

    final success = await ref
        .read(composeControllerProvider.notifier)
        .submit(media: _attachedMediaList.toList());
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
    ref.invalidate(savedDraftsProvider);
    context.go(RoutePaths.feed);
    ref.invalidate(multiTypeFeedProvider);
    ref.invalidate(mapPinsNotifierProvider);
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
          IconButton(
            key: const Key('draftsButton'),
            tooltip: 'Drafts',
            icon: const Icon(Icons.drafts_outlined),
            onPressed: () => context.push(RoutePaths.drafts),
          ),
          IconButton(
            key: const Key('saveAsDraftButton'),
            tooltip: 'Save as draft',
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveAsDraft,
          ),
          if (draft.hasContent)
            IconButton(
              tooltip: context.tr('compose_discard'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref.read(composeControllerProvider.notifier).discard();
                ref.invalidate(savedDraftsProvider);
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('compose_media'),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '${_attachedMediaList.length}/4',
                          key: const Key('mediaCountLabel'),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          key: const Key('openCameraButton'),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(context.tr('compose_take_photo')),
                          onPressed: _openCameraModal,
                        ),
                        OutlinedButton.icon(
                          key: const Key('capturedLibraryButton'),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('My captured photos'),
                          onPressed: _openLibrary,
                        ),
                      ],
                    ),
                    if (_attachedMediaList.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Captured photos',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                    child: _MediaThumbnail(
                                      bytesBase64: media.bytesBase64,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
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
                                          media.hasGps
                                              ? Icons.gps_fixed
                                              : Icons.gps_off,
                                          size: 14,
                                          color: media.hasGps
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        key: Key(
                                          'removeMedia_${media.id}',
                                        ),
                                        padding: EdgeInsets.zero,
                                        iconSize: 16,
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                        onPressed: () =>
                                            _removeMedia(media.id),
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
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              _LocationSubtitle(
                                draft: draft,
                                attachedMedia: _attachedMediaList,
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

/// Location subtitle: the draft lock when set, otherwise the first attached
/// photo's captured GPS ("From captured photo"), otherwise "Location not set".
class _LocationSubtitle extends StatelessWidget {
  const _LocationSubtitle({required this.draft, required this.attachedMedia});

  final ComposeDraft draft;
  final List<CapturedMedia> attachedMedia;

  @override
  Widget build(BuildContext context) {
    if (draft.latitude != null && draft.longitude != null) {
      return Text(
        '${draft.latitude!.toStringAsFixed(5)}, ${draft.longitude!.toStringAsFixed(5)}',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final gpsMedia = attachedMedia.where((m) => m.hasGps).firstOrNull;
    if (gpsMedia != null) {
      return Text(
        'From captured photo • ${gpsMedia.capturedLat!.toStringAsFixed(5)}, ${gpsMedia.capturedLng!.toStringAsFixed(5)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    return Text(
      'Location not set',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

/// Decodes a base64 payload into a memory-backed image thumbnail, falling
/// back to a placeholder icon for short/dummy captures or malformed payloads.
class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({required this.bytesBase64});

  final String bytesBase64;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Uint8List? bytes;
    try {
      final decoded = base64Decode(bytesBase64);
      if (decoded.isNotEmpty) bytes = decoded;
    } catch (_) {}

    if (bytes == null || bytes.length < 500) {
      return Container(
        color: colorScheme.surfaceContainerHigh,
        child: const Center(
          child: Icon(Icons.image, size: 40, color: Colors.grey),
        ),
      );
    }
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, st) => Container(
        color: colorScheme.surfaceContainerHigh,
        child: const Center(
          child: Icon(Icons.image, size: 40, color: Colors.grey),
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      label: Text(StringFormatters.formatCategory(category)),
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
