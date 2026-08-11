import 'package:flutter/foundation.dart';
import '../../data/media_service.dart';

class LocalSelectedMedia {
  final Uint8List bytes;
  final bool isInAppCamera;
  final double? capturedLat;
  final double? capturedLng;

  LocalSelectedMedia({
    required this.bytes,
    required this.isInAppCamera,
    this.capturedLat,
    this.capturedLng,
  });
}

class ComposeState {
  final List<LocalSelectedMedia> selectedMediaList;
  final List<MediaUploadResult> uploadedMediaList;
  final bool isUploading;
  final bool isFuzzed;
  final String? errorMessage;
  static const int maxImagesAllowed = 4;

  ComposeState({
    this.selectedMediaList = const [],
    this.uploadedMediaList = const [],
    this.isUploading = false,
    this.isFuzzed = false,
    this.errorMessage,
  });

  ComposeState copyWith({
    List<LocalSelectedMedia>? selectedMediaList,
    List<MediaUploadResult>? uploadedMediaList,
    bool? isUploading,
    bool? isFuzzed,
    String? errorMessage,
  }) {
    return ComposeState(
      selectedMediaList: selectedMediaList ?? this.selectedMediaList,
      uploadedMediaList: uploadedMediaList ?? this.uploadedMediaList,
      isUploading: isUploading ?? this.isUploading,
      isFuzzed: isFuzzed ?? this.isFuzzed,
      errorMessage: errorMessage,
    );
  }
}

class ComposeController extends ChangeNotifier {
  final MediaService _mediaService;
  ComposeState _state = ComposeState();

  ComposeController({MediaService? mediaService})
      : _mediaService = mediaService ?? MediaService();

  ComposeState get state => _state;

  void toggleLocationFuzzing(bool value) {
    _state = _state.copyWith(isFuzzed: value);
    notifyListeners();
  }

  /// Adds a photo captured via in-app camera
  bool addCapturedPhoto(Uint8List bytes, double? lat, double? lng) {
    if (_state.selectedMediaList.length >= ComposeState.maxImagesAllowed) {
      _state = _state.copyWith(
        errorMessage: 'Maximum ${ComposeState.maxImagesAllowed} images allowed.',
      );
      notifyListeners();
      return false;
    }

    final newMedia = LocalSelectedMedia(
      bytes: bytes,
      isInAppCamera: true,
      capturedLat: lat,
      capturedLng: lng,
    );

    _state = _state.copyWith(
      selectedMediaList: [..._state.selectedMediaList, newMedia],
      errorMessage: null,
    );
    notifyListeners();
    return true;
  }

  /// Adds gallery multi-selected images (up to 4 max)
  bool addGalleryImages(List<Uint8List> imageBytesList) {
    final currentCount = _state.selectedMediaList.length;
    final availableSlots = ComposeState.maxImagesAllowed - currentCount;

    if (availableSlots <= 0) {
      _state = _state.copyWith(
        errorMessage: 'Maximum ${ComposeState.maxImagesAllowed} images allowed.',
      );
      notifyListeners();
      return false;
    }

    final imagesToAdd = imageBytesList.take(availableSlots).map(
          (bytes) => LocalSelectedMedia(
            bytes: bytes,
            isInAppCamera: false,
            capturedLat: null,
            capturedLng: null,
          ),
        );

    _state = _state.copyWith(
      selectedMediaList: [..._state.selectedMediaList, ...imagesToAdd],
      errorMessage: imageBytesList.length > availableSlots
          ? 'Selected images truncated to maximum limit of 4.'
          : null,
    );
    notifyListeners();
    return true;
  }

  void removeImageAtIndex(int index) {
    if (index >= 0 && index < _state.selectedMediaList.length) {
      final updated = List<LocalSelectedMedia>.from(_state.selectedMediaList)
        ..removeAt(index);
      _state = _state.copyWith(selectedMediaList: updated);
      notifyListeners();
    }
  }

  /// Uploads all selected media via MediaService
  Future<List<MediaUploadResult>> uploadAllSelectedMedia() async {
    if (_state.selectedMediaList.isEmpty) return [];

    _state = _state.copyWith(isUploading: true, errorMessage: null);
    notifyListeners();

    final List<MediaUploadResult> results = [];
    try {
      for (final item in _state.selectedMediaList) {
        final result = await _mediaService.uploadMedia(
          bytes: item.bytes,
          isInAppCamera: item.isInAppCamera,
          capturedLat: item.capturedLat,
          capturedLng: item.capturedLng,
          isFuzzed: _state.isFuzzed,
        );
        results.add(result);
      }

      _state = _state.copyWith(
        uploadedMediaList: [..._state.uploadedMediaList, ...results],
        selectedMediaList: [],
        isUploading: false,
      );
      notifyListeners();
      return results;
    } catch (e) {
      _state = _state.copyWith(
        isUploading: false,
        errorMessage: 'Upload failed: ${e.toString()}',
      );
      notifyListeners();
      rethrow;
    }
  }
}
