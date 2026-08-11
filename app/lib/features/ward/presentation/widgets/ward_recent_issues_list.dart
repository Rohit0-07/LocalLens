import 'package:flutter/material.dart';
import '../../../feed/domain/issue.dart';
import '../../../feed/presentation/widgets/issue_card.dart';

class WardRecentIssuesList extends StatelessWidget {
  const WardRecentIssuesList({super.key, required this.issues});

  final List<Issue> issues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('wardRecentIssuesList'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Ward Issues',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (issues.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No recent issues reported in this ward.'),
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
