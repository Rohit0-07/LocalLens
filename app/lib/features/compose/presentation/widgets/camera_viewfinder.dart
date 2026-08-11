import 'dart:typed_data';
import 'package:flutter/material.dart';

enum FlashMode { off, on, auto }

enum CameraPosition { back, front }

class CameraViewfinder extends StatefulWidget {
  final Function(Uint8List photoBytes, double? lat, double? lng)? onPhotoCaptured;
  final Function(List<Uint8List> galleryImages)? onGalleryPickSelected;
  final double? initialLat;
  final double? initialLng;
  final bool isGpsLocked;

  const CameraViewfinder({
    super.key,
    this.onPhotoCaptured,
    this.onGalleryPickSelected,
    this.initialLat,
    this.initialLng,
    this.isGpsLocked = true,
  });

  @override
  State<CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<CameraViewfinder> {
  FlashMode _flashMode = FlashMode.off;
  CameraPosition _cameraPosition = CameraPosition.back;
  bool _isGpsLocked = true;
  double? _currentLat;
  double? _currentLng;

  @override
  void initState() {
    super.initState();
    _isGpsLocked = widget.isGpsLocked;
    _currentLat = widget.initialLat ?? 12.9716;
    _currentLng = widget.initialLng ?? 77.5946;
  }

  void _toggleFlash() {
    setState(() {
      switch (_flashMode) {
        case FlashMode.off:
          _flashMode = FlashMode.on;
          break;
        case FlashMode.on:
          _flashMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          _flashMode = FlashMode.off;
          break;
      }
    });
  }

  void _toggleCameraFlip() {
    setState(() {
      _cameraPosition = _cameraPosition == CameraPosition.back
          ? CameraPosition.front
          : CameraPosition.back;
    });
  }

  void _triggerShutter() {
    final dummyBytes = Uint8List.fromList(
      List.generate(100, (index) => (index * 7) % 256),
    );
    final lat = _isGpsLocked ? _currentLat : null;
    final lng = _isGpsLocked ? _currentLng : null;

    if (widget.onPhotoCaptured != null) {
      widget.onPhotoCaptured!(dummyBytes, lat, lng);
    }
  }

  void _triggerGalleryPicker() {
    final dummyBytes = Uint8List.fromList(
      List.generate(100, (index) => (index * 13) % 256),
    );
    if (widget.onGalleryPickSelected != null) {
      widget.onGalleryPickSelected!([dummyBytes]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flashIcon = switch (_flashMode) {
      FlashMode.off => Icons.flash_off,
      FlashMode.on => Icons.flash_on,
      FlashMode.auto => Icons.flash_auto,
    };

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Stack(
          children: [
            // Camera Feed Simulation
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _cameraPosition == CameraPosition.back
                        ? Icons.camera_alt_outlined
                        : Icons.face,
                    size: 64,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _cameraPosition == CameraPosition.back
                        ? 'Rear Viewfinder Active'
                        : 'Front Viewfinder Active',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Top Control Bar: Flash & GPS Indicator
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('flashToggleButton'),
                    icon: Icon(flashIcon, color: Colors.white),
                    onPressed: _toggleFlash,
                    tooltip: 'Flash Toggle',
                  ),
                  Container(
                    key: const Key('gpsLockStatus'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isGpsLocked
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.amber.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isGpsLocked ? Icons.gps_fixed : Icons.gps_not_fixed,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isGpsLocked ? 'GPS Locked' : 'GPS Searching',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Control Bar: Gallery, Shutter, Flip
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    key: const Key('galleryPickerButton'),
                    icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                    onPressed: _triggerGalleryPicker,
                    tooltip: 'Gallery Picker (Max 4)',
                  ),
                  GestureDetector(
                    key: const Key('shutterButton'),
                    onTap: _triggerShutter,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white24,
                      ),
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('cameraFlipButton'),
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                    onPressed: _toggleCameraFlip,
                    tooltip: 'Camera Flip',
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
