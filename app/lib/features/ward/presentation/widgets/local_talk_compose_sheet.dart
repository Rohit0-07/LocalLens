import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ward_providers.dart';

class LocalTalkComposeSheet extends ConsumerStatefulWidget {
  final String wardSlug;
  final VoidCallback? onPostSubmitted;

  const LocalTalkComposeSheet({
    super.key,
    required this.wardSlug,
    this.onPostSubmitted,
  });

  static Future<void> show(BuildContext context, String wardSlug, {VoidCallback? onPostSubmitted}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocalTalkComposeSheet(
        wardSlug: wardSlug,
        onPostSubmitted: onPostSubmitted,
      ),
    );
  }

  @override
  ConsumerState<LocalTalkComposeSheet> createState() => _LocalTalkComposeSheetState();
}

class _LocalTalkComposeSheetState extends ConsumerState<LocalTalkComposeSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTopic = 'General';
  bool _isSubmitting = false;

  final List<String> _topics = ['General', 'Q&A', 'Roads', 'Water', 'Safety', 'Sanitation'];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and content.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(wardRepositoryProvider);
      await repository.createTalkPost(
        wardSlug: widget.wardSlug,
        title: title,
        body: body,
        topic: _selectedTopic,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discussion post published successfully!')),
        );
        widget.onPostSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Start a Ward Discussion',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Select Topic',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _topics.map((topic) {
                final isSelected = _selectedTopic == topic;
                return ChoiceChip(
                  label: Text(topic),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedTopic = topic);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('localTalkTitleInput'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title / Question',
                hintText: 'e.g. When will the water pipeline repair complete?',
                border: OutlineInputBorder(),
              ),
              maxLength: 255,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('localTalkBodyInput'),
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Details / Discussion Body',
                hintText: 'Provide context for neighborhood discussion...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 2000,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const Key('submitLocalTalkButton'),
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Publish Discussion',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
