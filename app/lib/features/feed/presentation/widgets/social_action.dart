import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Live comment count for an issue, shown next to the comment action.
class CommentCount extends ConsumerWidget {
  const CommentCount({super.key, required this.issueId});

  final int issueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncComments = ref.watch(commentsProvider(issueId));
    final count = asyncComments.asData?.value.length ?? 0;
    return Text('$count');
  }
}
