import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/network/connectivity.dart';

class FakeConnectivitySource implements ConnectivitySource {
  final _controller = StreamController<NetworkStatus>.broadcast();

  @override
  Stream<NetworkStatus> get statuses => _controller.stream;

  void emit(NetworkStatus status) => _controller.add(status);

  Future<void> close() => _controller.close();
}

void main() {
  test(
    'networkStatusProvider follows the source from offline to online',
    () async {
      final source = FakeConnectivitySource();
      addTearDown(source.close);

      final container = ProviderContainer(
        overrides: [connectivitySourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);

      final subscription = container.listen<AsyncValue<NetworkStatus>>(
        networkStatusProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      await pumpEventQueue();

      source.emit(NetworkStatus.offline);
      await pumpEventQueue();
      expect(
        container.read(networkStatusProvider).value,
        NetworkStatus.offline,
      );

      source.emit(NetworkStatus.online);
      await pumpEventQueue();
      expect(container.read(networkStatusProvider).value, NetworkStatus.online);
    },
  );

  test(
    'networkStatusProvider uses the overridden ConnectivitySource',
    () async {
      final source = FakeConnectivitySource();
      addTearDown(source.close);

      final container = ProviderContainer(
        overrides: [connectivitySourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);

      final subscription = container.listen<AsyncValue<NetworkStatus>>(
        networkStatusProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      await pumpEventQueue();

      source.emit(NetworkStatus.online);
      await pumpEventQueue();
      expect(container.read(networkStatusProvider).value, NetworkStatus.online);
    },
  );
}
