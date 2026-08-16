import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';

class GuestGuard extends StatelessWidget {
  const GuestGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('sign_in_required')),
      content: Text(context.tr('guest_guard_body')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('action_cancel')),
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
          child: Text(context.tr('action_sign_in')),
        ),
      ],
    );
  }
}
