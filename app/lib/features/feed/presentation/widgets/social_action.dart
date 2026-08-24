import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../issue_detail/data/issue_detail_api.dart';
import '../../../issue_detail/presentation/controllers/issue_detail_controller.dart';

/// Icon + label tap target used in the footer action row of feed cards
/// (like / comment / share). Shared by IssueCard and WinCard.
class SocialAction extends StatelessWidget {
  const SocialAction({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final Widget label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      enabled: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 5),
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  child: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Comment count for an issue, shown next to the comment action.
///
/// Prefers the server-provided `comments_count` (which includes replies).
/// When no server count is available (e.g. win cards), falls back to counting
/// the loaded comment tree so replies are included there as well.
class CommentCount extends ConsumerWidget {
  const CommentCount({super.key, required this.issueId, this.count});

  final int issueId;

  /// Server-provided total from `Issue.commentsCount`, when available.
  final int? count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved =
        count ?? _treeTotal(ref.watch(commentsProvider(issueId)));
    return Text('$resolved');
  }

  int _treeTotal(AsyncValue<List<Comment>> asyncComments) {
    final comments = asyncComments.asData?.value;
    if (comments == null) return 0;
    var total = 0;
    void walk(List<Comment> list) {
      for (final c in list) {
        total++;
        walk(c.replies);
      }
    }

    walk(comments);
    return total;
  }
}
