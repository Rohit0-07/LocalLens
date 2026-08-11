import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/issue_detail_api.dart';

final commentsProvider =
    AsyncNotifierProvider.family<CommentsController, List<Comment>, int>(
  CommentsController.new,
);

class CommentsController extends FamilyAsyncNotifier<List<Comment>, int> {
  @override
  Future<List<Comment>> build(int arg) async {
    final api = ref.watch(issueDetailApiProvider);
    return api.getComments(arg);
  }

  /// Posts a comment and returns the created comment so the UI can
  /// optimistically append the authoritative record (no `anon_current`
  /// placeholder) instead of guessing an id/anonId.
  Future<Comment> postComment(String content, {dynamic parentId}) async {
    final api = ref.read(issueDetailApiProvider);
    final created = await api.postComment(arg, content, parentId: parentId);
    state = await AsyncValue.guard(() => api.getComments(arg));
    return created;
  }

  Future<void> deleteComment(dynamic commentId) async {
    final api = ref.read(issueDetailApiProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await api.deleteComment(arg, commentId);
      return api.getComments(arg);
    });
  }

  Future<void> refresh() async {
    final api = ref.read(issueDetailApiProvider);
    state = await AsyncValue.guard(() => api.getComments(arg));
  }
}
