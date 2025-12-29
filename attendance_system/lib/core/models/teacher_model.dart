import 'user_model.dart';

class Teacher {
  final String id;
  final String name;
  final String email;
  final String department;
  final List<String> subjectIds; // Subjects taught
  final List<String> classIds; // Classes assigned
  final String? profileImageUrl;
  final DateTime joinDate;

  const Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    this.subjectIds = const [],
    this.classIds = const [],
    this.profileImageUrl,
    required this.joinDate,
  });

  Teacher copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    List<String>? subjectIds,
    List<String>? classIds,
    String? profileImageUrl,
    DateTime? joinDate,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      subjectIds: subjectIds ?? this.subjectIds,
      classIds: classIds ?? this.classIds,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joinDate: joinDate ?? this.joinDate,
    );
  }

  User toUser() {
    return User(
      id: id,
      name: name,
      email: email,
      role: UserRole.teacher,
      department: department,
      profileImageUrl: profileImageUrl,
      createdAt: joinDate,
    );
  }
}

