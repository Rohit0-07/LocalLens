import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/offline_sync_worker.dart';
import 'error_boundary.dart';
import 'offline_banner.dart';
import 'toast_overlay.dart';

class AppInfrastructure extends ConsumerWidget {
  const AppInfrastructure({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const OfflineSyncWorker(),
        Positioned.fill(child: ErrorBoundary(child: child)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [OfflineBanner(), ToastOverlay()],
            ),
          ),
        ),
      ],
    );
  }
}
