import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/flag_issue_provider.dart';

class FlagIssueDialog extends StatefulWidget {
  final int issueId;
  final bool isGuest;

  const FlagIssueDialog({
    super.key,
    required this.issueId,
    this.isGuest = false,
  });

  @override
  State<FlagIssueDialog> createState() => _FlagIssueDialogState();
}

class _FlagIssueDialogState extends State<FlagIssueDialog> {
  String selectedCategory = 'spam';
  final TextEditingController detailsController = TextEditingController();

  @override
  void dispose() {
    detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('flagIssueDialog'),
      title: const Text('Flag Issue'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            key: const Key('flagCategorySelect'),
            value: selectedCategory,
            items: const [
              DropdownMenuItem(value: 'spam', child: Text('Spam')),
              DropdownMenuItem(value: 'abuse', child: Text('Abuse')),
              DropdownMenuItem(value: 'pii', child: Text('PII')),
              DropdownMenuItem(value: 'fake_report', child: Text('Fake Report')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedCategory = val;
                });
              }
            },
          ),
          TextField(
            key: const Key('flagDetailsInput'),
            controller: detailsController,
            decoration: const InputDecoration(hintText: 'Details (optional)'),
          ),
        ],
      ),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            return ElevatedButton(
              key: const Key('submitFlagButton'),
              onPressed: () async {
                final notifier = ref.read(
                    flagIssueNotifierProvider(widget.issueId).notifier);
                final success = await notifier.submitFlag(
                  category: selectedCategory,
                  details: detailsController.text,
                );
                if (success && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Submit'),
            );
          },
        ),
      ],
    );
  }
}
