import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/feedback/app_messenger.dart';

void main() {
  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [appMessengerProvider.overrideWith(AppMessenger.new)],
    );
  }

  group('AppMessenger.show', () {
    test('appends a toast with a unique incrementing id and default type', () {
      FakeAsync().run((async) {
        final container = makeContainer();
        final messenger = container.read(appMessengerProvider.notifier);

        messenger.show('first');
        messenger.show('second');

        final toasts = container.read(appMessengerProvider);
        expect(toasts, hasLength(2));
        expect(toasts[0].message, 'first');
        expect(toasts[0].type, ToastType.info);
        expect(toasts[1].message, 'second');
        expect(toasts[0].id, lessThan(toasts[1].id));

        async.elapse(const Duration(seconds: 10));
        container.dispose();
      });
    });

    test('dedupes an identical message+type while it is still active', () {
      FakeAsync().run((async) {
        final container = makeContainer();
        final messenger = container.read(appMessengerProvider.notifier);

        messenger.show('hello');
        messenger.show('hello');
        expect(container.read(appMessengerProvider), hasLength(1));

        messenger.show('hello', type: ToastType.error);
        expect(container.read(appMessengerProvider), hasLength(2));

        async.elapse(const Duration(seconds: 10));
        container.dispose();
      });
    });

    test('allows the same message again after the original was dismissed', () {
      FakeAsync().run((async) {
        final container = makeContainer();
        final messenger = container.read(appMessengerProvider.notifier);

        messenger.show('hello');
        final first = container.read(appMessengerProvider).single;
        messenger.dismiss(first.id);
        expect(container.read(appMessengerProvider), isEmpty);

        messenger.show('hello');
        expect(container.read(appMessengerProvider), hasLength(1));

        async.elapse(const Duration(seconds: 10));
        container.dispose();
      });
    });

    test('caps the active queue at three, dropping the oldest', () {
      FakeAsync().run((async) {
        final container = makeContainer();
        final messenger = container.read(appMessengerProvider.notifier);

        messenger.show('a');
        messenger.show('b');
        messenger.show('c');
        messenger.show('d');

        final toasts = container.read(appMessengerProvider);
        expect(toasts, hasLength(3));
        expect(toasts.map((t) => t.message).toList(), ['b', 'c', 'd']);

        async.elapse(const Duration(seconds: 10));
        container.dispose();
      });
    });
  });

  group('AppMessenger.dismiss', () {
    test('removes the toast with the given id', () {
      FakeAsync().run((async) {
        final container = makeContainer();
        final messenger = container.read(appMessengerProvider.notifier);

        messenger.show('one');
        messenger.show('two');

        final toasts = container.read(appMessengerProvider);
        messenger.dismiss(toasts.first.id);

        final remaining = container.read(appMessengerProvider);
        expect(remaining, hasLength(1));
        expect(remaining.single.message, 'two');

        async.elapse(const Duration(seconds: 10));
        container.dispose();
      });
    });
  });

  group('auto-dismiss', () {
    test('info toasts auto-dismiss after 4 seconds', () {
      FakeAsync().run((async) {
        final container = makeContainer();
        final messenger = container.read(appMessengerProvider.notifier);

        messenger.show('ping');
        async.elapse(const Duration(milliseconds: 3999));
        expect(container.read(appMessengerProvider), hasLength(1));

        async.elapse(const Duration(milliseconds: 2));
        expect(container.read(appMessengerProvider), isEmpty);

        container.dispose();
      });
    });

    test('success toasts auto-dismiss after 4 seconds', () {
      FakeAsync().run((async) {
        final container = makeContainer();
        final messenger = container.read(appMessengerProvider.notifier);

        messenger.show('done', type: ToastType.success);
        async.elapse(const Duration(milliseconds: 3999));
        expect(container.read(appMessengerProvider), hasLength(1));

        async.elapse(const Duration(milliseconds: 2));
        expect(container.read(appMessengerProvider), isEmpty);

        container.dispose();
      });
    });

    test('error toasts auto-dismiss after 6 seconds', () {
      FakeAsync().run((async) {
        final container = makeContainer();
        final messenger = container.read(appMessengerProvider.notifier);

        messenger.show('oops', type: ToastType.error);
        async.elapse(const Duration(seconds: 5));
        expect(container.read(appMessengerProvider), hasLength(1));

        async.elapse(const Duration(seconds: 1));
        expect(container.read(appMessengerProvider), isEmpty);

        container.dispose();
      });
    });
  });

  group('dispose', () {
    test('cancels pending auto-dismiss timers', () {
      FakeAsync().run((async) {
        final container = makeContainer();
        final messenger = container.read(appMessengerProvider.notifier);

        messenger.show('sticky');
        expect(async.pendingTimers, isNotEmpty);

        container.dispose();
        expect(async.pendingTimers, isEmpty);
      });
    });
  });
}
