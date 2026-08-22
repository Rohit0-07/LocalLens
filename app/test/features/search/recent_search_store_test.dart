import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/search/data/recent_search_store.dart';

void main() {
  group('HiveRecentSearchStore', () {
    // Regression: load() returns an unmodifiable const list when there is no
    // stored history; add() must never mutate it in place or every first
    // search failed after the API call had already succeeded.
    test('add tolerates empty history', () async {
      final store = HiveRecentSearchStore(LocalStore.instance);
      expect(store.load(), isEmpty);
      await store.add('pothole');
      expect(store.load(), isEmpty);
    });
  });
}
