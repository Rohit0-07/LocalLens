import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_lens/core/services/location_service.dart';
import 'package:local_lens/features/compose/presentation/compose_screen.dart';
import 'package:local_lens/features/compose/presentation/widgets/camera_viewfinder.dart';

import '../../helpers.dart';

class _FakeLocationService implements LocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gallery disabled (camera-only capture)', () {
    testWidgets('ComposeScreen renders without openGalleryButton', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...mockOverrides(
              authRepository: FakeAuthRepository(),
              feedRepository: FakeFeedRepository(),
            ),
            locationServiceProvider.overrideWithValue(_FakeLocationService()),
          ],
          child: const MaterialApp(
            home: ComposeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('openGalleryButton')), findsNothing);
    });

    testWidgets('CameraViewfinder renders without galleryPickerButton',
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

      expect(find.byKey(const Key('galleryPickerButton')), findsNothing);
    });
  });
}
