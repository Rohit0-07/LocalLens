import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/string_formatters.dart';
import '../../ward/presentation/providers/ward_providers.dart';
import '../domain/search_filters.dart';

Future<SearchFilters?> showAdvancedFilterSheet(
  BuildContext context, {
  required SearchFilters initial,
}) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => AdvancedFilterSheet(initial: initial),
  );
}

class AdvancedFilterSheet extends ConsumerStatefulWidget {
  const AdvancedFilterSheet({super.key, required this.initial});

  final SearchFilters initial;

  @override
  ConsumerState<AdvancedFilterSheet> createState() =>
      _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends ConsumerState<AdvancedFilterSheet> {
  late SearchFilters _selection = widget.initial;
  late final TextEditingController _accountController =
      TextEditingController(text: widget.initial.account ?? '');

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  void _resetLocal() {
    setState(() {
      _selection = const SearchFilters();
      _accountController.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(_selection);
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _selection.startDate != null && _selection.endDate != null
          ? DateTimeRange(start: _selection.startDate!, end: _selection.endDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 14)), end: now),
    );
    if (picked != null) {
      setState(() {
        _selection = _selection.copyWith(
          datePreset: SearchDatePreset.custom,
          startDate: picked.start,
          endDate: picked.end,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionLabel = theme.textTheme.titleSmall;
    final wardListAsync = ref.watch(wardListNotifierProvider);
    final wards = wardListAsync.valueOrNull?.wards ?? [];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('filter_title'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            // ── Account / Handle Filter ────────────────────────────
            Text(context.tr('filter_by_account'), style: sectionLabel),
            const SizedBox(height: 8),
            TextField(
              key: const Key('filter_account_field'),
              controller: _accountController,
              decoration: InputDecoration(
                hintText: '@username or citizen handle...',
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (val) {
                final trimmed = val.trim();
                _selection = _selection.copyWith(
                  account: trimmed.isNotEmpty ? trimmed : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Status Selection ───────────────────────────────────
            Text(context.tr('filter_status'), style: sectionLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('statusChip_all'),
                  label: const Text('All'),
                  selected: _selection.status == null,
                  onSelected: (_) => setState(() {
                    _selection = _selection.copyWith(status: null);
                  }),
                ),
                for (final status in kSearchStatusOptions)
                  ChoiceChip(
                    key: Key('statusChip_$status'),
                    label: Text(StringFormatters.formatStatus(status)),
                    selected: _selection.status == status,
                    onSelected: (_) => setState(() {
                      _selection = _selection.copyWith(status: status);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Category Selection ─────────────────────────────────
            Text(context.tr('filter_category'), style: sectionLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in kSearchCategoryOptions)
                  FilterChip(
                    key: Key('categoryChip_$category'),
                    label: Text(context.tr('cat_$category')),
                    selected: _selection.categories.contains(category),
                    onSelected: (_) => setState(() {
                      final selectedCategories =
                          List<String>.of(_selection.categories);
                      if (selectedCategories.contains(category)) {
                        selectedCategories.remove(category);
                      } else {
                        selectedCategories.add(category);
                      }
                      _selection = _selection.copyWith(
                        categories: selectedCategories,
                      );
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Ward Selection ────────────────────────────────────
            Text(context.tr('filter_by_ward'), style: sectionLabel),
            const SizedBox(height: 8),
            if (wards.isEmpty)
              Text(
                'Loading wards…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('wardChip_any'),
                    label: const Text('Any Ward'),
                    selected: _selection.ward == null,
                    onSelected: (_) => setState(() {
                      _selection = _selection.copyWith(ward: null);
                    }),
                  ),
                  for (final ward in wards)
                    ChoiceChip(
                      key: Key('wardChip_${ward.slug}'),
                      label: Text(ward.name),
                      selected: _selection.ward == ward.slug ||
                          _selection.ward == ward.name,
                      onSelected: (_) => setState(() {
                        _selection = _selection.copyWith(ward: ward.slug);
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 16),

            // ── Distance / Proximity ──────────────────────────────
            Text(context.tr('filter_distance'), style: sectionLabel),
            const SizedBox(height: 8),
            SegmentedButton<SearchDistanceOption>(
              segments: [
                ButtonSegment<SearchDistanceOption>(
                  value: SearchDistanceOption.any,
                  label: Text(
                    context.tr('filter_any_distance'),
                    key: const Key('distanceAny'),
                  ),
                ),
                ButtonSegment<SearchDistanceOption>(
                  value: SearchDistanceOption.within,
                  label: Text(
                    context.tr('filter_within_radius'),
                    key: const Key('distanceWithin'),
                  ),
                ),
              ],
              selected: {_selection.distanceOption},
              onSelectionChanged: (set) => setState(() {
                _selection = _selection.copyWith(distanceOption: set.first);
              }),
            ),
            if (_selection.distanceOption == SearchDistanceOption.within) ...[
              const SizedBox(height: 8),
              Slider(
                key: const Key('distanceSlider'),
                min: 1,
                max: 50,
                divisions: 49,
                value: _selection.radiusKm.clamp(1.0, 50.0),
                label: '${_selection.radiusKm.round()} km',
                onChanged: (value) => setState(() {
                  _selection = _selection.copyWith(radiusKm: value);
                }),
              ),
            ],
            const SizedBox(height: 16),

            // ── Date Preset & Custom Range ─────────────────────────
            Text(context.tr('filter_date_range'), style: sectionLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in SearchDatePreset.values)
                  ChoiceChip(
                    key: Key('dateChip_${preset.name}'),
                    label: Text(_datePresetLabel(preset)),
                    selected: _selection.datePreset == preset,
                    onSelected: (_) async {
                      if (preset == SearchDatePreset.custom) {
                        await _pickCustomDateRange();
                      } else {
                        setState(() {
                          _selection = _selection.copyWith(
                            datePreset: preset,
                            startDate: null,
                            endDate: null,
                          );
                        });
                      }
                    },
                  ),
              ],
            ),
            if (_selection.datePreset == SearchDatePreset.custom &&
                _selection.startDate != null &&
                _selection.endDate != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickCustomDateRange,
                icon: const Icon(Icons.date_range_outlined, size: 16),
                label: Text(
                  '${_selection.startDate!.toString().substring(0, 10)} → ${_selection.endDate!.toString().substring(0, 10)}',
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Footer Buttons ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('resetFiltersButton'),
                  onPressed: _resetLocal,
                  child: Text(context.tr('filter_reset')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('applyFiltersButton'),
                  onPressed: _apply,
                  child: Text(context.tr('filter_apply')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _datePresetLabel(SearchDatePreset preset) {
  switch (preset) {
    case SearchDatePreset.anyTime:
      return 'Any time';
    case SearchDatePreset.past24Hours:
      return 'Past 24 hours';
    case SearchDatePreset.past7Days:
      return 'Past 7 days';
    case SearchDatePreset.past30Days:
      return 'Past 30 days';
    case SearchDatePreset.custom:
      return 'Custom range';
  }
}
