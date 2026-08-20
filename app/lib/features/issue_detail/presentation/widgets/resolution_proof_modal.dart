import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/feedback/error_copy.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../compose/data/media_service.dart';
import '../../../compose/presentation/widgets/camera_viewfinder.dart';
import '../../../feed/presentation/feed_providers.dart';
import '../screens/issue_detail_screen.dart';

/// Modal bottom sheet for capturing and uploading resolution proof media with live GPS / watermark,
/// notes, and submitting the proof to initiate community verification.
class ResolutionProofModal extends ConsumerStatefulWidget {
  const ResolutionProofModal({
    super.key,
    required this.issueId,
    this.initialLat,
    this.initialLng,
    this.mediaService,
    this.locationService,
  });

  final int issueId;
  final double? initialLat;
  final double? initialLng;
  final MediaService? mediaService;
  final LocationService? locationService;

  static Future<void> show(
    BuildContext context, {
    required int issueId,
    double? initialLat,
    double? initialLng,
    MediaService? mediaService,
    LocationService? locationService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResolutionProofModal(
        issueId: issueId,
        initialLat: initialLat,
        initialLng: initialLng,
        mediaService: mediaService,
        locationService: locationService,
      ),
    );
  }

  @override
  ConsumerState<ResolutionProofModal> createState() =>
      _ResolutionProofModalState();
}

class _ResolutionProofModalState extends ConsumerState<ResolutionProofModal> {
  final TextEditingController _notesController = TextEditingController();
  Uint8List? _capturedBytes;
  bool _isInAppCamera = false;
  double? _capturedLat;
  double? _capturedLng;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _openCameraViewfinder() {
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
            locationService: widget.locationService ??
                ref.read(locationServiceProvider),
            initialLat: widget.initialLat,
            initialLng: widget.initialLng,
            isGpsLocked: widget.initialLat != null && widget.initialLng != null,
            onPhotoCaptured: (bytes, lat, lng) {
              setState(() {
                _capturedBytes = bytes;
                _isInAppCamera = true;
                _capturedLat = lat ?? widget.initialLat;
                _capturedLng = lng ?? widget.initialLng;
                _errorMessage = null;
              });
              Navigator.pop(modalCtx);
            },
          ),
        );
      },
    );
  }

  Future<void> _submitResolution() async {
    if (_capturedBytes == null) {
      setState(() {
        _errorMessage = context.tr('resolution_photo_required');
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final MediaService mediaService =
          widget.mediaService ?? ref.read(mediaServiceProvider);
      final uploadResult = await mediaService.uploadMedia(
        bytes: _capturedBytes!,
        isInAppCamera: _isInAppCamera,
        capturedLat: _capturedLat ?? widget.initialLat,
        capturedLng: _capturedLng ?? widget.initialLng,
      );

      final repo = ref.read(feedRepositoryProvider);
      await repo.submitResolution(
        issueId: widget.issueId,
        proofUrl: uploadResult.url,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(singleIssueProvider(widget.issueId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('resolution_submitted')),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = friendlyErrorMessage(
            err,
            fallback: context.tr('resolution_submit_failed'),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: keyboardInset + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.resolved.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: AppColors.resolved,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('submit_resolution_dialog_title'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Upload photo proof to initiate community verification',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isUploading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Media Picker / Preview Section
              if (_capturedBytes != null) ...[
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.resolved.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _capturedBytes!,
                          key: const Key('resolution_photo_preview'),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.photo,
                                  color: AppColors.resolved, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        key: _isInAppCamera
                            ? const Key('gps_verified_badge')
                            : const Key('gallery_photo_badge'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isInAppCamera
                              ? AppColors.resolved.withValues(alpha: 0.9)
                              : Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isInAppCamera
                                  ? Icons.gps_fixed_rounded
                                  : Icons.photo_library,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isInAppCamera
                                  ? 'GPS Verified Proof'
                                  : 'Gallery Image',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Row(
                        children: [
                          FilledButton.tonalIcon(
                            key: const Key('resolution_retake_button'),
                            onPressed: _isUploading
                                ? null
                                : _openCameraViewfinder,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(context.tr('resolution_retake_photo')),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            key: const Key('resolution_remove_photo_button'),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: _isUploading
                                ? null
                                : () => setState(() {
                                      _capturedBytes = null;
                                      _isInAppCamera = false;
                                    }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  key: const Key('resolution_photo_placeholder'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('resolution_proof_url'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('camera_only_capture_hint'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        key: const Key('resolution_take_photo_button'),
                        icon: const Icon(Icons.photo_camera_rounded, size: 18),
                        label: Text(context.tr('resolution_take_photo')),
                        onPressed: _openCameraViewfinder,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Resolution Notes
              TextField(
                key: const Key('resolution_notes_input'),
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.tr('resolution_notes_label'),
                  hintText: context.tr('resolution_notes_hint'),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Submit & Cancel Buttons
              FilledButton.icon(
                key: const Key('resolution_submit_confirm_button'),
                onPressed: _isUploading ? null : _submitResolution,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isUploading
                      ? 'Uploading Proof...'
                      : context.tr('action_submit'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('resolution_cancel_button'),
                onPressed: _isUploading ? null : () => Navigator.pop(context),
                child: Text(context.tr('action_cancel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
