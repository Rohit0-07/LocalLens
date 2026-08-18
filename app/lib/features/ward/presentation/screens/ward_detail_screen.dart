import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../feed/domain/issue.dart';
import '../providers/ward_providers.dart';
import '../widgets/ward_boundary_mini_map.dart';
import '../widgets/ward_chip.dart';
import '../widgets/ward_hero_banner.dart';
import '../widgets/ward_metric_card.dart';
import '../widgets/ward_recent_issues_list.dart';
import '../widgets/ward_rep_card.dart';

class WardDetailScreen extends ConsumerStatefulWidget {
  const WardDetailScreen({super.key, required this.wardSlug});

  final String wardSlug;

  @override
  ConsumerState<WardDetailScreen> createState() => _WardDetailScreenState();
}

class _WardDetailScreenState extends ConsumerState<WardDetailScreen> {
  String _issueFilter = 'active';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Issue> _filterIssues(List<Issue> issues) {
    var filtered = issues;

    // Apply status filter
    switch (_issueFilter) {
      case 'active':
        filtered = filtered
            .where((i) => i.status != 'resolved' && i.status != 'dismissed')
            .toList();
        break;
      case 'escalated':
        filtered = filtered
            .where((i) =>
                i.status == 'escalating' || i.status == 'escalated')
            .toList();
        break;
      case 'resolved':
        filtered =
            filtered.where((i) => i.status == 'resolved').toList();
        break;
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((i) =>
              i.title.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asyncDetail = ref.watch(wardDetailNotifierProvider(widget.wardSlug));

    return Scaffold(
      key: const Key('wardDetailScreen'),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('wardDetailBackButton'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(context.tr('ward_details')),
      ),
      body: asyncDetail.when(
        data: (wardDetail) {
          final filteredIssues = _filterIssues(wardDetail.recentIssues);
          final rep = wardDetail.assignedRepresentative;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WardHeroBanner(wardDetail: wardDetail),
                const SizedBox(height: 16),
                WardMetricsGrid(wardDetail: wardDetail),

                // ── Representative Section ───────────────────────
                const SizedBox(height: 20),
                Row(
                  key: const Key('wardRepSectionHeader'),
                  children: [
                    Icon(Icons.person_pin_outlined,
                        size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Ward Representatives',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (rep != null)
                  WardRepCard(
                    representative: rep,
                    onTap: rep.userId > 0
                        ? () => context.push(
                              RoutePaths.publicProfileFor(rep.userId),
                            )
                        : null,
                  )
                else
                  Card(
                    key: const Key('wardNoRepPlaceholder'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.person_off_outlined,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text(
                            'No representative assigned yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Boundary Mini-Map ────────────────────────────
                const SizedBox(height: 20),
                WardBoundaryMiniMap(
                  key: const Key('wardBoundaryMiniMap'),
                  ward: wardDetail,
                ),

                // ── Issues Search Bar ─────────────────────────────
                const SizedBox(height: 20),
                TextField(
                  key: const Key('wardIssueSearchField'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search issues in this ward...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim()),
                ),

                // ── Issues Filter Tabs ────────────────────────────
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.assignment_outlined, size: 20,
                        color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Ward Issues',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filteredIssues.length} found',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _IssueFilterChip(
                        label: 'Active',
                        isSelected: _issueFilter == 'active',
                        color: AppColors.urgent,
                        onTap: () =>
                            setState(() => _issueFilter = 'active'),
                      ),
                      const SizedBox(width: 8),
                      _IssueFilterChip(
                        label: 'Escalated',
                        isSelected: _issueFilter == 'escalated',
                        color: Colors.deepOrange,
                        onTap: () =>
                            setState(() => _issueFilter = 'escalated'),
                      ),
                      const SizedBox(width: 8),
                      _IssueFilterChip(
                        label: 'Resolved',
                        isSelected: _issueFilter == 'resolved',
                        color: AppColors.resolved,
                        onTap: () =>
                            setState(() => _issueFilter = 'resolved'),
                      ),
                      const SizedBox(width: 8),
                      _IssueFilterChip(
                        label: 'All',
                        isSelected: _issueFilter == 'all',
                        color: colorScheme.primary,
                        onTap: () =>
                            setState(() => _issueFilter = 'all'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Issues List ────────────────────────────────────
                if (filteredIssues.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 40,
                                color: colorScheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No issues matching "$_searchQuery"'
                                  : 'No ${_issueFilter == 'all' ? '' : '$_issueFilter '}issues',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  WardRecentIssuesList(
                    issues: filteredIssues,
                    showHeader: false,
                  ),

                // ── Nearby Wards ──────────────────────────────────
                const SizedBox(height: 20),
                _buildNearbyWardsSection(wardDetail.slug),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          final errorMsg =
              error is StateError ? error.message : error.toString();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    errorMsg.contains('Ward not found')
                        ? 'Ward not found'
                        : errorMsg,
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

  /// Horizontal row of chips for the other wards in the registry, completing
  /// the reachability loop back into this page. Hidden while loading, on
  /// error, or when there is at most one ward in total.
  Widget _buildNearbyWardsSection(String currentSlug) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asyncList = ref.watch(wardListNotifierProvider);

    return asyncList.when(
      data: (list) {
        final others = list.items.where((w) => w.slug != currentSlug).toList();
        if (others.isEmpty) return const SizedBox.shrink();
        return Column(
          key: const Key('wardNearbyWardsSection'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.near_me_outlined,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Nearby Wards',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final ward in others) ...[
                    WardChip(
                      key: Key('wardChip_${ward.slug}'),
                      wardName: ward.name,
                      slug: ward.slug,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _IssueFilterChip extends StatelessWidget {
  const _IssueFilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.16),
      backgroundColor: colorScheme.surface,
      side: BorderSide(
        color: isSelected ? color : colorScheme.outlineVariant,
      ),
      labelStyle: TextStyle(
        color: isSelected ? color : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
