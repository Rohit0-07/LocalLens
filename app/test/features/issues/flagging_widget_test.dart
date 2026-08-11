import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ============================================================================
// Domain Data Models & Interfaces (from docs/4_interfaces.json)
// ============================================================================

class FlagOut {
  final int id;
  final int issueId;
  final int? reporterId;
  final String? anonId;
  final String category;
  final String? details;
  final String createdAt;

  FlagOut({
    required this.id,
    required this.issueId,
    this.reporterId,
    this.anonId,
    required this.category,
    this.details,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'issue_id': issueId,
        'reporter_id': reporterId,
        'anon_id': anonId,
        'category': category,
        'details': details,
        'created_at': createdAt,
      };

  factory FlagOut.fromJson(Map<String, dynamic> json) => FlagOut(
        id: json['id'] as int,
        issueId: json['issue_id'] as int,
        reporterId: json['reporter_id'] as int?,
        anonId: json['anon_id'] as String?,
        category: json['category'] as String,
        details: json['details'] as String?,
        createdAt: json['created_at'] as String,
      );
}

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

// ============================================================================
// Hive Local Storage Mock / Store (box: 'flagged_issues', key: 'user_flagged_issue_ids')
// ============================================================================

class FakeFlaggedIssuesLocalStore {
  static final FakeFlaggedIssuesLocalStore instance = FakeFlaggedIssuesLocalStore._();
  FakeFlaggedIssuesLocalStore._();

  final Map<String, String> _storage = {};

  Set<int> getFlaggedIssueIds() {
    final jsonStr = _storage['user_flagged_issue_ids'];
    if (jsonStr == null) return {};
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map && decoded.containsKey('flagged_issue_ids')) {
        final list = (decoded['flagged_issue_ids'] as List).cast<int>();
        return list.toSet();
      } else if (decoded is List) {
        return decoded.cast<int>().toSet();
      }
    } catch (_) {}
    return {};
  }

  Future<void> addFlaggedIssueId(int issueId) async {
    final current = getFlaggedIssueIds();
    current.add(issueId);
    final payload = jsonEncode({
      'flagged_issue_ids': current.toList(),
      'last_updated': DateTime.now().toIso8601String(),
    });
    _storage['user_flagged_issue_ids'] = payload;
  }

  bool isIssueFlaggedLocally(int issueId) {
    return getFlaggedIssueIds().contains(issueId);
  }

  void clear() {
    _storage.clear();
  }
}

// ============================================================================
// Riverpod Notifier Providers
// ============================================================================

class FlagIssueNotifier extends FamilyAsyncNotifier<FlagOut?, int> {
  late int issueId;
  bool isGuestUser = false;
  bool submitCalled = false;
  String? lastCategory;
  String? lastDetails;

  @override
  Future<FlagOut?> build(int arg) async {
    issueId = arg;
    return null;
  }

  Future<bool> submitFlag({required String category, String? details}) async {
    submitCalled = true;
    lastCategory = category;
    lastDetails = details;
    if (isGuestUser) {
      return false;
    }
    await FakeFlaggedIssuesLocalStore.instance.addFlaggedIssueId(issueId);
    state = AsyncData(FlagOut(
      id: 1,
      issueId: issueId,
      category: category,
      details: details,
      createdAt: DateTime.now().toIso8601String(),
    ));
    return true;
  }
}

final flagIssueNotifierProvider = AsyncNotifierProviderFamily<
    FlagIssueNotifier, FlagOut?, int>(FlagIssueNotifier.new);

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

    // Update state to reflect moderation action
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

// ============================================================================
// UI Widgets for Testing Key Contracts
// ============================================================================

class GuestGuard extends StatelessWidget {
  const GuestGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('guestGuardModal'),
      title: const Text('Sign in Required'),
      content: const Text('You must be signed in to flag issues.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

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

class TestIssueCard extends StatelessWidget {
  final int issueId;
  final bool isGuest;

  const TestIssueCard({
    super.key,
    required this.issueId,
    this.isGuest = false,
  });

  void _onFlagOptionPressed(BuildContext context) {
    if (isGuest) {
      showDialog(
        context: context,
        builder: (_) => const GuestGuard(),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => FlagIssueDialog(issueId: issueId, isGuest: isGuest),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Card(
        child: ListTile(
          title: Text('Issue #$issueId'),
          trailing: PopupMenuButton<String>(
            key: Key('issueCardOverflow_$issueId'),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                key: Key('flagIssueOption_$issueId'),
                value: 'flag',
                onTap: () => _onFlagOptionPressed(context),
                child: const Text('Flag Issue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TestAdminQueueScreen extends StatefulWidget {
  const TestAdminQueueScreen({super.key});

  @override
  State<TestAdminQueueScreen> createState() => _TestAdminQueueScreenState();
}

class _TestAdminQueueScreenState extends State<TestAdminQueueScreen> {
  String selectedFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    final filter = FlaggedQueueFilter(status: selectedFilter);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Flagged Queue'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            key: const Key('adminQueueFilterSelect'),
            value: selectedFilter,
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'reviewed', child: Text('Reviewed')),
              DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
              DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
              DropdownMenuItem(value: 'all', child: Text('All')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedFilter = val;
                });
              }
            },
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final queueAsync = ref.watch(adminFlaggedQueueProvider(filter));
                return queueAsync.when(
                  data: (response) {
                    if (response.items.isEmpty) {
                      return const Center(child: Text('No items in queue'));
                    }
                    return ListView.builder(
                      itemCount: response.items.length,
                      itemBuilder: (context, index) {
                        final item = response.items[index];
                        return ListTile(
                          title: Text(item.issueTitle),
                          trailing: ElevatedButton(
                            key: Key('moderateAction_${item.issueId}'),
                            onPressed: () {
                              ref
                                  .read(adminFlaggedQueueProvider(filter)
                                      .notifier)
                                  .moderateIssue(
                                    issueId: item.issueId,
                                    action: 'hide_issue',
                                    reason: 'Moderated by admin',
                                  );
                            },
                            child: const Text('Moderate'),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Test Suite: FE-FLAG-01 through FE-FLAG-08
// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FakeFlaggedIssuesLocalStore.instance.clear();
  });

  group('F-14-FLAG Frontend Widget & Integration Tests', () {
    testWidgets('FE-FLAG-01: Issue Card Overflow Menu Interaction',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestIssueCard(issueId: 101),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowKey = Key('issueCardOverflow_101');
      expect(find.byKey(overflowKey), findsOneWidget);

      await tester.tap(find.byKey(overflowKey));
      await tester.pumpAndSettle();

      final optionKey = Key('flagIssueOption_101');
      expect(find.byKey(optionKey), findsOneWidget);
    });

    testWidgets('FE-FLAG-02: Opening Flag Issue Dialog', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestIssueCard(issueId: 101, isGuest: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('issueCardOverflow_101')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('flagIssueOption_101')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('flagIssueDialog')), findsOneWidget);
    });

    testWidgets('FE-FLAG-03: Flag Category Selection Dropdown',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FlagIssueDialog(issueId: 101),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final categorySelectKey = const Key('flagCategorySelect');
      expect(find.byKey(categorySelectKey), findsOneWidget);

      await tester.tap(find.byKey(categorySelectKey));
      await tester.pumpAndSettle();

      final abuseOption = find.text('Abuse').last;
      await tester.tap(abuseOption);
      await tester.pumpAndSettle();

      expect(find.text('Abuse'), findsOneWidget);
    });

    testWidgets('FE-FLAG-04: Submitting Flag Details & Provider Trigger',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FlagIssueDialog(issueId: 101),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final detailsInputKey = const Key('flagDetailsInput');
      final submitButtonKey = const Key('submitFlagButton');

      await tester.enterText(
          find.byKey(detailsInputKey), 'Inappropriate content in description');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(submitButtonKey));
      await tester.pumpAndSettle();

      // Verify Hive cache update as indicator of submission completion
      expect(
          FakeFlaggedIssuesLocalStore.instance.isIssueFlaggedLocally(101), isTrue);
    });

    testWidgets('FE-FLAG-05: Guest User GuestGuard Modal Trigger',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestIssueCard(issueId: 101, isGuest: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('issueCardOverflow_101')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('flagIssueOption_101')));
      await tester.pumpAndSettle();

      // flagIssueDialog should NOT be displayed
      expect(find.byKey(const Key('flagIssueDialog')), findsNothing);

      // GuestGuard dialog should be triggered
      expect(find.byType(GuestGuard), findsOneWidget);
      expect(find.text('Sign in Required'), findsOneWidget);
    });

    testWidgets('FE-FLAG-06: Hive LocalStore Cache Sync Upon Flag Submission',
        (tester) async {
      expect(
          FakeFlaggedIssuesLocalStore.instance.isIssueFlaggedLocally(101), isFalse);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FlagIssueDialog(issueId: 101),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submitFlagButton')));
      await tester.pumpAndSettle();

      final flaggedIds = FakeFlaggedIssuesLocalStore.instance.getFlaggedIssueIds();
      expect(flaggedIds.contains(101), isTrue);
    });

    testWidgets('FE-FLAG-07: Admin Queue Screen Rendering & Filter Selection',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestAdminQueueScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pothole on Main St'), findsOneWidget);

      final filterKey = const Key('adminQueueFilterSelect');
      expect(find.byKey(filterKey), findsOneWidget);

      await tester.tap(find.byKey(filterKey));
      await tester.pumpAndSettle();

      final dismissedItem = find.text('Dismissed').last;
      await tester.tap(dismissedItem);
      await tester.pumpAndSettle();

      expect(find.text('No items in queue'), findsOneWidget);
    });

    testWidgets('FE-FLAG-08: Executing Moderation Action & Queue Refresh',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestAdminQueueScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final moderateKey = Key('moderateAction_101');
      expect(find.byKey(moderateKey), findsOneWidget);

      await tester.tap(find.byKey(moderateKey));
      await tester.pumpAndSettle();

      // Queue state should refresh and item 101 should be removed
      expect(find.text('No items in queue'), findsOneWidget);
    });
  });
}
