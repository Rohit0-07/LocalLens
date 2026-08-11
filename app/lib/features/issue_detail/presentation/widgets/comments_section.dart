import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../../../auth/presentation/widgets/guest_guard.dart';
import '../../../core/l10n/app_strings.dart';
import '../../data/issue_detail_api.dart';
import '../controllers/issue_detail_controller.dart';
import 'comment_card.dart';

class CommentsSection extends ConsumerStatefulWidget {
  final int issueId;
  final List<Comment> initialComments;
  final bool isGuest;
  final Function(String content, dynamic parentId)? onPostComment;
  final Function(dynamic commentId)? onDeleteComment;

  const CommentsSection({
    super.key,
    required this.issueId,
    this.initialComments = const [],
    this.isGuest = false,
    this.onPostComment,
    this.onDeleteComment,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  late List<Comment> _comments;
  final TextEditingController _controller = TextEditingController();
  Comment? _replyingTo;
  final FocusNode _composerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.initialComments);
  }

  @override
  void didUpdateWidget(covariant CommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialComments != oldWidget.initialComments &&
        widget.initialComments.isNotEmpty) {
      _comments = List.from(widget.initialComments);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  bool _checkIsGuest() {
    final session = ref.read(sessionProvider);
    return widget.isGuest || (session == null || session.isGuest);
  }

  void _handleInteraction(VoidCallback action) {
    if (_checkIsGuest()) {
      showDialog(context: context, builder: (_) => const GuestGuard());
    } else {
      action();
    }
  }

  void _submitComment() {
    _handleInteraction(() {
      final text = _controller.text.trim();
      if (text.isEmpty) return;

      if (widget.onPostComment != null) {
        widget.onPostComment!(text, _replyingTo?.id);
      } else {
        ref
            .read(commentsProvider(widget.issueId).notifier)
            .postComment(text, parentId: _replyingTo?.id);
      }

      final newComment = Comment(
        id: DateTime.now().microsecondsSinceEpoch,
        issueId: widget.issueId,
        parentId: _replyingTo?.id,
        anonId: 'anon_current',
        content: text,
        createdAt: DateTime.now(),
        isAuthor: true,
      );

      setState(() {
        final target = _replyingTo;
        if (target != null) {
          _appendReply(target, newComment);
        } else {
          _comments.add(newComment);
        }
        _controller.clear();
        _replyingTo = null;
        _composerFocus.unfocus();
      });
    });
  }

  void _appendReply(Comment target, Comment reply) {
    bool found = false;
    void walk(List<Comment> list) {
      for (var i = 0; i < list.length; i++) {
        final c = list[i];
        if (c.id == target.id) {
          list[i] = c.copyWith(replies: [...c.replies, reply]);
          found = true;
          return;
        }
        if (c.replies.isNotEmpty) walk(c.replies);
      }
    }

    walk(_comments);
    if (!found) _comments.add(reply);
  }

  void _deleteComment(dynamic commentId) {
    _handleInteraction(() {
      if (widget.onDeleteComment != null) {
        widget.onDeleteComment!(commentId);
      } else {
        ref
            .read(commentsProvider(widget.issueId).notifier)
            .deleteComment(commentId);
      }
      setState(() {
        _comments.removeWhere((c) => c.id == commentId);
      });
    });
  }

  void _startReply(Comment target) {
    _handleInteraction(() {
      setState(() => _replyingTo = target);
      _composerFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asyncComments = ref.watch(commentsProvider(widget.issueId));

    final commentsToDisplay = widget.initialComments.isNotEmpty
        ? _comments
        : (asyncComments.asData?.value ?? _comments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.forum_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                context.tr('comments_title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${commentsToDisplay.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (commentsToDisplay.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                context.tr('comments_empty'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...commentsToDisplay.map(
            (comment) => CommentCard(
              comment: comment,
              onReply: _startReply,
              onDelete: _deleteComment,
            ),
          ),
        const Divider(height: 24),
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            color: colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Icon(Icons.reply, size: 15, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${context.tr('comments_replying_to')} ${_replyingTo!.anonId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _replyingTo = null;
                    _controller.clear();
                  }),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('comment_input'),
                  controller: _controller,
                  focusNode: _composerFocus,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: context.tr('comments_hint'),
                    isDense: true,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('submit_comment_button'),
                icon: const Icon(Icons.send_rounded, size: 20),
                onPressed: _submitComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.controller,
    required this.focusNode,
    required this.onCancel,
    required this.onSubmit,
    required this.targetLabel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String targetLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const Key('inlineReplyComposer'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply, size: 15, color: colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${context.tr('comments_replying_to')} $targetLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                icon: const Icon(Icons.close),
                onPressed: onCancel,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: context.tr('comments_hint'),
                    isDense: true,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: onSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}