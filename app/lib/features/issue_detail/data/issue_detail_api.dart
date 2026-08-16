import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';

class Comment {
  final dynamic id;
  final int issueId;
  final dynamic parentId;
  final String anonId;
  final String content;
  final DateTime createdAt;
  final bool isAuthor;
  final List<Comment> replies;
  final int? userId;

  const Comment({
    required this.id,
    required this.issueId,
    this.parentId,
    required this.anonId,
    required this.content,
    required this.createdAt,
    required this.isAuthor,
    this.replies = const [],
    this.userId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      issueId: json['issue_id'] is int
          ? json['issue_id'] as int
          : int.parse(json['issue_id'].toString()),
      parentId: json['parent_id'],
      anonId: json['anon_id'] as String? ?? 'anon_user',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isAuthor: json['is_author'] as bool? ?? false,
      userId: (json['user_id'] ?? json['author_id'] as num?)?.toInt(),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_id': issueId,
      'parent_id': parentId,
      'anon_id': anonId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_author': isAuthor,
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }

  Comment copyWith({
    dynamic id,
    int? issueId,
    dynamic parentId,
    String? anonId,
    String? content,
    DateTime? createdAt,
    bool? isAuthor,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      issueId: issueId ?? this.issueId,
      parentId: parentId ?? this.parentId,
      anonId: anonId ?? this.anonId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isAuthor: isAuthor ?? this.isAuthor,
      replies: replies ?? this.replies,
    );
  }
}

final issueDetailApiProvider = Provider<IssueDetailApi>((ref) {
  return IssueDetailApi(ref.watch(apiClientProvider));
});

class IssueDetailApi {
  IssueDetailApi(this._client);
  final ApiClient _client;

  Future<List<Comment>> getComments(int issueId) async {
    final data = await _client.getJson('/issues/$issueId/comments');
    final list = data as List<dynamic>;
    return list
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Comment> postComment(int issueId, String content, {dynamic parentId}) async {
    final data = await _client.postJson(
      '/issues/$issueId/comments',
      body: {
        'content': content,
        if (parentId != null) 'parent_id': parentId.toString(),
      },
    );
    return Comment.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteComment(int issueId, dynamic commentId) async {
    await _client.postJson('/issues/$issueId/comments/$commentId/delete');
  }
}
