import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_providers.dart';
import '../../domain/session.dart';

export '../auth_providers.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  Future<void> signIn(Session session) async {
    await _ref.read(sessionProvider.notifier).signIn(session);
  }

  Future<void> signOut() async {
    await _ref.read(sessionProvider.notifier).signOut();
  }
}
