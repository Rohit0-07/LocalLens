import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rep_dashboard_providers.dart';

class PostOfficialResponseDialog extends ConsumerStatefulWidget {
  const PostOfficialResponseDialog({
    super.key,
    required this.issueId,
  });

  final int issueId;

  @override
  ConsumerState<PostOfficialResponseDialog> createState() => _PostOfficialResponseDialogState();
}

class _PostOfficialResponseDialogState extends ConsumerState<PostOfficialResponseDialog> {
  late final TextEditingController _messageController;
  late final TextEditingController _etaController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _etaController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _etaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('postOfficialResponseDialog'),
      title: Text('Post Official Response (#${widget.issueId})'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('officialResponseInput'),
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Official Response Message',
                hintText: 'Enter response message for citizens...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('officialEtaInput'),
              controller: _etaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated Resolution (Days)',
                hintText: 'e.g. 3',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancelOfficialResponseButton'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('submitOfficialResponseButton'),
          onPressed: () async {
            final message = _messageController.text.trim();
            final etaText = _etaController.text.trim();
            final eta = int.tryParse(etaText);

            if (message.isNotEmpty) {
              await ref.read(repDashboardNotifierProvider.notifier).postOfficialResponse(
                    issueId: widget.issueId,
                    message: message,
                    estimatedResolutionDays: eta,
                  );
            }
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Submit Response'),
        ),
      ],
    );
  }
}
