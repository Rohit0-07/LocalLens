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

  @override
  List<ComposeDraft> loadAll() {
    return _store
        .loadAllDrafts()
        .map((raw) {
          try {
            return ComposeDraft.fromJson(
              jsonDecode(raw) as Map<String, Object?>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<ComposeDraft>()
        .toList();
  }

  @override
  Future<void> saveItem(ComposeDraft draft) async {
    final id = draft.id.isNotEmpty
        ? draft.id
        : 'draft_${DateTime.now().microsecondsSinceEpoch}';
    final item = draft.copyWith(id: id);
    await _store.saveDraftItem(id, jsonEncode(item.toJson()));
  }

  @override
  Future<void> deleteItem(String id) async {
    await _store.deleteDraftItem(id);
  }
}
