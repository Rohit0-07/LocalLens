import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({super.key, required this.child});

  final Widget child;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  @override
  void initState() {
    super.initState();
    _installHandler();
  }

  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    _installHandler();
  }

  void _installHandler() {
    final previous = ErrorWidget.builder;
    ErrorWidget.builder = (details) {
      if (kDebugMode) {
        debugPrint('ErrorBoundary caught: ${details.exception}');
      }
      return const SafeFallback();
    };
    _previous = previous;
  }

  late ErrorWidgetBuilder _previous;

  @override
  void dispose() {
    ErrorWidget.builder = _previous;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class SafeFallback extends StatelessWidget {
  const SafeFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
