import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';

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

  factory FlaggedIssueItem.fromJson(Map<String, dynamic> json) {
    return FlaggedIssueItem(
      issueId: json['issue_id'] as int,
      issueTitle: json['title'] as String? ?? '',
      issueDescription: json['description'] as String? ?? '',
      issueStatus: json['status'] as String? ?? 'open',
      isHidden: json['is_hidden'] as bool? ?? false,
      reporterId: json['reporter_id'] as int? ?? 0,
      flagCount: json['flag_count'] as int? ?? 0,
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      latestFlagAt: json['latest_flag_at'] as String? ?? '',
    );
  }
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

  factory FlaggedQueueResponse.fromJson(Map<String, dynamic> json) {
    return FlaggedQueueResponse(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => FlaggedIssueItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      offset: json['offset'] as int? ?? 0,
    );
  }
}

class AdminFlaggedQueueNotifier
    extends FamilyAsyncNotifier<FlaggedQueueResponse, FlaggedQueueFilter> {
  late FlaggedQueueFilter filter;

  @override
  Future<FlaggedQueueResponse> build(FlaggedQueueFilter arg) async {
    filter = arg;
    final client = ref.watch(apiClientProvider);
    final query = <String, dynamic>{
      'status': filter.status,
      'limit': filter.limit,
      'offset': filter.offset,
    };
    if (filter.category != null) query['category'] = filter.category;
    final data = await client.getJson('/admin/flagged-issues', query: query);
    return FlaggedQueueResponse.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> moderateIssue({
    required int issueId,
    required String action,
    String? reason,
  }) async {
    final client = ref.read(apiClientProvider);
    await client.postJson(
      '/admin/issues/$issueId/moderate',
      body: {'action': action, 'reason': reason},
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg));
  }
}

final adminFlaggedQueueProvider = AsyncNotifierProviderFamily<
    AdminFlaggedQueueNotifier,
    FlaggedQueueResponse,
    FlaggedQueueFilter>(AdminFlaggedQueueNotifier.new);