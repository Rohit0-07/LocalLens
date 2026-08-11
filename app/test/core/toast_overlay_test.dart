import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/feedback/app_messenger.dart';
import 'package:local_lens/core/feedback/toast_overlay.dart';

Widget wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      home: Scaffold(body: Stack(children: [ToastOverlay()])),
    ),
  );
}

void main() {
  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [appMessengerProvider.overrideWith(AppMessenger.new)],
    );
  }

  testWidgets('renders a shown toast', (tester) async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    container.read(appMessengerProvider.notifier).show('hello');
    await tester.pump();

    expect(find.text('hello'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('tapping a toast dismisses it', (tester) async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    container.read(appMessengerProvider.notifier).show('hello');
    await tester.pump();
    expect(find.text('hello'), findsOneWidget);

    await tester.tap(find.text('hello'));
    await tester.pump();
    expect(find.text('hello'), findsNothing);

    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('stacks multiple toasts and dismisses only the tapped one', (
    tester,
  ) async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    final messenger = container.read(appMessengerProvider.notifier);
    messenger.show('one');
    messenger.show('two');
    messenger.show('three');
    await tester.pump();

    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(find.text('three'), findsOneWidget);

    await tester.tap(find.text('two'));
    await tester.pump();

    expect(find.text('two'), findsNothing);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('three'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
  });
}
