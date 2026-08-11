import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../domain/gamification_models.dart';

class GamificationApi {
  GamificationApi(this._client);

  final ApiClient _client;
  static const String _cacheKey = 'gamification_cache';

  Future<GamificationProfile> getProfile() async {
    try {
      final data = await _client.getJson('/gamification/me');
      final profile = GamificationProfile.fromJson(data as Map<String, dynamic>);
      await cacheProfile(profile);
      return profile;
    } catch (_) {
      final cached = await getCachedProfile();
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<StreakClaimResult> claimDailyStreak() async {
    final data = await _client.postJson('/gamification/claim-daily-streak');
    final result = StreakClaimResult.fromJson(data as Map<String, dynamic>);
    try {
      await getProfile();
    } catch (_) {}
    return result;
  }

  Future<List<BadgeMetadata>> getBadges() async {
    final data = await _client.getJson('/gamification/badges');
    final list = data as List<dynamic>;
    return list
        .map((e) => BadgeMetadata.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GamificationProfile?> getCachedProfile() async {
    try {
      String? jsonStr;
      if (Hive.isBoxOpen(_cacheKey)) {
        jsonStr = Hive.box<String>(_cacheKey).get(_cacheKey);
      } else {
        try {
          final box = await Hive.openBox<String>(_cacheKey);
          jsonStr = box.get(_cacheKey);
        } catch (_) {
          jsonStr = LocalStore.instance.getString(_cacheKey);
        }
      }
      if (jsonStr == null || jsonStr.isEmpty) {
        jsonStr = LocalStore.instance.getString(_cacheKey);
      }
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return GamificationProfile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<void> cacheProfile(GamificationProfile profile) async {
    try {
      final jsonStr = jsonEncode(profile.toJson());
      await LocalStore.instance.setString(_cacheKey, jsonStr);
      if (Hive.isBoxOpen(_cacheKey)) {
        await Hive.box<String>(_cacheKey).put(_cacheKey, jsonStr);
      } else {
        try {
          final box = await Hive.openBox<String>(_cacheKey);
          await box.put(_cacheKey, jsonStr);
        } catch (_) {}
      }
    } catch (_) {}
  }
}
