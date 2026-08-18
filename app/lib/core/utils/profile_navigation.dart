import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../router/route_paths.dart';

/// Opens the correct profile page for a reporter: the signed-in user's own
/// profile tab when [reporterId] matches the current session, otherwise their
/// public profile page. If [reporterId] is null (anonymous), shows a privacy notice.
void openReporterProfile(
  BuildContext context,
  WidgetRef ref,
  int? reporterId,
) {
  if (reporterId == null) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This post is anonymous to safeguard citizen privacy & safety.',
        ),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  final session = ref.read(sessionProvider);
  final isSelf = session != null &&
      !session.isGuest &&
      session.userId is int &&
      session.userId == reporterId;
  if (isSelf) {
    context.go(RoutePaths.profile);
  } else {
    context.push(RoutePaths.publicProfileFor(reporterId));
  }
}