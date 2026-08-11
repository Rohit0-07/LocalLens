import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/compose/presentation/compose_providers.dart';
import '../feedback/app_messenger.dart';
import 'connectivity.dart';

class OfflineSyncWorker extends ConsumerStatefulWidget {
  const OfflineSyncWorker({super.key});

  @override
  ConsumerState<OfflineSyncWorker> createState() => _OfflineSyncWorkerState();
}

class _OfflineSyncWorkerState extends ConsumerState<OfflineSyncWorker> {
  NetworkStatus? _lastKnownStatus;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<NetworkStatus>>(networkStatusProvider, (previous, next) {
      final prevStatus = previous?.valueOrNull ?? _lastKnownStatus;
      final currentStatus = next.valueOrNull;

      if (prevStatus == NetworkStatus.offline &&
          currentStatus == NetworkStatus.online) {
        _triggerOutboxSync();
      }

      if (currentStatus != null) {
        _lastKnownStatus = currentStatus;
      }
    });

    return const SizedBox.shrink();
  }

  Future<void> _triggerOutboxSync() async {
    ref.read(appMessengerProvider.notifier).show(
          'Back online — synchronizing outbox queue',
          type: ToastType.info,
        );

    try {
      final outbox = ref.read(offlineOutboxProvider);
      await outbox.flush();
    } catch (_) {
      // Ignored or logged by queue failure handler
    }
  }
}
