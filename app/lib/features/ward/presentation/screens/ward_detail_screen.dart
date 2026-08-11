import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ward_providers.dart';
import '../widgets/ward_hero_banner.dart';
import '../widgets/ward_metric_card.dart';
import '../widgets/ward_recent_issues_list.dart';
import '../widgets/ward_rep_card.dart';

class WardDetailScreen extends ConsumerWidget {
  const WardDetailScreen({super.key, required this.wardSlug});

  final String wardSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final theme = Theme.of(context);
    final asyncDetail = ref.watch(wardDetailNotifierProvider(wardSlug));

    return Scaffold(
      key: const Key('wardDetailScreen'),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('wardDetailBackButton'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Ward Details'),
      ),
      body: asyncDetail.when(
        data: (wardDetail) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WardHeroBanner(wardDetail: wardDetail),
                const SizedBox(height: 16),
                WardMetricsGrid(wardDetail: wardDetail),
                if (wardDetail.assignedRepresentative != null) ...[
                  const SizedBox(height: 16),
                  WardRepCard(representative: wardDetail.assignedRepresentative!),
                ],
                const SizedBox(height: 16),
                WardRecentIssuesList(issues: wardDetail.recentIssues),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          final errorMsg = error is StateError ? error.message : error.toString();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    errorMsg.contains('Ward not found') ? 'Ward not found' : errorMsg,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
