import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/auth_api.dart';
import '../data/auth_mock.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockAuth) return AuthMock();
  return AuthApi(ref.watch(apiClientProvider));
});

final sessionProvider = NotifierProvider<SessionController, Session?>(
  SessionController.new,
);

class SessionController extends Notifier<Session?> {
  @override
  Session? build() {
    final store = ref.watch(localStoreProvider);
    final token = store.restoreAccessToken();
    final userId = store.restoreUserId();
    if (token == null || token.isEmpty || userId == null) return null;
    return Session(
      accessToken: token,
      userId: userId,
      isGuest: userId.startsWith('guest'),
    );
  }

  Future<void> signIn(Session session) async {
    await ref
        .read(localStoreProvider)
        .saveSession(accessToken: session.accessToken, userId: session.userId.toString());
    state = session;
  }

  Future<void> signOut() async {
    await ref.read(localStoreProvider).clearSession();
    state = null;
  }
}
