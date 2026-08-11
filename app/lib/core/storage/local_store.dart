import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
export 'storage_providers.dart';


class LocalStore {
  LocalStore._();

  static final instance = LocalStore._();

  static const _sessionBoxName = 'session';
  static const _draftsBoxName = 'drafts';
  static const _repCacheBoxName = 'rep_cache';
  static const _flaggedIssuesBoxName = 'flagged_issues';
  static const _wardCacheBoxName = 'ward_cache';
  static const _tokenKey = 'access_token';
  static const _userIdKey = 'user_id';
  static const _draftKey = 'current_draft';
  static const _hasCompletedOnboardingKey = 'has_completed_onboarding';

  Box<String>? _sessionBox;
  Box<String>? _draftsBox;
  Box<String>? _repCacheBox;
  Box<String>? _flaggedIssuesBox;
  Box<String>? _wardCacheBox;

  bool hasCompletedOnboarding() {
    if (_sessionBox == null) return true;
    return _sessionBox?.get(_hasCompletedOnboardingKey) == 'true';
  }

  Future<void> setCompletedOnboarding([bool completed = true]) async {
    await _sessionBox?.put(
      _hasCompletedOnboardingKey,
      completed ? 'true' : 'false',
    );
  }

  Future<void> init() async {
    await Hive.initFlutter();
    _sessionBox = await Hive.openBox<String>(_sessionBoxName);
    _draftsBox = await Hive.openBox<String>(_draftsBoxName);
    _repCacheBox = await Hive.openBox<String>(_repCacheBoxName);
    _flaggedIssuesBox = await Hive.openBox<String>(_flaggedIssuesBoxName);
    _wardCacheBox = await Hive.openBox<String>(_wardCacheBoxName);
  }


  String? restoreAccessToken() => _sessionBox?.get(_tokenKey);

  String? restoreUserId() => _sessionBox?.get(_userIdKey);

  Future<void> saveSession({
    required String accessToken,
    required Object userId,
  }) async {
    await _sessionBox?.put(_tokenKey, accessToken);
    await _sessionBox?.put(_userIdKey, userId.toString());
  }

  Future<void> clearSession() async {
    await _sessionBox?.delete(_tokenKey);
    await _sessionBox?.delete(_userIdKey);
  }

  String? loadDraft() => _draftsBox?.get(_draftKey);

  Future<void> saveDraft(String json) async {
    await _draftsBox?.put(_draftKey, json);
  }

  Future<void> clearDraft() async {
    await _draftsBox?.delete(_draftKey);
  }

  String? loadOutbox() => _draftsBox?.get('pending_outbox');

  Future<void> saveOutbox(String json) async {
    await _draftsBox?.put('pending_outbox', json);
  }

  String? getString(String key) {
    if (key == 'rep_profile') {
      return _repCacheBox?.get(key) ?? _draftsBox?.get(key);
    }
    return _draftsBox?.get(key);
  }

  Future<void> setString(String key, String value) async {
    if (key == 'rep_profile') {
      await _repCacheBox?.put(key, value);
      await _draftsBox?.put(key, value);
    } else {
      await _draftsBox?.put(key, value);
    }
  }

  Set<int> getFlaggedIssueIds() {
    final raw = _flaggedIssuesBox?.get('user_flagged_issue_ids') ?? _draftsBox?.get('user_flagged_issue_ids');
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded.containsKey('flagged_issue_ids')) {
        final list = (decoded['flagged_issue_ids'] as List).cast<int>();
        return list.toSet();
      } else if (decoded is List) {
        return decoded.cast<int>().toSet();
      }
    } catch (_) {}
    return {};
  }

  Future<void> addFlaggedIssueId(int issueId) async {
    final current = getFlaggedIssueIds();
    current.add(issueId);
    final payload = jsonEncode({
      'flagged_issue_ids': current.toList(),
      'last_updated': DateTime.now().toIso8601String(),
    });
    await _flaggedIssuesBox?.put('user_flagged_issue_ids', payload);
    await _draftsBox?.put('user_flagged_issue_ids', payload);
  }

  bool isIssueFlaggedLocally(int issueId) {
    return getFlaggedIssueIds().contains(issueId);
  }

  String? getWardDetailCache(String slug) {
    return _wardCacheBox?.get('ward_detail_$slug') ?? _draftsBox?.get('ward_detail_$slug');
  }

  Future<void> saveWardDetailCache(String slug, String jsonStr) async {
    await _wardCacheBox?.put('ward_detail_$slug', jsonStr);
    await _draftsBox?.put('ward_detail_$slug', jsonStr);
  }
}


