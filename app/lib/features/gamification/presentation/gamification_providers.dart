import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/gamification_api.dart';
import '../domain/gamification_models.dart';

final gamificationApiProvider = Provider<GamificationApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return GamificationApi(client);
});

final gamificationProfileProvider =
    AsyncNotifierProvider<GamificationProfileNotifier, GamificationProfile>(
  GamificationProfileNotifier.new,
);

class GamificationProfileNotifier extends AsyncNotifier<GamificationProfile> {
  @override
  Future<GamificationProfile> build() async {
    final api = ref.watch(gamificationApiProvider);
    return await api.getProfile();
  }

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(gamificationApiProvider);
      return await api.getProfile();
    });
  }
}

final allBadgesProvider = FutureProvider<List<BadgeMetadata>>((ref) async {
  final api = ref.watch(gamificationApiProvider);
  return await api.getBadges();
});

final claimStreakNotifierProvider =
    StateNotifierProvider<ClaimStreakNotifier, AsyncValue<StreakClaimResult?>>((ref) {
  return ClaimStreakNotifier(ref.watch(gamificationApiProvider), ref);
});

class ClaimStreakNotifier extends StateNotifier<AsyncValue<StreakClaimResult?>> {
  final GamificationApi _api;
  final Ref _ref;

  ClaimStreakNotifier(this._api, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> claimStreak() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _api.claimDailyStreak();
      await _ref.read(gamificationProfileProvider.notifier).refreshProfile();
      return result;
    });
  }
}
