import '../domain/compose_draft.dart';

abstract interface class DraftStore {
  Future<void> save(ComposeDraft draft);

  Future<void> clear();

  List<ComposeDraft> loadAll();

  Future<void> saveItem(ComposeDraft draft);

  Future<void> deleteItem(String id);
}
