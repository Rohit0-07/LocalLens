import '../../../core/network/api_client.dart';
import '../domain/notification_item.dart';

class NotificationsApi {
  NotificationsApi(this._client);

  final ApiClient _client;

  Future<NotificationListResult> fetchNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final data = await _client.getJson(
      '/notifications',
      query: {
        'limit': limit,
        'offset': offset,
        'unread_only': unreadOnly,
      },
    );
    return NotificationListResult.fromJson(data as Map<String, dynamic>);
  }

  Future<NotificationItem> markAsRead(String notificationId) async {
    final data = await _client.patchJson('/notifications/$notificationId/read');
    return NotificationItem.fromJson(data as Map<String, dynamic>);
  }

  Future<int> markAllAsRead() async {
    final data = await _client.postJson('/notifications/read-all');
    final map = data as Map<String, dynamic>;
    return map['updated_count'] as int? ?? 0;
  }
}
