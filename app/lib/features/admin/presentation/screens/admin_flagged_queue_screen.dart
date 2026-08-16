import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../providers/admin_flagged_queue_provider.dart';

class AdminFlaggedQueueScreen extends StatefulWidget {
  const AdminFlaggedQueueScreen({super.key});

  @override
  State<AdminFlaggedQueueScreen> createState() => _AdminFlaggedQueueScreenState();
}

class _AdminFlaggedQueueScreenState extends State<AdminFlaggedQueueScreen> {
  String selectedFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    final filter = FlaggedQueueFilter(status: selectedFilter);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('admin_queue_title')),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            key: const Key('adminQueueFilterSelect'),
            value: selectedFilter,
            items: [
              DropdownMenuItem(value: 'pending', child: Text(context.tr('admin_status_pending'))),
              DropdownMenuItem(value: 'reviewed', child: Text(context.tr('admin_status_reviewed'))),
              DropdownMenuItem(value: 'dismissed', child: Text(context.tr('admin_status_dismissed'))),
              DropdownMenuItem(value: 'hidden', child: Text(context.tr('admin_status_hidden'))),
              DropdownMenuItem(value: 'all', child: Text(context.tr('admin_status_all'))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedFilter = val;
                });
              }
            },
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final queueAsync = ref.watch(adminFlaggedQueueProvider(filter));
                return queueAsync.when(
                  data: (response) {
                    if (response.items.isEmpty) {
                      return Center(child: Text(context.tr('admin_no_items')));
                    }
                    return ListView.builder(
                      itemCount: response.items.length,
                      itemBuilder: (context, index) {
                        final item = response.items[index];
                        return ListTile(
                          title: Text(item.issueTitle),
                          subtitle: Text(item.issueDescription),
                          trailing: ElevatedButton(
                            key: Key('moderateAction_${item.issueId}'),
                            onPressed: () {
                              ref
                                  .read(adminFlaggedQueueProvider(filter)
                                      .notifier)
                                  .moderateIssue(
                                    issueId: item.issueId,
                                    action: 'hide_issue',
                                    reason: 'Moderated by admin',
                                  );
                            },
                            child: Text(context.tr('admin_moderate')),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('${context.tr('admin_error')} $err'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
