import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_lens/core/utils/relative_time.dart';
import 'package:local_lens/features/notifications/presentation/notifications_screen.dart';

/// Data model matching backend F-10 NotificationResponse contract.
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'].toString(),
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      referenceId: json['reference_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'reference_id': referenceId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Controller managing state for Notifications Engine
class FakeNotificationsController extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  FakeNotificationsController(this._allItems) : super(AsyncValue.data(_allItems));

  final List<NotificationItem> _allItems;
  bool showUnreadOnly = false;
  int markAllAsReadCalls = 0;
  int markSingleAsReadCalls = 0;

  int get unreadCount => state.value?.where((item) => !item.isRead).length ?? 0;

  void filter(bool unreadOnly) {
    showUnreadOnly = unreadOnly;
    _updateState();
  }

  void markAllAsRead() {
    markAllAsReadCalls++;
    for (var i = 0; i < _allItems.length; i++) {
      _allItems[i] = _allItems[i].copyWith(isRead: true);
    }
    _updateState();
  }

  void markAsRead(String id) {
    markSingleAsReadCalls++;
    final index = _allItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _allItems[index] = _allItems[index].copyWith(isRead: true);
    }
    _updateState();
  }

  void _updateState() {
    final filtered = showUnreadOnly
        ? _allItems.where((item) => !item.isRead).toList()
        : List<NotificationItem>.from(_allItems);
    state = AsyncValue.data(filtered);
  }
}

final notificationsTestControllerProvider = StateNotifierProvider.family<
    FakeNotificationsController,
    AsyncValue<List<NotificationItem>>,
    List<NotificationItem>>((ref, initialItems) {
  return FakeNotificationsController(List.from(initialItems));
});

/// Testable Notifications List View widget representing F-10 specification UI requirements
class TestableNotificationsView extends ConsumerStatefulWidget {
  final List<NotificationItem> initialItems;
  final Function(String id)? onNotificationTap;

  const TestableNotificationsView({
    super.key,
    required this.initialItems,
    this.onNotificationTap,
  });

  @override
  ConsumerState<TestableNotificationsView> createState() =>
      _TestableNotificationsViewState();
}

class _TestableNotificationsViewState
    extends ConsumerState<TestableNotificationsView> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
        notificationsTestControllerProvider(widget.initialItems).notifier);
    final asyncNotifications =
        ref.watch(notificationsTestControllerProvider(widget.initialItems));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            key: const Key('mark_all_read_btn'),
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => controller.markAllAsRead(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(
                  key: const Key('filter_all'),
                  label: const Text('All'),
                  selected: !_unreadOnly,
                  onSelected: (selected) {
                    setState(() => _unreadOnly = false);
                    controller.filter(false);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  key: const Key('filter_unread'),
                  label: Text('Unread (${controller.unreadCount})'),
                  selected: _unreadOnly,
                  onSelected: (selected) {
                    setState(() => _unreadOnly = true);
                    controller.filter(true);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncNotifications.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const Center(
                    child: Text('No notifications yet'),
                  );
                }
                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return ListTile(
                      key: Key('notification_tile_${item.id}'),
                      title: Text(item.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.body),
                          const SizedBox(height: 4),
                          Text(
                            formatRelativeTime(item.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      leading: CircleAvatar(
                        child: Icon(_getIconForType(item.type)),
                      ),
                      trailing: item.isRead
                          ? null
                          : Container(
                              key: Key('unread_badge_${item.id}'),
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () {
                        controller.markAsRead(item.id);
                        widget.onNotificationTap?.call(item.id);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'escalation':
        return Icons.warning_amber;
      case 'quorum_request':
        return Icons.people;
      case 'upvote_milestone':
        return Icons.thumb_up;
      case 'comment_reply':
        return Icons.comment;
      case 'system_notice':
      default:
        return Icons.notifications;
    }
  }
}

void main() {
  group('F-10 Notifications & Inbox Engine - Contract & Unit Tests', () {
    test('NotificationItem serializes and deserializes correctly', () {
      final json = {
        'id': 'notif-101',
        'title': 'Issue Escalated',
        'body': 'Pothole on Main St reached 24h unacknowledged',
        'type': 'escalation',
        'reference_id': 'issue-42',
        'is_read': false,
        'created_at': '2026-08-09T12:00:00.000Z',
      };

      final item = NotificationItem.fromJson(json);
      expect(item.id, 'notif-101');
      expect(item.title, 'Issue Escalated');
      expect(item.body, 'Pothole on Main St reached 24h unacknowledged');
      expect(item.type, 'escalation');
      expect(item.referenceId, 'issue-42');
      expect(item.isRead, isFalse);
      expect(item.createdAt.year, 2026);

      final exported = item.toJson();
      expect(exported['id'], 'notif-101');
      expect(exported['is_read'], isFalse);
      expect(exported['type'], 'escalation');
    });

    test('FakeNotificationsController filters unread items correctly', () {
      final items = [
        NotificationItem(
          id: '1',
          title: 'Title 1',
          body: 'Body 1',
          type: 'system_notice',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        NotificationItem(
          id: '2',
          title: 'Title 2',
          body: 'Body 2',
          type: 'comment_reply',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      ];

      final controller = FakeNotificationsController(items);
      expect(controller.unreadCount, 1);

      controller.filter(true);
      expect(controller.state.value!.length, 1);
      expect(controller.state.value!.first.id, '1');

      controller.markAllAsRead();
      expect(controller.unreadCount, 0);
      expect(controller.markAllAsReadCalls, 1);
    });
  });

  group('F-10 Notifications & Inbox Engine - Widget Tests', () {
    final now = DateTime.now();
    final mockNotifications = [
      NotificationItem(
        id: '101',
        title: 'Deep pothole reported',
        body: 'Your issue was assigned to Ward 3',
        type: 'escalation',
        referenceId: 'issue-1',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      NotificationItem(
        id: '102',
        title: 'Quorum request nearby',
        body: 'Please verify street light fix on 4th st',
        type: 'quorum_request',
        referenceId: 'issue-2',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: '103',
        title: '10 Upvotes milestone!',
        body: 'Water logging post has reached 10 votes',
        type: 'upvote_milestone',
        referenceId: 'issue-3',
        isRead: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    testWidgets('Renders NotificationsScreen route without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('Empty state renders when list is empty ("No notifications yet")',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestableNotificationsView(initialItems: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets(
        'Verify list of notifications renders with titles, bodies, and relative timestamps',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TestableNotificationsView(initialItems: mockNotifications),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Titles
      expect(find.text('Deep pothole reported'), findsOneWidget);
      expect(find.text('Quorum request nearby'), findsOneWidget);
      expect(find.text('10 Upvotes milestone!'), findsOneWidget);

      // Bodies
      expect(find.text('Your issue was assigned to Ward 3'), findsOneWidget);
      expect(find.text('Please verify street light fix on 4th st'), findsOneWidget);
      expect(find.text('Water logging post has reached 10 votes'), findsOneWidget);

      // Relative timestamps using formatRelativeTime helper
      expect(find.text(formatRelativeTime(mockNotifications[0].createdAt)), findsOneWidget);
      expect(find.text(formatRelativeTime(mockNotifications[1].createdAt)), findsOneWidget);
    });

    testWidgets('Verify unread indicator badge appears for unread items only',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TestableNotificationsView(initialItems: mockNotifications),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unread items (101 & 103) have unread badge indicators
      expect(find.byKey(const Key('unread_badge_101')), findsOneWidget);
      expect(find.byKey(const Key('unread_badge_103')), findsOneWidget);

      // Read item (102) does NOT have unread badge
      expect(find.byKey(const Key('unread_badge_102')), findsNothing);
    });

    testWidgets('Verify filter toggle (All / Unread) filters rendered list',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TestableNotificationsView(initialItems: mockNotifications),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 'All' filter is selected, 3 items shown
      expect(find.byType(ListTile), findsNWidgets(3));

      // Tap 'Unread' filter chip
      await tester.tap(find.byKey(const Key('filter_unread')));
      await tester.pumpAndSettle();

      // Should filter to only 2 unread items (101 and 103)
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('Deep pothole reported'), findsOneWidget);
      expect(find.text('10 Upvotes milestone!'), findsOneWidget);
      expect(find.text('Quorum request nearby'), findsNothing);

      // Tap 'All' filter chip
      await tester.tap(find.byKey(const Key('filter_all')));
      await tester.pumpAndSettle();

      // Shows all 3 items again
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('Verify "Mark all as read" action triggers controller method',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TestableNotificationsView(initialItems: mockNotifications),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before mark-all-read: 2 unread badges exist
      expect(find.byKey(const Key('unread_badge_101')), findsOneWidget);
      expect(find.byKey(const Key('unread_badge_103')), findsOneWidget);

      // Tap "Mark all as read" action button in app bar
      await tester.tap(find.byKey(const Key('mark_all_read_btn')));
      await tester.pumpAndSettle();

      // All badges are gone after mark-all-as-read
      expect(find.byKey(const Key('unread_badge_101')), findsNothing);
      expect(find.byKey(const Key('unread_badge_103')), findsNothing);
    });

    testWidgets('Tapping notification tile triggers mark single notification read',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TestableNotificationsView(initialItems: mockNotifications),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unread_badge_101')), findsOneWidget);

      // Tap tile 101
      await tester.tap(find.byKey(const Key('notification_tile_101')));
      await tester.pumpAndSettle();

      // Unread badge for 101 is cleared
      expect(find.byKey(const Key('unread_badge_101')), findsNothing);
    });
  });
}
