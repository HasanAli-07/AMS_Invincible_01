import '../models/attendance_model.dart';
import '../models/student_model.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/student_repository.dart';

/// Service layer for attendance business logic
class AttendanceService {
  final AttendanceRepository attendanceRepo;
  final StudentRepository studentRepo;

  AttendanceService({
    required this.attendanceRepo,
    required this.studentRepo,
  });

  /// Create a new attendance session
  Future<AttendanceSession> createAttendanceSession({
    required String subjectId,
    required String classId,
    required String teacherId,
    required DateTime date,
    required List<String> studentIds,
  }) async {
    final sessionId = 'session-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    
    final records = studentIds.map((studentId) {
      return AttendanceRecord(
        id: '$sessionId-$studentId',
        studentId: studentId,
        subjectId: subjectId,
        classId: classId,
        teacherId: teacherId,
        date: date,
        status: AttendanceStatus.present, // Default to present
        createdAt: now,
      );
    }).toList();

    final session = AttendanceSession(
      id: sessionId,
      subjectId: subjectId,
      classId: classId,
      teacherId: teacherId,
      date: date,
      startTime: now,
      records: records,
      isConfirmed: false,
      createdAt: now,
    );

    return await attendanceRepo.createSession(session);
  }

  /// Update attendance record status
  Future<AttendanceSession> updateRecordStatus({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  }) async {
    final session = await attendanceRepo.getSessionById(sessionId);
    if (session == null) {
      throw Exception('Session not found');
    }

    final updatedRecords = session.records.map((record) {
      if (record.studentId == studentId) {
        return record.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      }
      return record;
    }).toList();

    final updatedSession = session.copyWith(
      records: updatedRecords,
    );

    return await attendanceRepo.updateSession(updatedSession);
  }

  /// Confirm attendance session
  Future<AttendanceSession> confirmSession(String sessionId) async {
    final session = await attendanceRepo.getSessionById(sessionId);
    if (session == null) {
      throw Exception('Session not found');
    }

    final confirmedSession = session.copyWith(
      isConfirmed: true,
      endTime: DateTime.now(),
    );

    final updated = await attendanceRepo.updateSession(confirmedSession);
    
    // Update student attendance percentages
    await _updateStudentAttendancePercentages(session.classId);
    
    return updated;
  }

  /// Calculate and update student attendance percentages
  Future<void> _updateStudentAttendancePercentages(String classId) async {
    final students = await studentRepo.getStudentsByClass(classId);
    
    for (final student in students) {
      final percentages = await attendanceRepo.getAttendancePercentages(student.id);
      final updatedStudent = student.copyWith(subjectAttendance: percentages);
      await studentRepo.updateStudent(updatedStudent);
    }
  }

  /// Get attendance statistics for a student
  Future<Map<String, dynamic>> getStudentStatistics(String studentId) async {
    final percentages = await attendanceRepo.getAttendancePercentages(studentId);
    final records = await attendanceRepo.getRecordsByStudent(studentId, null);
    
    final total = records.length;
    final present = records.where((r) => 
      r.status == AttendanceStatus.present || r.status == AttendanceStatus.late
    ).length;
    final absent = records.where((r) => r.status == AttendanceStatus.absent).length;
    final late = records.where((r) => r.status == AttendanceStatus.late).length;
    
    final overall = total > 0 ? (present / total) * 100 : 0.0;

    return {
      'overall': overall,
      'bySubject': percentages,
      'total': total,
      'present': present,
      'absent': absent,
      'late': late,
    };
  }

  /// Get class attendance statistics
  Future<Map<String, dynamic>> getClassStatistics(String classId) async {
    final percentages = await attendanceRepo.getClassAttendancePercentages(classId);
    final sessions = await attendanceRepo.getSessionsByClass(classId);
    
    final totalSessions = sessions.length;
    final confirmedSessions = sessions.where((s) => s.isConfirmed).length;
    
    final overall = percentages.values.isEmpty 
        ? 0.0 
        : percentages.values.reduce((a, b) => a + b) / percentages.length;

    return {
      'overall': overall,
      'bySubject': percentages,
      'totalSessions': totalSessions,
      'confirmedSessions': confirmedSessions,
    };
  }
}

