import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/repositories/rep_dashboard_repository.dart';
import '../domain/official_response.dart';
import '../domain/public_representative_profile.dart';
import '../domain/representative_profile.dart';
import '../domain/ward_issues_response.dart';

final repDashboardRepositoryProvider = Provider<RepDashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localStore = ref.watch(localStoreProvider);
  return RepDashboardRepository(apiClient, localStore);
});

final repProfileProvider = FutureProvider<RepresentativeProfile>((ref) async {
  final repository = ref.watch(repDashboardRepositoryProvider);
  return repository.fetchRepresentativeProfile();
});

/// Public rep performance profile keyed by user id.
///
/// Returns `null` for non-representatives (404) and for `userId <= 0`, so
/// widgets can render header-only without crashing.
final publicRepProfileProvider =
    FutureProvider.family<PublicRepresentativeProfile?, int>((ref, userId) async {
  if (userId <= 0) return null;
  return ref.watch(repDashboardRepositoryProvider).fetchPublicRepByUser(userId);
});

final wardIssuesFilterProvider = StateProvider<String>((ref) => 'all');

final wardIssuesProvider = FutureProvider.family<WardIssuesResponse, String>((ref, filter) async {
  final repository = ref.watch(repDashboardRepositoryProvider);
  return repository.fetchWardIssues(filter: filter);
});

final officialResponsesProvider = FutureProvider.family<List<OfficialResponse>, int>((ref, issueId) async {
  final repository = ref.watch(repDashboardRepositoryProvider);
  return repository.fetchOfficialResponses(issueId);
});

class RepDashboardNotifier extends StateNotifier<AsyncValue<void>> {
  RepDashboardNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  final RepDashboardRepository _repository;
  final Ref _ref;

  Future<void> postOfficialResponse({
    required int issueId,
    required String message,
    int? estimatedResolutionDays,
    String? statusUpdate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.postOfficialResponse(
        issueId: issueId,
        message: message,
        estimatedResolutionDays: estimatedResolutionDays,
        statusUpdate: statusUpdate,
      );
      _ref.invalidate(repProfileProvider);
      _ref.invalidate(wardIssuesProvider);
      _ref.invalidate(officialResponsesProvider(issueId));
    });
  }
}

final repDashboardNotifierProvider =
    StateNotifierProvider<RepDashboardNotifier, AsyncValue<void>>((ref) {
  return RepDashboardNotifier(ref.watch(repDashboardRepositoryProvider), ref);
});
