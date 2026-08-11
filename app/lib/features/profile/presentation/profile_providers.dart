import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/user_profile.dart';

export '../domain/user_profile.dart';

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final session = ref.watch(sessionProvider);
  final config = ref.watch(appConfigProvider);

  if (session == null) {
    return const UserProfile(
      id: 'guest',
      anonymousIdentity: 'guest_anon',
      anonId: 'guest_anon',
      isGuest: true,
    );
  }

  if (config.useMockAuth) {
    return UserProfile(
      id: session.userId,
      phone: '+919876543210',
      email: null,
      anonymousIdentity: session.anonId ?? 'anon_mock_123',
      anonId: session.anonId ?? 'anon_mock_123',
      isGuest: session.isGuest,
      issuesCount: session.isGuest ? 0 : 3,
      upvotesCount: session.isGuest ? 0 : 12,
      quorumVotesCount: session.isGuest ? 0 : 5,
    );
  }

  final client = ref.watch(apiClientProvider);
  final data = await client.getJson('/auth/me');
  return UserProfile.fromJson(data as Map<String, dynamic>);
});
