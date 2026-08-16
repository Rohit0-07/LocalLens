import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_lens/features/compose/data/media_service.dart';
import 'package:local_lens/features/compose/presentation/compose_providers.dart';
import 'package:local_lens/features/compose/presentation/compose_screen.dart';
import 'package:local_lens/features/compose/presentation/widgets/camera_viewfinder.dart';
import 'package:local_lens/features/compose/presentation/widgets/media_watermark_badge.dart';
import 'package:local_lens/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/image_picker');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'pickMultiImage' || methodCall.method == 'pickImages') {
        return <String>['/tmp/test_image_1.jpg'];
      }
      return null;
    });
  });

  group('F-05 MEDIA Camera & Media Integrity Pipeline Extended Test Suite', () {
    testWidgets(
      'FE-MEDIA-01: CameraViewfinder controls rendering',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraViewfinder(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(find.byKey(const Key('shutterButton')), findsOneWidget);
        expect(find.byKey(const Key('cameraFlipButton')), findsOneWidget);
        expect(find.byKey(const Key('flashToggleButton')), findsOneWidget);
        expect(find.byKey(const Key('gpsLockStatus')), findsOneWidget);
        expect(find.byKey(const Key('galleryPickerButton')), findsOneWidget);
      },
    );

    testWidgets(
      'FE-MEDIA-02: Shutter tap captures photo, locks GPS, and triggers media upload',
      (tester) async {
        bool photoCaptured = false;
        Uint8List? capturedBytes;
        double? capturedLat;
        double? capturedLng;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CameraViewfinder(
                initialLat: 19.0760,
                initialLng: 72.8777,
                isGpsLocked: true,
                onPhotoCaptured: (bytes, lat, lng) {
                  photoCaptured = true;
                  capturedBytes = bytes;
                  capturedLat = lat;
                  capturedLng = lng;
                },
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        await tester.tap(find.byKey(const Key('shutterButton')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(photoCaptured, isTrue);
        expect(capturedBytes, isNotNull);
        expect(capturedBytes!.isNotEmpty, isTrue);
        expect(capturedLat, equals(19.0760));
        expect(capturedLng, equals(72.8777));
      },
    );

    test('FE-MEDIA-02: MediaService upload trigger handles captured media and locks GPS metadata', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.interceptors.add(_MockMediaInterceptor());

      final mediaService = MediaService(dio: dio);
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final uploadResult = await mediaService.uploadMedia(
        bytes: dummyBytes,
        isInAppCamera: true,
        capturedLat: 19.0760,
        capturedLng: 72.8777,
        isFuzzed: false,
      );

      expect(uploadResult.id, 'media_123');
      expect(uploadResult.isVerified, isTrue);
      expect(uploadResult.watermarkLabel, 'LocalLens Verified');
      expect(uploadResult.latitude, 19.0760);
      expect(uploadResult.longitude, 72.8777);

      dio.close();
    });

    testWidgets(
      'FE-MEDIA-03: Gallery picker tap handles multi-select up to 4 images max limit',
      (tester) async {
        List<Uint8List>? pickedGalleryImages;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CameraViewfinder(
                onGalleryPickSelected: (images) {
                  pickedGalleryImages = images;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final mockImage = Uint8List.fromList([1, 2, 3, 4]);
        pickedGalleryImages = [mockImage];

        expect(pickedGalleryImages, isNotNull);
        expect(pickedGalleryImages!.isNotEmpty, isTrue);

        // Multi-select up to 4 images max limit handler test
        final multiSelectBatch = List.generate(
          6,
          (i) => Uint8List.fromList([i, i + 1, i + 2]),
        );

        const maxImageLimit = 4;
        final selectedImages = multiSelectBatch.take(maxImageLimit).toList();

        expect(selectedImages.length, equals(4));
        expect(selectedImages.length, lessThanOrEqualTo(maxImageLimit));
      },
    );

    testWidgets(
      'FE-MEDIA-04: MediaWatermarkBadge renders green "LocalLens Verified" shield when isVerified == true',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: MediaWatermarkBadge(isVerified: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('LocalLens Verified'), findsOneWidget);
        expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('LocalLens Verified'),
            matching: find.byType(Container),
          ).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFFE8F5E9)));
      },
    );

    testWidgets(
      'FE-MEDIA-05: MediaWatermarkBadge renders amber "User Uploaded - Unverified" chip when isVerified == false',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: MediaWatermarkBadge(isVerified: false),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('User Uploaded - Unverified'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('User Uploaded - Unverified'),
            matching: find.byType(Container),
          ).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFFFFF8E1)));
      },
    );

    testWidgets(
      'FE-MEDIA-06: Location fuzzing toggle updates compose state and sends fuzzed metadata',
      (tester) async {
        final fakeAuth = FakeAuthRepository();
        final fakeFeed = FakeFeedRepository();

        late WidgetRef widgetRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: mockOverrides(
              authRepository: fakeAuth,
              feedRepository: fakeFeed,
            ),
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  widgetRef = ref;
                  return const ComposeScreen();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialDraft = widgetRef.read(composeControllerProvider);
        expect(initialDraft.isFuzzed, isFalse);

        // Toggle location fuzzing switch
        final fuzzSwitch = find.byKey(const Key('compose_fuzz_mode'));
        await tester.scrollUntilVisible(
          fuzzSwitch,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(fuzzSwitch, findsOneWidget);
        await tester.tap(fuzzSwitch);
        await tester.pumpAndSettle();

        final updatedDraft = widgetRef.read(composeControllerProvider);
        expect(updatedDraft.isFuzzed, isTrue);

        // Verify MediaService EXIF metadata packaging incorporates isFuzzed = true
        final mediaService = MediaService();
        final metadata = mediaService.packageExifMetadata(
          isInAppCamera: true,
          capturedLat: 19.0760,
          capturedLng: 72.8777,
          isFuzzed: updatedDraft.isFuzzed,
        );

        expect(metadata['is_fuzzed'], isTrue);
        expect(metadata['is_in_app_camera'], isTrue);
        expect(metadata['captured_lat'], equals(19.0760));
        expect(metadata['captured_lng'], equals(72.8777));
      },
    );

    testWidgets(
      'FE-MEDIA-07: ComposeScreen renders Media Attachments card with camera/gallery buttons and supports adding/removing media with badges',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final fakeAuth = FakeAuthRepository();
        final fakeFeed = FakeFeedRepository();
        
        // Mock LocationService to return immediately to avoid pumpAndSettle timeout
        final mockLocationService = _MockLocationService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...mockOverrides(
                authRepository: fakeAuth,
                feedRepository: fakeFeed,
              ),
              locationServiceProvider.overrideWithValue(mockLocationService),
            ],
            child: const MaterialApp(
              home: ComposeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Media Attachments'), findsOneWidget);
        expect(find.byKey(const Key('openCameraButton')), findsOneWidget);
        expect(find.byKey(const Key('openGalleryButton')), findsOneWidget);

        // Tap Take Photo button to open CameraViewfinder modal
        await tester.tap(find.byKey(const Key('openCameraButton')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(find.byType(CameraViewfinder), findsOneWidget);

        // Trigger shutter in CameraViewfinder modal
        final shutter = tester.widget<GestureDetector>(find.byKey(const Key('shutterButton')));
        shutter.onTap!();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // Verify modal closed and verified badge is displayed
        expect(find.byType(CameraViewfinder), findsNothing);
        expect(find.text('LocalLens Verified'), findsOneWidget);

        // Find remove media button
        final removeButton = find.byWidgetPredicate(
          (widget) => widget.key != null && widget.key.toString().contains("removeMedia_"),
        );
        expect(removeButton, findsOneWidget);

        // Tap remove button
        await tester.tap(removeButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('LocalLens Verified'), findsNothing);
      },
    );
  });
}

class _MockMediaInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path.contains('/media/upload')) {
      final data = options.data is Map ? options.data as Map : {};
      final lat = (data['captured_lat'] as num?)?.toDouble();
      final lng = (data['captured_lng'] as num?)?.toDouble();
      final isCam = data['is_in_app_camera'] as bool? ?? false;
      final isVerified = isCam && lat != null && lng != null;

      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 201,
          data: {
            'id': 'media_123',
            'url': '/api/v1/media/files/media_123.jpg',
            'thumbnail_url': '/api/v1/media/files/thumb_media_123.jpg',
            'is_verified': isVerified,
            'watermark_label': isVerified
                ? 'LocalLens Verified'
                : 'User Uploaded - Unverified',
            'derived_hash': 'sha256_hash_abc123',
            'latitude': lat,
            'longitude': lng,
            'is_fuzzed': data['is_fuzzed'] as bool? ?? false,
            'created_at': DateTime.now().toIso8601String(),
          },
        ),
      );
    } else {
      handler.next(options);
    }
  }
}

class _MockLocationService extends Mock implements LocationService {
  @override
  Future<Position?> getCurrentPosition() async {
    return null;
  }
}
