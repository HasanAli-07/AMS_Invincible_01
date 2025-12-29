class Class {
  final String id;
  final String name; // e.g., "10-A", "CS-2024"
  final String department;
  final String academicYear;
  final int totalStudents;
  final String? classTeacherId;

  const Class({
    required this.id,
    required this.name,
    required this.department,
    required this.academicYear,
    required this.totalStudents,
    this.classTeacherId,
  });

  Class copyWith({
    String? id,
    String? name,
    String? department,
    String? academicYear,
    int? totalStudents,
    String? classTeacherId,
  }) {
    return Class(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      totalStudents: totalStudents ?? this.totalStudents,
      classTeacherId: classTeacherId ?? this.classTeacherId,
    );
  }
}

