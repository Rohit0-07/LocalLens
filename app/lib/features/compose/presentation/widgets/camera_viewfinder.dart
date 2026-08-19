import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../core/services/location_service.dart';

enum FlashModeToggle { off, on, auto }

enum CameraPositionToggle { back, front }

class CameraViewfinder extends StatefulWidget {
  final Function(Uint8List photoBytes, double? lat, double? lng)? onPhotoCaptured;
  final Function(List<Uint8List> galleryImages)? onGalleryPickSelected;
  final double? initialLat;
  final double? initialLng;
  final bool isGpsLocked;
  /// Injected for testability; defaults to the real geolocator implementation.
  final LocationService? locationService;

  const CameraViewfinder({
    super.key,
    this.onPhotoCaptured,
    this.onGalleryPickSelected,
    this.initialLat,
    this.initialLng,
    this.isGpsLocked = true,
    this.locationService,
  });

  @override
  State<CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<CameraViewfinder> {
  FlashModeToggle _flashMode = FlashModeToggle.off;
  CameraPositionToggle _cameraPosition = CameraPositionToggle.back;
  bool _isGpsLocked = false;
  double? _currentLat;
  double? _currentLng;

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  final bool _isPermissionDenied = false;
  late final LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? LocationService();
    _isGpsLocked = widget.isGpsLocked;
    _currentLat = widget.initialLat;
    _currentLng = widget.initialLng;
    _initializeCamera();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (mounted) {
      if (position != null) {
        setState(() {
          _isGpsLocked = true;
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });
      } else {
        setState(() {
          _isGpsLocked = false;
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        return;
      }
      
      CameraDescription? selectedCamera;
      for (final camera in _cameras) {
        if (_cameraPosition == CameraPositionToggle.back && camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        } else if (_cameraPosition == CameraPositionToggle.front && camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      selectedCamera ??= _cameras.first;

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _applyFlashMode();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameras = [];
          _isCameraInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _applyFlashMode() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    switch (_flashMode) {
      case FlashModeToggle.off:
        _controller!.setFlashMode(FlashMode.off);
        break;
      case FlashModeToggle.on:
        _controller!.setFlashMode(FlashMode.always);
        break;
      case FlashModeToggle.auto:
        _controller!.setFlashMode(FlashMode.auto);
        break;
    }
  }

  void _toggleFlash() {
    setState(() {
      switch (_flashMode) {
        case FlashModeToggle.off:
          _flashMode = FlashModeToggle.on;
          break;
        case FlashModeToggle.on:
          _flashMode = FlashModeToggle.auto;
          break;
        case FlashModeToggle.auto:
          _flashMode = FlashModeToggle.off;
          break;
      }
    });
    _applyFlashMode();
  }

  void _toggleCameraFlip() {
    setState(() {
      _cameraPosition = _cameraPosition == CameraPositionToggle.back
          ? CameraPositionToggle.front
          : CameraPositionToggle.back;
      _isCameraInitialized = false;
    });
    _initializeCamera();
  }

  Future<void> _triggerShutter() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      // Never fabricate a dummy capture; kick initialization so the next tap
      // has a real, initialized camera.
      _initializeCamera();
      return;
    }
    if (_controller!.value.isTakingPicture) return;

    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      final lat = _isGpsLocked ? _currentLat : null;
      final lng = _isGpsLocked ? _currentLng : null;

      if (widget.onPhotoCaptured != null) {
        widget.onPhotoCaptured!(bytes, lat, lng);
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final flashIcon = switch (_flashMode) {
      FlashModeToggle.off => Icons.flash_off,
      FlashModeToggle.on => Icons.flash_on,
      FlashModeToggle.auto => Icons.flash_auto,
    };

    Widget cameraPreview;
    if (_isPermissionDenied) {
      cameraPreview = const Center(
        child: Text(
          'Camera permission denied.',
          style: TextStyle(color: Colors.white),
        ),
      );
    } else if (_cameras.isEmpty && _isCameraInitialized) {
       cameraPreview = const Center(
        child: Text(
          'No cameras available.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    else if (!_isCameraInitialized || _controller == null) {
      cameraPreview = const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else {
      cameraPreview = CameraPreview(_controller!);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16.0),
      ),
        child: Stack(
          children: [
            // Camera Feed Simulation
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: cameraPreview,
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

            // Bottom Control Bar: Shutter, Flip
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
      );
  }
}
