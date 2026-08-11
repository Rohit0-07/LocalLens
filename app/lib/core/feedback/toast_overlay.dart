import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_messenger.dart';

class ToastOverlay extends ConsumerWidget {
  const ToastOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(appMessengerProvider);
    if (toasts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final toast in toasts) _ToastCard(toast: toast)],
      ),
    );
  }
}

class _ToastCard extends ConsumerWidget {
  const _ToastCard({required this.toast});

  final ToastMessage toast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final background = switch (toast.type) {
      ToastType.error => scheme.errorContainer,
      ToastType.success => scheme.secondaryContainer,
      ToastType.info => scheme.surfaceContainerHigh,
    };
    final foreground = switch (toast.type) {
      ToastType.error => scheme.onErrorContainer,
      ToastType.success => scheme.onSecondaryContainer,
      ToastType.info => scheme.onSurface,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              ref.read(appMessengerProvider.notifier).dismiss(toast.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  switch (toast.type) {
                    ToastType.error => Icons.error_outline,
                    ToastType.success => Icons.check_circle_outline,
                    ToastType.info => Icons.info_outline,
                  },
                  size: 20,
                  color: foreground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    toast.message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
