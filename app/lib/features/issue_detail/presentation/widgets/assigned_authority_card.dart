import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../feed/domain/issue.dart';
import '../../data/issue_detail_api.dart';

/// Card showing the assigned municipal department representative / authority,
/// including username handle, claimed vs unclaimed dummy status badge,
/// and a report wrong ward/department button.
class AssignedAuthorityCard extends ConsumerStatefulWidget {
  const AssignedAuthorityCard({
    super.key,
    required this.issue,
    this.onReportSubmitted,
  });

  final Issue issue;
  final VoidCallback? onReportSubmitted;

  @override
  ConsumerState<AssignedAuthorityCard> createState() =>
      _AssignedAuthorityCardState();
}

class _AssignedAuthorityCardState
    extends ConsumerState<AssignedAuthorityCard> {
  void _openReportWrongWardDialog() {
    final issue = widget.issue;
    final suggestedWardController =
        TextEditingController(text: issue.ward);
    final suggestedCategoryController =
        TextEditingController(text: issue.category);
    final reasonController = TextEditingController();
    bool isSubmitting = false;
    String? errorText;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            final colorScheme = theme.colorScheme;
            final keyboardInset = MediaQuery.viewInsetsOf(ctx).bottom;

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: keyboardInset + 20,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.urgent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wrong_location_outlined,
                              color: AppColors.urgent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ctx.tr('report_wrong_ward_title'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ctx.tr('report_wrong_ward_desc'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        key: const Key('suggested_ward_field'),
                        controller: suggestedWardController,
                        decoration: InputDecoration(
                          labelText: ctx.tr('suggested_ward_label'),
                          prefixIcon: const Icon(Icons.location_city_outlined),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('suggested_category_field'),
                        controller: suggestedCategoryController,
                        decoration: InputDecoration(
                          labelText: ctx.tr('suggested_category_label'),
                          prefixIcon: const Icon(Icons.category_outlined),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('report_reason_field'),
                        controller: reasonController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: ctx.tr('report_reason_label'),
                          hintText: ctx.tr('report_reason_hint'),
                          prefixIcon: const Icon(Icons.edit_note_outlined),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorText!,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('submit_wrong_ward_button'),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final reason = reasonController.text.trim();
                                if (reason.isEmpty) {
                                  setModalState(() {
                                    errorText =
                                        'Please provide a brief reason for reassignment';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = true;
                                  errorText = null;
                                });

                                try {
                                  final api = ref.read(issueDetailApiProvider);
                                  await api.reportWrongAssignment(
                                    issueId: issue.id,
                                    suggestedWard:
                                        suggestedWardController.text.trim(),
                                    suggestedCategory:
                                        suggestedCategoryController.text.trim(),
                                    reason: reason,
                                  );

                                  if (modalCtx.mounted) {
                                    Navigator.pop(modalCtx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ctx.tr(
                                            'report_submitted_success')),
                                      ),
                                    );
                                    widget.onReportSubmitted?.call();
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isSubmitting = false;
                                    errorText = e.toString();
                                  });
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(ctx.tr('submit_report')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rep = widget.issue.assignedRepresentative;

    final String officialName =
        rep?.officialName ?? '${widget.issue.ward} Authority';
    final String title =
        rep?.title ?? 'Department Executive Engineer';
    final String? handle = rep?.handle;
    final bool isUnclaimed = rep?.isUnclaimed ?? true;

    return Card(
      key: const Key('assigned_authority_card'),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: AppColors.brand,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('assigned_authority'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        officialName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  key: isUnclaimed
                      ? const Key('unclaimed_handle_badge')
                      : const Key('claimed_handle_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnclaimed
                        ? Colors.amber.withValues(alpha: 0.15)
                        : AppColors.resolved.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUnclaimed
                          ? Colors.amber.shade700
                          : AppColors.resolved,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUnclaimed
                            ? Icons.hourglass_top_rounded
                            : Icons.verified_rounded,
                        size: 13,
                        color: isUnclaimed
                            ? Colors.amber.shade900
                            : AppColors.resolved,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isUnclaimed
                            ? context.tr('unclaimed_authority_badge')
                            : context.tr('claimed_authority_badge'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isUnclaimed
                              ? Colors.amber.shade900
                              : AppColors.resolved,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (handle != null && handle.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '@$handle',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (isUnclaimed) ...[
              const SizedBox(height: 8),
              Text(
                context.tr('unclaimed_authority_notice'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.issue.ward} • ${context.tr("cat_${widget.issue.category}")}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  key: const Key('report_wrong_ward_button'),
                  onPressed: _openReportWrongWardDialog,
                  icon: const Icon(
                    Icons.flag_outlined,
                    size: 14,
                    color: AppColors.urgent,
                  ),
                  label: Text(
                    context.tr('report_wrong_ward'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.urgent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
