import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
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

  void _resetLocal() {
    setState(() => _selection = const SearchFilters());
  }

  void _apply() {
    Navigator.of(context).pop(_selection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionLabel = theme.textTheme.titleSmall;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('filter_title'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(context.tr('filter_status'), style: sectionLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in kSearchStatusOptions)
                  ChoiceChip(
                    key: Key('statusChip_$status'),
                    label: Text(status),
                    selected: _selection.status == status,
                    onSelected: (_) => setState(() {
                      _selection = _selection.copyWith(status: status);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(context.tr('filter_category'), style: sectionLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in kSearchCategoryOptions)
                  FilterChip(
                    key: Key('categoryChip_$category'),
                    label: Text(category),
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
            Text(context.tr('filter_posted'), style: sectionLabel),
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
                    onSelected: (_) => setState(() {
                      _selection = _selection.copyWith(datePreset: preset);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
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
                  child: Text(context.tr('filter_show_results')),
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
  }
}
