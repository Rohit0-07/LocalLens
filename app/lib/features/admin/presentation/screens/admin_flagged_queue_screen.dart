import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text('Admin Flagged Queue'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            key: const Key('adminQueueFilterSelect'),
            value: selectedFilter,
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'reviewed', child: Text('Reviewed')),
              DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
              DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
              DropdownMenuItem(value: 'all', child: Text('All')),
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
                      return const Center(child: Text('No items in queue'));
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
                            child: const Text('Moderate'),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
