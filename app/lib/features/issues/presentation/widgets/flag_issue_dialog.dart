import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
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
      title: Text(context.tr('flag_issue_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            key: const Key('flagCategorySelect'),
            value: selectedCategory,
            items: [
              DropdownMenuItem(
                value: 'spam',
                child: Text(context.tr('flag_category_spam')),
              ),
              DropdownMenuItem(
                value: 'abuse',
                child: Text(context.tr('flag_category_abuse')),
              ),
              DropdownMenuItem(
                value: 'pii',
                child: Text(context.tr('flag_category_pii')),
              ),
              DropdownMenuItem(
                value: 'fake_report',
                child: Text(context.tr('flag_category_fake')),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text(context.tr('flag_category_other')),
              ),
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
            decoration: InputDecoration(
              hintText: context.tr('flag_details_hint'),
            ),
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
              child: Text(context.tr('action_submit')),
            );
          },
        ),
      ],
    );
  }
}
