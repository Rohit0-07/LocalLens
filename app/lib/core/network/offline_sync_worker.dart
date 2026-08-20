import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/compose/presentation/compose_providers.dart';
import '../../features/feed/presentation/feed_providers.dart';
import '../../features/map/presentation/controllers/map_controller.dart';
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

      // Sync on app start when already online (no flap) and on every
      // offline -> online recovery, so a failed publish is retried.
      final isInitialOnline =
          _lastKnownStatus == null && currentStatus == NetworkStatus.online;
      final recovered = prevStatus == NetworkStatus.offline &&
          currentStatus == NetworkStatus.online;
      if (currentStatus != null) {
        _lastKnownStatus = currentStatus;
      }
      if (isInitialOnline || recovered) {
        _triggerOutboxSync();
      }
    });

    return const SizedBox.shrink();
  }

  Future<void> _triggerOutboxSync() async {
    try {
      final outbox = ref.read(offlineOutboxProvider);
      final synced = await outbox.flush();
      if (synced > 0) {
        ref.invalidate(multiTypeFeedProvider);
        ref.invalidate(mapPinsNotifierProvider);
        if (mounted) {
          ref.read(appMessengerProvider.notifier).show(
                'Back online — $synced report(s) published',
                type: ToastType.success,
              );
        }
      } else {
        if (mounted) {
          ref.read(appMessengerProvider.notifier).show(
                'Back online — synchronizing outbox queue',
                type: ToastType.info,
              );
        }
      }
    } catch (_) {
      // Ignored or logged by queue failure handler
    }
  }
}