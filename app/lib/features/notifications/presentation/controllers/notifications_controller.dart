import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/notifications_api.dart';
import '../../domain/notification_item.dart';

enum NotificationFilter { all, unread }

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.filter = NotificationFilter.all,
    this.errorMessage,
  });

  final List<NotificationItem> notifications;
  final int unreadCount;
  final bool isLoading;
  final NotificationFilter filter;
  final String? errorMessage;

  NotificationsState copyWith({
    List<NotificationItem>? notifications,
    int? unreadCount,
    bool? isLoading,
    NotificationFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(apiClientProvider));
});

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
  NotificationsController.new,
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationsControllerProvider);
  return state.unreadCount;
});

class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    Future.microtask(() => loadNotifications());
    return const NotificationsState(isLoading: true);
  }

  Future<void> loadNotifications({NotificationFilter? filter}) async {
    final activeFilter = filter ?? state.filter;
    state = state.copyWith(isLoading: true, filter: activeFilter, clearError: true);

    try {
      final api = ref.read(notificationsApiProvider);
      final result = await api.fetchNotifications(
        unreadOnly: activeFilter == NotificationFilter.unread,
      );
      state = state.copyWith(
        notifications: result.items,
        unreadCount: result.unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications',
      );
    }
  }

  Future<void> setFilter(NotificationFilter filter) async {
    if (state.filter == filter && !state.isLoading) return;
    await loadNotifications(filter: filter);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final api = ref.read(notificationsApiProvider);
      final updated = await api.markAsRead(notificationId);

      final updatedList = state.notifications.map((item) {
        if (item.id == notificationId) {
          return updated;
        }
        return item;
      }).toList();

      final newUnreadCount = (state.unreadCount - 1).clamp(0, 999);
      state = state.copyWith(
        notifications: updatedList,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      // Keep UI resilient
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final api = ref.read(notificationsApiProvider);
      await api.markAllAsRead();

      final updatedList = state.notifications
          .map((item) => item.copyWith(isRead: true))
          .toList();

      state = state.copyWith(
        notifications: updatedList,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to mark all as read');
    }
  }

  Future<void> refresh() async {
    await loadNotifications();
  }
}
