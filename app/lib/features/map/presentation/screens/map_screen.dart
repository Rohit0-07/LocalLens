import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/map_controller.dart';
import '../widgets/map_pin_preview_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final TransformationController _transformationController =
      TransformationController();

  static const List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All', 'key': 'mapFilterChip_all'},
    {'id': 'road', 'label': 'Road', 'key': 'mapFilterChip_road'},
    {'id': 'sanitation', 'label': 'Sanitation', 'key': 'mapFilterChip_sanitation'},
    {'id': 'water', 'label': 'Water', 'key': 'mapFilterChip_water'},
    {'id': 'lighting', 'label': 'Lighting', 'key': 'mapFilterChip_lighting'},
    {'id': 'other', 'label': 'Other', 'key': 'mapFilterChip_other'},
  ];

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Color _categoryPinColor(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return Colors.amber.shade700;
      case 'sanitation':
        return Colors.green.shade700;
      case 'water':
        return Colors.blue.shade700;
      case 'lighting':
        return Colors.orange.shade700;
      default:
        return Colors.purple.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapPinsNotifierProvider);
    final mapNotifier = ref.read(mapPinsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => mapNotifier.fetchPins(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Interactive Canvas Map Container
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              onInteractionEnd: (_) {
                mapNotifier.updateBounds(mapState.bounds);
              },
              child: _buildMapCanvas(context, mapState, mapNotifier),
            ),
          ),

          // Non-blocking loading bar at top of map
          if (mapState.pins.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),


          // Top Category Filter Chips
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected =
                      mapState.selectedCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      key: Key(cat['key']!),
                      label: Text(cat['label']!),
                      selected: isSelected,
                      onSelected: (_) {
                        mapNotifier.selectCategory(cat['id']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Floating "Search this area" button
          if (mapState.isBoundsDirty)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  key: const Key('searchThisAreaButton'),
                  onPressed: () {
                    mapNotifier.searchThisArea();
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Search this area'),
                ),
              ),
            ),

          // Error State
          if (mapState.pins.hasError)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Failed to load map pins: ${mapState.pins.error.toString()}',
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                      TextButton(
                        key: const Key('mapErrorRetryButton'),
                        onPressed: () => mapNotifier.fetchPins(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Empty State
          if (mapState.pins.hasValue && (mapState.pins.value ?? []).isEmpty)
            Positioned(
              top: 130,
              left: 20,
              right: 20,
              child: Card(
                key: const Key('mapEmptyState'),
                color: Colors.white.withValues(alpha: 0.9),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('No issues found in this area'),
                    ],
                  ),
                ),
              ),
            ),

          // Map Pin Preview Sheet overlay when pin selected
          if (mapState.selectedPin != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MapPinPreviewSheet(
                pin: mapState.selectedPin!,
                onClose: () => mapNotifier.clearSelectedPin(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapCanvas(
    BuildContext context,
    MapState state,
    MapPinsNotifier notifier,
  ) {
    final pins = state.pins.valueOrNull ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 0 ? constraints.maxWidth : 400.0;
        final height = constraints.maxHeight > 0 ? constraints.maxHeight : 600.0;

        return GestureDetector(
          onTap: () => notifier.clearSelectedPin(),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECEF),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(width, height),
                  painter: _MapGridPainter(),
                ),
                ...pins.map((pin) {
                  final bounds = state.bounds;
                  final latRange = (bounds.maxLat - bounds.minLat) == 0
                      ? 1.0
                      : (bounds.maxLat - bounds.minLat);
                  final lngRange = (bounds.maxLng - bounds.minLng) == 0
                      ? 1.0
                      : (bounds.maxLng - bounds.minLng);

                  final dy =
                      (1.0 - (pin.latitude - bounds.minLat) / latRange) *
                          (height - 100) +
                      50;
                  final dx =
                      ((pin.longitude - bounds.minLng) / lngRange) *
                          (width - 100) +
                      50;

                  final isSelected = state.selectedPin?.id == pin.id;

                  return Positioned(
                    left: dx - 20,
                    top: dy - 40,
                    child: GestureDetector(
                      key: Key('mapPin_${pin.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        notifier.selectPin(pin);
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _categoryPinColor(pin.category),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black26,
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _categoryIcon(pin.category),
                              size: isSelected ? 24 : 18,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 8,
                            color: _categoryPinColor(pin.category),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return Icons.alt_route;
      case 'sanitation':
        return Icons.cleaning_services;
      case 'water':
        return Icons.water_drop;
      case 'lighting':
        return Icons.lightbulb;
      default:
        return Icons.place;
    }
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFD0D7DE)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pathPaint = Paint()
      ..color = const Color(0xFFC4D2DC)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke;

    final roadPath = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.2, size.width, size.height * 0.6);

    canvas.drawPath(roadPath, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
