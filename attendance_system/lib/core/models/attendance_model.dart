enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final String subjectId;
  final String classId;
  final String teacherId;
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.classId,
    required this.teacherId,
    required this.date,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    String? classId,
    String? teacherId,
    DateTime? date,
    AttendanceStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AttendanceSession {
  final String id;
  final String subjectId;
  final String classId;
  final String teacherId;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final List<AttendanceRecord> records;
  final bool isConfirmed;
  final DateTime createdAt;

  const AttendanceSession({
    required this.id,
    required this.subjectId,
    required this.classId,
    required this.teacherId,
    required this.date,
    required this.startTime,
    this.endTime,
    this.records = const [],
    this.isConfirmed = false,
    required this.createdAt,
  });

  AttendanceSession copyWith({
    String? id,
    String? subjectId,
    String? classId,
    String? teacherId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    List<AttendanceRecord>? records,
    bool? isConfirmed,
    DateTime? createdAt,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      records: records ?? this.records,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

