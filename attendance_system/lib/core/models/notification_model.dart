import 'user_model.dart';

enum NotificationType {
  attendancePending,
  attendanceSubmitted,
  reportReady,
  systemAlert,
  postUpdate,
  general,
}

class Notification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? relatedId; // ID of related entity (attendance, post, etc.)
  final DateTime createdAt;
  final bool isRead;
  final UserRole? targetRole; // If null, applies to all roles

  const Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.createdAt,
    this.isRead = false,
    this.targetRole,
  });

  Notification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    String? relatedId,
    DateTime? createdAt,
    bool? isRead,
    UserRole? targetRole,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      targetRole: targetRole ?? this.targetRole,
    );
  }
}

