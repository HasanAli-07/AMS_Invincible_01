import 'user_model.dart';

class Post {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final UserRole authorRole;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> attachments; // URLs or file paths
  final bool isPinned;
  final List<String> targetRoles; // Which roles can see this

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorRole,
    required this.createdAt,
    this.updatedAt,
    this.attachments = const [],
    this.isPinned = false,
    this.targetRoles = const [],
  });

  Post copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    UserRole? authorRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachments,
    bool? isPinned,
    List<String>? targetRoles,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorRole: authorRole ?? this.authorRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      isPinned: isPinned ?? this.isPinned,
      targetRoles: targetRoles ?? this.targetRoles,
    );
  }
}

