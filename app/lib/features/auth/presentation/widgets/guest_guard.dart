import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';

class GuestGuard extends StatelessWidget {
  const GuestGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sign in required'),
      content: const Text(
        'Create an account or sign in to participate in civic reporting.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go(RoutePaths.signIn);
              }
            });
          },
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}
