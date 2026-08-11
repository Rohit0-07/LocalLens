import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/repositories/ward_repository.dart';
import '../../domain/ward_detail_out.dart';
import '../../domain/ward_list_response.dart';

final wardRepositoryProvider = Provider<WardRepository>((ref) {
  return WardRepositoryImpl(ref.watch(apiClientProvider));
});

final wardDetailNotifierProvider =
    FutureProvider.family.autoDispose<WardDetailOut, String>((ref, slug) async {
  final store = ref.read(localStoreProvider);
  final cachedJson = store.getWardDetailCache(slug);
  WardDetailOut? cachedDetail;
  if (cachedJson != null) {
    try {
      cachedDetail = WardDetailOut.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
    } catch (_) {}
  }

  final repository = ref.read(wardRepositoryProvider);
  try {
    final freshDetail = await repository.getWardDetail(slug);
    try {
      await store.saveWardDetailCache(slug, jsonEncode(freshDetail.toJson()));
    } catch (_) {}
    return freshDetail;
  } catch (e) {
    if (cachedDetail != null) {
      return cachedDetail;
    }
    rethrow;
  }
});

final wardListNotifierProvider =
    FutureProvider<WardListResponse>((ref) async {
  final repository = ref.read(wardRepositoryProvider);
  return await repository.getWards();
});

