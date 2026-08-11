import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/feedback/error_boundary.dart';

class _ThrowingChild extends StatelessWidget {
  const _ThrowingChild({this.message = 'boom'});

  final String message;

  @override
  Widget build(BuildContext context) {
    throw StateError(message);
  }
}

void main() {
  testWidgets('shows the fallback when the child throws during build', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ErrorBoundary(child: const _ThrowingChild())),
    );
    await tester.pump();
    while (tester.takeException() != null) {}

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Please try again later.'), findsOneWidget);
  });

  testWidgets('renders the child normally when no error occurs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ErrorBoundary(child: const Text('all good'))),
    );
    await tester.pump();

    expect(find.text('all good'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
  });

  testWidgets('never leaks exception details into the UI', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorBoundary(
          child: _ThrowingChild(message: 'Exception: token=SECRET_VALUE abc'),
        ),
      ),
    );
    await tester.pump();
    while (tester.takeException() != null) {}

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(
      find.textContaining('SECRET_VALUE', findRichText: true),
      findsNothing,
    );
  });
}
