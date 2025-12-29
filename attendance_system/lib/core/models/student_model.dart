import 'user_model.dart';

class Student {
  final String id;
  final String name;
  final String email;
  final String rollNumber;
  final String classId;
  final String? profileImageUrl;
  final DateTime enrollmentDate;
  final Map<String, double> subjectAttendance; // subjectId -> percentage

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNumber,
    required this.classId,
    this.profileImageUrl,
    required this.enrollmentDate,
    this.subjectAttendance = const {},
  });

  double get overallAttendance {
    if (subjectAttendance.isEmpty) return 0.0;
    final total = subjectAttendance.values.reduce((a, b) => a + b);
    return total / subjectAttendance.length;
  }

  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? rollNumber,
    String? classId,
    String? profileImageUrl,
    DateTime? enrollmentDate,
    Map<String, double>? subjectAttendance,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      rollNumber: rollNumber ?? this.rollNumber,
      classId: classId ?? this.classId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      subjectAttendance: subjectAttendance ?? this.subjectAttendance,
    );
  }

  User toUser() {
    return User(
      id: id,
      name: name,
      email: email,
      role: UserRole.student,
      classId: classId,
      profileImageUrl: profileImageUrl,
      createdAt: enrollmentDate,
    );
  }
}

