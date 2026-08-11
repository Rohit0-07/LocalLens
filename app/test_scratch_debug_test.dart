import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('const canonicalization', () {
    debugPrint('obj identity: ${identical(const Object(), const Object())}');
    debugPrint('tune data identity: ${identical(Icons.tune, Icons.tune)}');
    debugPrint('icon identity: ${identical(const Icon(Icons.tune), const Icon(Icons.tune))}');
  });

  testWidgets('debug icon identity', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              key: Key('filterButton'),
              tooltip: 'Filters',
              icon: const Icon(Icons.tune),
              onPressed: null,
            ),
          ],
        ),
      ),
    ));
    final button = tester.widget<IconButton>(find.byKey(const Key('filterButton')));
    final icon = button.icon as Icon;
    debugPrint('icon widget runtime: ${icon.runtimeType}');
    debugPrint('icon.icon == Icons.tune: ${icon.icon == Icons.tune}');
    debugPrint('identical iconData: ${identical(icon.icon, Icons.tune)}');
    debugPrint('identical icon widget: ${identical(icon, const Icon(Icons.tune))}');
    debugPrint('icon hash: ${icon.hashCode} vs const hash: ${const Icon(Icons.tune).hashCode}');
    debugPrint('all icon buttons: ${find.byType(IconButton).evaluate().length}');
    for (final e in find.byType(IconButton).evaluate()) {
      final w = e.widget;
      debugPrint('  ${w.key} -> ${w is IconButton ? (w.icon as Icon).icon : '?'}');
    }
  });
}
