import 'user_model.dart';

class Student {
  final String id;
  final String name;
  final String email;
  final String rollNumber;
  final String enrollmentNo; // New field
  final String semester;     // New field
  final String department;   // New field
  final String batch;        // New field
  final String classId;
  final String? profileImageUrl;
  final DateTime enrollmentDate;
  final Map<String, double> subjectAttendance; // subjectId -> percentage

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNumber,
    this.enrollmentNo = '',
    this.semester = '',
    this.department = '',
    this.batch = '',
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
    String? enrollmentNo,
    String? semester,
    String? department,
    String? batch,
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
      enrollmentNo: enrollmentNo ?? this.enrollmentNo,
      semester: semester ?? this.semester,
      department: department ?? this.department,
      batch: batch ?? this.batch,
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
      // Map extra fields if User model supports them, otherwise they are student specific
    );
  }
}

