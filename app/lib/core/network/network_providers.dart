import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config_provider.dart';
import '../feedback/app_messenger.dart';
import '../storage/storage_providers.dart';
import '../../features/auth/presentation/auth_providers.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final store = ref.watch(localStoreProvider);
  return ApiClient(
    baseUrl: config.apiBaseUrl,
    accessTokenProvider: store.restoreAccessToken,
    onUnauthorized: () {
      ref.read(sessionProvider.notifier).signOut();
      ref.read(appMessengerProvider.notifier).show(
        'Your session expired. Please sign in again.',
      );
    },
  );
});
