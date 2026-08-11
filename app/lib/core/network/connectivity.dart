import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

abstract class ConnectivitySource {
  Stream<NetworkStatus> get statuses;
}

class PluginConnectivitySource implements ConnectivitySource {
  @override
  Stream<NetworkStatus> get statuses =>
      Connectivity().onConnectivityChanged.map((results) {
        if (results.isEmpty) {
          return NetworkStatus.offline;
        }
        return results.contains(ConnectivityResult.none)
            ? NetworkStatus.offline
            : NetworkStatus.online;
      });
}

final connectivitySourceProvider = Provider<ConnectivitySource>(
  (ref) => PluginConnectivitySource(),
);

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final source = ref.watch(connectivitySourceProvider);
  return source.statuses;
});
