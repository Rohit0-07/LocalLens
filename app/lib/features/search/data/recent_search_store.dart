import 'dart:convert';

import '../../../core/storage/local_store.dart';

abstract interface class RecentSearchStore {
  List<String> load();

  Future<void> add(String query);

  Future<void> clear();
}

class HiveRecentSearchStore implements RecentSearchStore {
  HiveRecentSearchStore(this._store);

  static const _key = 'recent_searches';
  static const _maxEntries = 5;

  final LocalStore _store;

  @override
  List<String> load() {
    final raw = _store.getString(_key);
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<String>().toList();
    } on FormatException {
      return const <String>[];
    }
  }

  @override
  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final items = load();
    items.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    items.insert(0, trimmed);
    if (items.length > _maxEntries) {
      items.removeRange(_maxEntries, items.length);
    }
    await _store.setString(_key, jsonEncode(items));
  }

  @override
  Future<void> clear() async {
    await _store.setString(_key, jsonEncode(<String>[]));
  }
}