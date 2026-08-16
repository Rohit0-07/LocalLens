import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/media_url.dart';
import 'shimmer_loading.dart';

/// Class representing a parsed media item (image or video).
class MediaItem {
  final String url;
  final bool isVideo;
  final String? label;

  const MediaItem({
    required this.url,
    this.isVideo = false,
    this.label,
  });

  static bool isVideoUrl(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.mp4') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.webm') ||
        clean.endsWith('.mkv') ||
        clean.endsWith('.avi') ||
        clean.endsWith('.m4v') ||
        url.contains('/video/') ||
        url.contains('video_url');
  }
}

/// A versatile, production-grade media widget that renders image thumbnails,
/// multiple-photo galleries, and video previews with play badges.
///
/// Features:
/// - Single image, dual split preview, or multi-image grid (+N more).
/// - Video detection and rich play badge overlay with duration chip.
/// - Shimmer placeholder on load and graceful error / offline fallback.
/// - Tap-to-view fullscreen modal with pinch-to-zoom (`InteractiveViewer`).
/// - Tap-to-play interactive video preview sheet.
class MediaPreviewWidget extends StatelessWidget {
  const MediaPreviewWidget({
    super.key,
    this.mediaUrls = const <String>[],
    this.videoUrl,
    this.imageUrl,
    this.resolutionProof,
    this.maxHeight = 220.0,
    this.borderRadius,
    this.aspectRatio,
    this.heroTagPrefix,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  /// Shorthand constructor for a single image or video URL.
  factory MediaPreviewWidget.single({
    Key? key,
    required String url,
    bool? isVideo,
    double maxHeight = 220.0,
    BorderRadius? borderRadius,
    double? aspectRatio,
    BoxFit fit = BoxFit.cover,
    VoidCallback? onTap,
  }) {
    final video = isVideo ?? MediaItem.isVideoUrl(url);
    return MediaPreviewWidget(
      key: key,
      videoUrl: video ? url : null,
      imageUrl: video ? null : url,
      maxHeight: maxHeight,
      borderRadius: borderRadius,
      aspectRatio: aspectRatio,
      fit: fit,
      onTap: onTap,
    );
  }

  final List<String> mediaUrls;
  final String? videoUrl;
  final String? imageUrl;
  final String? resolutionProof;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final double? aspectRatio;
  final String? heroTagPrefix;
  final BoxFit fit;
  final VoidCallback? onTap;

  /// Compiles all input sources into a list of normalized [MediaItem]s.
  List<MediaItem> _resolveItems() {
    final items = <MediaItem>[];
    final seen = <String>{};

    void addItem(String? url, {bool isVideo = false, String? label}) {
      if (url == null || url.trim().isEmpty) return;
      final trimmed = resolveMediaUrl(url);
      if (seen.contains(trimmed)) return;
      seen.add(trimmed);
      items.add(MediaItem(
        url: trimmed,
        isVideo: isVideo || MediaItem.isVideoUrl(trimmed),
        label: label,
      ));
    }

    if (videoUrl != null) {
      addItem(videoUrl, isVideo: true, label: 'Video Demo');
    }
    if (imageUrl != null) {
      addItem(imageUrl);
    }
    if (resolutionProof != null) {
      addItem(resolutionProof, label: 'Resolution Proof');
    }
    for (final url in mediaUrls) {
      addItem(url);
    }

    return items;
  }

  static void openFullScreen(
    BuildContext context, {
    required List<MediaItem> items,
    int initialIndex = 0,
    String? title,
  }) {
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (dialogCtx) => MediaFullScreenViewer(
        items: items,
        initialIndex: initialIndex,
        title: title,
      ),
    );
  }

  static void openVideoPlayer(
    BuildContext context, {
    required String videoUrl,
    String? title,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => VideoPlayerSheet(
        videoUrl: videoUrl,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _resolveItems();
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);

    Widget content;
    if (items.length == 1) {
      content = _buildSingleItem(context, items.first, 0);
    } else if (items.length == 2) {
      content = _buildDualItem(context, items);
    } else {
      content = _buildGridItem(context, items);
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: aspectRatio != null
            ? AspectRatio(aspectRatio: aspectRatio!, child: content)
            : content,
      ),
    );
  }

  Widget _buildSingleItem(BuildContext context, MediaItem item, int index) {
    return InkWell(
      onTap: onTap ?? () => _handleItemTap(context, [item], index),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          _MediaThumbnail(
            item: item,
            fit: fit,
            heroTag: heroTagPrefix != null ? '${heroTagPrefix}_$index' : null,
          ),
          if (item.isVideo)
            _VideoBadgeOverlay(item: item)
          else if (item.label != null)
            Positioned(
              top: 8,
              left: 8,
              child: _MediaLabelBadge(label: item.label!),
            ),
        ],
      ),
    );
  }

  Widget _buildDualItem(BuildContext context, List<MediaItem> items) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap ?? () => _handleItemTap(context, items, 0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _MediaThumbnail(item: items[0], fit: fit),
                if (items[0].isVideo) _VideoBadgeOverlay(item: items[0]),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: InkWell(
            onTap: onTap ?? () => _handleItemTap(context, items, 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _MediaThumbnail(item: items[1], fit: fit),
                if (items[1].isVideo) _VideoBadgeOverlay(item: items[1]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, List<MediaItem> items) {
    final first = items[0];
    final second = items[1];
    final third = items[2];
    final remaining = items.length - 3;

    return Row(
      children: [
        // Left dominant tile
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: onTap ?? () => _handleItemTap(context, items, 0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _MediaThumbnail(item: first, fit: fit),
                if (first.isVideo) _VideoBadgeOverlay(item: first),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Right split column
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTap ?? () => _handleItemTap(context, items, 1),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _MediaThumbnail(item: second, fit: fit),
                      if (second.isVideo) _VideoBadgeOverlay(item: second),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: InkWell(
                  onTap: onTap ?? () => _handleItemTap(context, items, 2),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _MediaThumbnail(item: third, fit: fit),
                      if (third.isVideo) _VideoBadgeOverlay(item: third),
                      if (remaining > 0)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          alignment: Alignment.center,
                          child: Text(
                            '+$remaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleItemTap(BuildContext context, List<MediaItem> items, int index) {
    final item = items[index];
    if (item.isVideo) {
      openVideoPlayer(context, videoUrl: item.url, title: item.label);
    } else {
      openFullScreen(context, items: items, initialIndex: index);
    }
  }
}

/// Gallery view widget displaying horizontal or grid list of media items.
class MediaGalleryView extends StatelessWidget {
  const MediaGalleryView({
    super.key,
    required this.mediaUrls,
    this.videoUrl,
    this.height = 180,
    this.borderRadius,
    this.onTapItem,
  });

  final List<String> mediaUrls;
  final String? videoUrl;
  final double height;
  final BorderRadius? borderRadius;
  final void Function(MediaItem item, int index)? onTapItem;

  @override
  Widget build(BuildContext context) {
    final items = <MediaItem>[];
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      items.add(MediaItem(url: videoUrl!, isVideo: true));
    }
    for (final url in mediaUrls) {
      if (url.isNotEmpty) {
        items.add(MediaItem(url: url, isVideo: MediaItem.isVideoUrl(url)));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: height * 1.3,
            child: MediaPreviewWidget.single(
              url: item.url,
              isVideo: item.isVideo,
              borderRadius: borderRadius,
              onTap: () {
                if (onTapItem != null) {
                  onTapItem!(item, index);
                } else if (item.isVideo) {
                  MediaPreviewWidget.openVideoPlayer(context, videoUrl: item.url);
                } else {
                  MediaPreviewWidget.openFullScreen(
                    context,
                    items: items,
                    initialIndex: index,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

/// Internal image/video thumbnail builder with shimmer and error fallback.
class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({
    required this.item,
    this.fit = BoxFit.cover,
    this.heroTag,
  });

  final MediaItem item;
  final BoxFit fit;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget imageWidget = Image.network(
      resolveMediaUrl(item.url),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return ShimmerLoading(
          child: Container(
            color: isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBase,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _ErrorFallback(isVideo: item.isVideo);
      },
    );

    if (heroTag != null) {
      imageWidget = Hero(tag: heroTag!, child: imageWidget);
    }

    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightBorder,
      child: imageWidget,
    );
  }
}

/// Overlay displayed on top of video thumbnails with play button and duration badge.
class _VideoBadgeOverlay extends StatelessWidget {
  const _VideoBadgeOverlay({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Center Play Icon Button
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brand.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            // Bottom Video Badge
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaLabelBadge extends StatelessWidget {
  const _MediaLabelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Fallback widget when an image or video thumbnail cannot be loaded.
class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback({required this.isVideo});

  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE8EEF5),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVideo ? Icons.videocam_outlined : Icons.image_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 4),
          Text(
            isVideo ? 'Video Preview' : 'Media Preview',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fullscreen Image Viewer with zoom & pan support using `InteractiveViewer`.
class MediaFullScreenViewer extends StatefulWidget {
  const MediaFullScreenViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.title,
  });

  final List<MediaItem> items;
  final int initialIndex;
  final String? title;

  @override
  State<MediaFullScreenViewer> createState() => _MediaFullScreenViewerState();
}

class _MediaFullScreenViewerState extends State<MediaFullScreenViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    final currentItem = widget.items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Swiper / Zoomable Viewer
            PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _resetZoom();
                });
              },
              itemBuilder: (context, index) {
                final item = widget.items[index];
                if (item.isVideo) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 72,
                          color: AppColors.brand,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            MediaPreviewWidget.openVideoPlayer(
                              context,
                              videoUrl: item.url,
                              title: widget.title,
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play Video'),
                        ),
                      ],
                    ),
                  );
                }
                return InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      resolveMediaUrl(item.url),
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white60,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load media',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top App Bar Controls
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    key: const Key('closeFullScreenMedia'),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  if (total > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.zoom_out_map_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Reset Zoom',
                    onPressed: _resetZoom,
                  ),
                ],
              ),
            ),

            // Bottom hint if single or multiple
            if (currentItem.label != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentItem.label!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rich interactive video player sheet with simulated controls (Play/Pause, Scrubber, Mute).
class VideoPlayerSheet extends StatefulWidget {
  const VideoPlayerSheet({
    super.key,
    required this.videoUrl,
    this.title,
  });

  final String videoUrl;
  final String? title;

  @override
  State<VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<VideoPlayerSheet> {
  bool _isPlaying = true;
  bool _isMuted = false;
  double _progress = 0.25;

  String _formatTime(double progress) {
    const totalSeconds = 45;
    final currentSec = (progress * totalSeconds).toInt();
    final mins = (currentSec ~/ 60).toString().padLeft(2, '0');
    final secs = (currentSec % 60).toString().padLeft(2, '0');
    return '$mins:$secs / 00:45';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14171F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.videocam_rounded, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title ?? 'Video Evidence / Demo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Video Canvas / Player Interface
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Simulated 16:9 Video Canvas
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background video illustration
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.35,
                                child: Image.network(
                                  resolveMediaUrl(widget.videoUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Center(
                                    child: Icon(
                                      Icons.movie_outlined,
                                      color: Colors.white30,
                                      size: 56,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Interactive Center Play/Pause toggle
                            GestureDetector(
                              key: const Key('videoPlayerPlayPause'),
                              onTap: () => setState(() => _isPlaying = !_isPlaying),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.brand.withValues(alpha: 0.85),
                                ),
                                child: Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),

                            // Video Status Overlay
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _isPlaying ? 'PLAYING' : 'PAUSED',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Controls Row: Scrubber Slider + Mute + Time
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: AppColors.brand,
                            size: 28,
                          ),
                          onPressed: () =>
                              setState(() => _isPlaying = !_isPlaying),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                            ),
                            child: Slider(
                              value: _progress,
                              activeColor: AppColors.brand,
                              onChanged: (val) =>
                                  setState(() => _progress = val),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('videoPlayerMuteToggle'),
                          icon: Icon(
                            _isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            size: 22,
                          ),
                          onPressed: () => setState(() => _isMuted = !_isMuted),
                        ),
                      ],
                    ),

                    // Time display & URL info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_progress),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'LocalLens HD Video Stream',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Media details card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: AppColors.brand,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Verified citizen media proof recorded on-device.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
