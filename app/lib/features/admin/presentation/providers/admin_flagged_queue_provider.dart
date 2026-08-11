import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlaggedQueueFilter {
  final String status;
  final String? category;
  final int limit;
  final int offset;

  const FlaggedQueueFilter({
    this.status = 'pending',
    this.category,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlaggedQueueFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          category == other.category &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      status.hashCode ^ category.hashCode ^ limit.hashCode ^ offset.hashCode;
}

class FlaggedIssueItem {
  final int issueId;
  final String issueTitle;
  final String issueDescription;
  final String issueStatus;
  final bool isHidden;
  final int reporterId;
  final int flagCount;
  final List<String> categories;
  final String latestFlagAt;

  FlaggedIssueItem({
    required this.issueId,
    required this.issueTitle,
    required this.issueDescription,
    this.issueStatus = 'open',
    required this.isHidden,
    required this.reporterId,
    required this.flagCount,
    required this.categories,
    required this.latestFlagAt,
  });
}

class FlaggedQueueResponse {
  final List<FlaggedIssueItem> items;
  final int total;
  final int limit;
  final int offset;

  FlaggedQueueResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });
}

class AdminFlaggedQueueNotifier
    extends FamilyAsyncNotifier<FlaggedQueueResponse, FlaggedQueueFilter> {
  late FlaggedQueueFilter filter;
  bool moderateCalled = false;
  int? moderatedIssueId;
  String? lastAction;
  String? lastReason;

  @override
  Future<FlaggedQueueResponse> build(FlaggedQueueFilter arg) async {
    filter = arg;
    final sampleItems = [
      FlaggedIssueItem(
        issueId: 101,
        issueTitle: 'Pothole on Main St',
        issueDescription: 'Dangerous hole',
        isHidden: false,
        reporterId: 42,
        flagCount: 3,
        categories: ['spam', 'abuse'],
        latestFlagAt: DateTime.now().toIso8601String(),
      ),
    ];
    return FlaggedQueueResponse(
      items: filter.status == 'dismissed' ? [] : sampleItems,
      total: sampleItems.length,
      limit: filter.limit,
      offset: filter.offset,
    );
  }

  Future<void> moderateIssue({
    required int issueId,
    required String action,
    String? reason,
  }) async {
    moderateCalled = true;
    moderatedIssueId = issueId;
    lastAction = action;
    lastReason = reason;

    final currentItems = state.value?.items ?? [];
    final updatedItems = currentItems
        .where((item) => item.issueId != issueId)
        .toList();
    state = AsyncData(FlaggedQueueResponse(
      items: updatedItems,
      total: updatedItems.length,
      limit: filter.limit,
      offset: filter.offset,
    ));
  }
}

final adminFlaggedQueueProvider = AsyncNotifierProviderFamily<
    AdminFlaggedQueueNotifier,
    FlaggedQueueResponse,
    FlaggedQueueFilter>(AdminFlaggedQueueNotifier.new);
