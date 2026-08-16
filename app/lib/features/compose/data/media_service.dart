import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../auth/presentation/auth_providers.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService(
    dio: Dio(
      BaseOptions(
        baseUrl: AppConfig.dev.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    ),
    accessTokenProvider: () {
      final session = ref.read(sessionProvider);
      return session?.accessToken;
    },
  );
});

class MediaUploadResult {
  final String id;
  final String url;
  final String thumbnailUrl;
  final bool isVerified;
  final String watermarkLabel;
  final String derivedHash;
  final double? latitude;
  final double? longitude;
  final bool isFuzzed;
  final DateTime createdAt;

  MediaUploadResult({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.isVerified,
    required this.watermarkLabel,
    required this.derivedHash,
    this.latitude,
    this.longitude,
    required this.isFuzzed,
    required this.createdAt,
  });

  factory MediaUploadResult.fromJson(Map<String, dynamic> json) {
    return MediaUploadResult(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      watermarkLabel: json['watermark_label'] as String? ?? 'Unverified',
      derivedHash: json['derived_hash'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isFuzzed: json['is_fuzzed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'is_verified': isVerified,
      'watermark_label': watermarkLabel,
      'derived_hash': derivedHash,
      'latitude': latitude,
      'longitude': longitude,
      'is_fuzzed': isFuzzed,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class MediaService {
  final Dio _dio;
  final String? Function()? accessTokenProvider;

  MediaService({Dio? dio, this.accessTokenProvider})
      : _dio = dio ?? Dio();

  /// Compresses raw image bytes to simulate quality reduction & optimization.
  Uint8List compressImage(Uint8List bytes, {double quality = 0.85}) {
    // Return compressed byte simulation
    return bytes;
  }

  /// Packages EXIF payload metadata.
  Map<String, dynamic> packageExifMetadata({
    required bool isInAppCamera,
    double? capturedLat,
    double? capturedLng,
    bool isFuzzed = false,
  }) {
    return {
      'is_in_app_camera': isInAppCamera,
      'captured_lat': capturedLat,
      'captured_lng': capturedLng,
      'is_fuzzed': isFuzzed,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Uploads media bytes to backend POST /api/v1/media/upload.
  Future<MediaUploadResult> uploadMedia({
    required Uint8List bytes,
    required bool isInAppCamera,
    double? capturedLat,
    double? capturedLng,
    bool isFuzzed = false,
    String? filename,
  }) async {
    final compressedBytes = compressImage(bytes);
    final base64Payload = base64Encode(compressedBytes);

    final payload = {
      'base64_payload': base64Payload,
      'is_in_app_camera': isInAppCamera,
      'captured_lat': capturedLat,
      'captured_lng': capturedLng,
      'is_fuzzed': isFuzzed,
    };

    final token = accessTokenProvider?.call();
    final response = await _dio.post(
      '/media/upload',
      data: payload,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return MediaUploadResult.fromJson(
        response.data is String ? jsonDecode(response.data) : response.data,
      );
    } else {
      throw Exception('Failed to upload media: ${response.statusMessage}');
    }
  }
}
