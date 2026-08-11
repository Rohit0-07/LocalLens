import '../domain/compose_draft.dart';

abstract interface class DraftStore {
  Future<void> save(ComposeDraft draft);

  Future<void> clear();
}
