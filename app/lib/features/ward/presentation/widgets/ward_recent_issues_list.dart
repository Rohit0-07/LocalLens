import 'package:flutter/material.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../feed/domain/issue.dart';
import '../../../feed/presentation/widgets/issue_card.dart';

class WardRecentIssuesList extends StatelessWidget {
  const WardRecentIssuesList({
    super.key,
    required this.issues,
    this.showHeader = true,
    this.emptyMessage,
  });

  final List<Issue> issues;

  /// Whether to render the "recent issues" header. The ward detail page
  /// renders its own search + filter header and passes `false`.
  final bool showHeader;

  /// Optional override for the empty-state message (shown when [issues] is
  /// empty and [showHeader] is still rendering its own content).
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('wardRecentIssuesList'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text(
            context.tr('ward_recent_issues_header'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (issues.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(emptyMessage ?? context.tr('ward_no_recent_issues')),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: issues.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),

            itemBuilder: (context, index) {
              return IssueCard(issue: issues[index]);
            },
          ),
      ],
    );
  }
}
