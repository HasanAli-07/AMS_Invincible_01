/// Core user model with role-based access
enum UserRole {
  admin,
  principal,
  teacher,
  student,
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? department;
  final String? classId;
  final String? profileImageUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.classId,
    this.profileImageUrl,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? classId,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      classId: classId ?? this.classId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

