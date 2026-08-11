import 'dart:convert';
import '../../../core/storage/local_store.dart';
import '../../feed/domain/feed_repository.dart';
import '../domain/compose_draft.dart';

class OfflineOutboxQueue {
  OfflineOutboxQueue(this._localStore, this._feedRepository);

  final LocalStore _localStore;
  final FeedRepository _feedRepository;

  static const String _outboxKey = 'locallens_outbox_queue_v1';

  int get pendingCount => getPendingQueue().length;

  List<ComposeDraft> getPendingQueue() {
    final raw = _localStore.getString(_outboxKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => ComposeDraft.fromJson(item as Map<String, Object?>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> enqueue(ComposeDraft draft) async {
    final queue = getPendingQueue();
    queue.add(draft);
    await _saveQueue(queue);
  }

  Future<void> removeAt(int index) async {
    final queue = getPendingQueue();
    if (index < 0 || index >= queue.length) return;
    queue.removeAt(index);
    await _saveQueue(queue);
  }

  Future<void> removeAll() async {
    await _saveQueue([]);
  }

  Future<void> _saveQueue(List<ComposeDraft> queue) async {
    final raw = jsonEncode(queue.map((d) => d.toJson()).toList());
    await _localStore.setString(_outboxKey, raw);
  }

  Future<int> flush() async {
    final queue = getPendingQueue();
    if (queue.isEmpty) return 0;

    int successCount = 0;
    final remaining = <ComposeDraft>[];

    for (final draft in queue) {
      try {
        await _feedRepository.createIssue(
          title: draft.title,
          description: draft.description,
          category: draft.category,
          latitude: draft.latitude ?? 19.1136,
          longitude: draft.longitude ?? 72.8697,
          isAnonymous: draft.isAnonymous,
          isFuzzed: draft.isFuzzed,
          isShielded: draft.isShielded,
        );
        successCount++;
      } catch (_) {
        remaining.add(draft);
      }
    }

    await _saveQueue(remaining);
    return successCount;
  }
}
