import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/map/data/map_api.dart';
import 'package:local_lens/features/map/presentation/controllers/map_controller.dart';
import 'package:local_lens/features/map/presentation/screens/map_screen.dart';
import 'package:local_lens/features/map/presentation/widgets/map_pin_preview_sheet.dart';
import 'package:mocktail/mocktail.dart';

class MockMapApi extends Mock implements MapApi {}

void main() {
  late MockMapApi mockMapApi;

  final samplePin1 = MapPin(
    id: 101,
    title: 'Huge Pothole on Main St',
    category: 'road',
    status: 'unacknowledged',
    latitude: 19.10,
    longitude: 72.85,
    wardName: 'Ward 45, Urban Central',
    isShielded: false,
    upvotesCount: 12,
    createdAt: DateTime.now(),
  );

  final samplePin2 = MapPin(
    id: 102,
    title: 'Water Leakage Near School',
    category: 'water',
    status: 'in_progress',
    latitude: 19.15,
    longitude: 72.88,
    wardName: 'Ward 45, Urban Central',
    isShielded: true,
    upvotesCount: 8,
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockMapApi = MockMapApi();
  });

  Widget buildTestableWidget(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        mapApiProvider.overrideWithValue(mockMapApi),
        ...overrides,
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('MapScreen & MapPinPreviewSheet Widget Tests (F-08-MAP)', () {
    testWidgets('MapScreen renders filter chips and map pins correctly',
        (WidgetTester tester) async {
      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [samplePin1, samplePin2]);

      await tester.pumpWidget(buildTestableWidget(const MapScreen()));
      await tester.pumpAndSettle();

      // Verify category filter chips exist with correct keys
      expect(find.byKey(const Key('mapFilterChip_all')), findsOneWidget);
      expect(find.byKey(const Key('mapFilterChip_road')), findsOneWidget);
      expect(find.byKey(const Key('mapFilterChip_sanitation')), findsOneWidget);
      expect(find.byKey(const Key('mapFilterChip_water')), findsOneWidget);
      expect(find.byKey(const Key('mapFilterChip_lighting')), findsOneWidget);
      expect(find.byKey(const Key('mapFilterChip_other')), findsOneWidget);

      // Verify pins exist with correct keys
      expect(find.byKey(const Key('mapPin_101')), findsOneWidget);
      expect(find.byKey(const Key('mapPin_102')), findsOneWidget);

      // Tap on pin 101 to bring up preview sheet
      await tester.tap(find.byKey(const Key('mapPin_101')), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify MapPinPreviewSheet displays issue details
      expect(find.byType(MapPinPreviewSheet), findsOneWidget);
      expect(find.text('Huge Pothole on Main St'), findsOneWidget);
      expect(find.text('ROAD'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('Tapping category filter chip triggers API reload',
        (WidgetTester tester) async {
      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [samplePin1]);

      await tester.pumpWidget(buildTestableWidget(const MapScreen()));
      await tester.pumpAndSettle();

      // Tap on 'road' category filter chip
      await tester.tap(find.byKey(const Key('mapFilterChip_road')));
      await tester.pumpAndSettle();

      verify(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: 'road',
            status: any(named: 'status'),
          )).called(1);
    });

    testWidgets('Shows empty state when no pins found',
        (WidgetTester tester) async {
      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestableWidget(const MapScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No issues found in this area'), findsOneWidget);
    });

    testWidgets('Search this area button appears when bounds updated',
        (WidgetTester tester) async {
      when(() => mockMapApi.getMapPins(
            minLat: any(named: 'minLat'),
            maxLat: any(named: 'maxLat'),
            minLng: any(named: 'minLng'),
            maxLng: any(named: 'maxLng'),
            category: any(named: 'category'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [samplePin1]);

      final container = ProviderContainer(
        overrides: [
          mapApiProvider.overrideWithValue(mockMapApi),
        ],
      );

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MapScreen()),
      ));
      await tester.pumpAndSettle();

      // Initially search button not visible
      expect(find.byKey(const Key('searchThisAreaButton')), findsNothing);

      // Update bounds via controller
      container.read(mapPinsNotifierProvider.notifier).updateBounds(
            const MapBounds(minLat: 19.05, maxLat: 19.25, minLng: 72.82, maxLng: 72.92),
          );
      await tester.pumpAndSettle();

      // Search this area button should now appear
      expect(find.byKey(const Key('searchThisAreaButton')), findsOneWidget);

      // Tap search button
      await tester.tap(find.byKey(const Key('searchThisAreaButton')), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Button disappears after searching
      expect(find.byKey(const Key('searchThisAreaButton')), findsNothing);
    });
  });
}
