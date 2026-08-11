import 'dart:convert';

import '../../../core/storage/local_store.dart';
import '../domain/compose_draft.dart';
import '../domain/draft_store.dart';

class HiveDraftStore implements DraftStore {
  HiveDraftStore(this._store);

  final LocalStore _store;

  @override
  Future<void> save(ComposeDraft draft) async {
    await _store.saveDraft(jsonEncode(draft.toJson()));
  }

  @override
  Future<void> clear() async {
    await _store.clearDraft();
  }
}
