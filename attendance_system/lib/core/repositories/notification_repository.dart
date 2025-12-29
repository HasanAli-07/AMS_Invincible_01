import '../models/notification_model.dart';
import '../models/user_model.dart';

abstract class NotificationRepository {
  Future<List<Notification>> getNotificationsByUser(String userId, UserRole role);
  Future<Notification?> getNotificationById(String id);
  Future<Notification> createNotification(Notification notification);
  Future<Notification> markAsRead(String id);
  Future<void> deleteNotification(String id);
  Future<int> getUnreadCount(String userId, UserRole role);
}

class InMemoryNotificationRepository implements NotificationRepository {
  final Map<String, Notification> _notifications = {};

  @override
  Future<List<Notification>> getNotificationsByUser(String userId, UserRole role) async {
    return _notifications.values.where((n) => 
      n.targetRole == null || n.targetRole == role
    ).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Notification?> getNotificationById(String id) async {
    return _notifications[id];
  }

  @override
  Future<Notification> createNotification(Notification notification) async {
    _notifications[notification.id] = notification;
    return notification;
  }

  @override
  Future<Notification> markAsRead(String id) async {
    final notification = _notifications[id];
    if (notification != null) {
      final updated = notification.copyWith(isRead: true);
      _notifications[id] = updated;
      return updated;
    }
    throw Exception('Notification not found');
  }

  @override
  Future<void> deleteNotification(String id) async {
    _notifications.remove(id);
  }

  @override
  Future<int> getUnreadCount(String userId, UserRole role) async {
    final notifications = await getNotificationsByUser(userId, role);
    return notifications.where((n) => !n.isRead).length;
  }
}

